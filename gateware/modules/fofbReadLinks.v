// Gather data from local BPM and cell controller loops into DPRAM
module fofbReadLinks #(
    parameter SYSCLK_RATE       = 100000000,
    parameter FOFB_INDEX_WIDTH = -1,
    parameter MAX_CELLS        = 32,
    parameter CELL_INDEX_WIDTH = $clog2(MAX_CELLS),
    parameter    FAstrobeDebug = "false",
    parameter      statusDebug = "false",
    parameter     rawDataDebug = "false",
    parameter     ccwLinkDebug = "false",
    parameter      cwLinkDebug = "false",
    parameter   cellCountDebug = "false",
    parameter  dspReadoutDebug = "false"
    ) (
    input  wire        sysClk,

    // Control/Status
    input wire                                            csrStrobe,
    input wire                                     [31:0] GPIO_OUT,
    (*mark_debug=statusDebug*) output wire         [31:0] csr,
    (*mark_debug=statusDebug*) output reg [MAX_CELLS-1:0] rxBitmap,
    (*mark_debug=statusDebug*) output reg [MAX_CELLS-1:0] fofbEnableBitmap,
    (*mark_debug=statusDebug*) output reg                 fofbEnabled,

    // Synchronization
    (*mark_debug=FAstrobeDebug*) input  wire        FAstrobe,

    // Link statistics
    (*mark_debug=statusDebug*) output wire       sysStatusStrobe,
    (*mark_debug=statusDebug*) output wire [2:0] sysStatusCode,
    (*mark_debug=statusDebug*) output reg        sysTimeoutStrobe = 0,

    // Fast orbit feedback correction DSP
    (*mark_debug=dspReadoutDebug*)
    input wire [FOFB_INDEX_WIDTH-1:0] fofbDSPreadoutAddress,
    (*mark_debug=dspReadoutDebug*)
    output wire                [31:0] fofbDSPreadoutX,
    (*mark_debug=dspReadoutDebug*)
    output wire                [31:0] fofbDSPreadoutY,
    (*mark_debug=dspReadoutDebug*)
    output wire                [31:0] fofbDSPreadoutS,

    // Values to microBlaze
    input  wire                       uBreadoutStrobe,
    output wire                [31:0] uBreadoutX,
    output wire                [31:0] uBreadoutY,
    output wire                [31:0] uBreadoutS,

    // Start of Aurora user clock domain nets
    input  wire                              auClk,
    (*mark_debug=FAstrobeDebug*) input  wire auFAstrobe,
    input  wire                              auReset,
    output reg                               auCCWcellInhibit = 0,
    output reg                               auCWcellInhibit = 0,

    // Tap of outging cell links
    (*mark_debug=rawDataDebug*) input  wire        auCellCCWlinkTVALID,
    (*mark_debug=rawDataDebug*) input  wire        auCellCCWlinkTLAST,
    (*mark_debug=rawDataDebug*) input  wire [31:0] auCellCCWlinkTDATA,

    (*mark_debug=rawDataDebug*) input  wire        auCellCWlinkTVALID,
    (*mark_debug=rawDataDebug*) input  wire        auCellCWlinkTLAST,
    (*mark_debug=rawDataDebug*) input  wire [31:0] auCellCWlinkTDATA);

parameter CELL_COUNT_WIDTH = $clog2(MAX_CELLS+1);
localparam READOUT_TIMER_WIDTH = 5;

//
// Control register
//
reg ccwInhibit = 0, cwInhibit = 0, useFakeData = 0;
reg [CELL_COUNT_WIDTH-1:0] cellCount = 0;
reg readoutActive = 0, readoutValid = 0, readTimeout = 0;
reg auReadoutValid_m, auReadoutValid;
always @(posedge sysClk) begin
    if (csrStrobe) begin
        cellCount <= GPIO_OUT[0+:CELL_COUNT_WIDTH];
        ccwInhibit <= GPIO_OUT[3*CELL_COUNT_WIDTH+0];
        cwInhibit <= GPIO_OUT[3*CELL_COUNT_WIDTH+1];
        useFakeData <= GPIO_OUT[20];
    end
end

//
// Packet reception
//
wire       auCCWstatusStrobe, auCWstatusStrobe;
wire       auCCWstatusFOFBenabled, auCWstatusFOFBenabled;
wire [1:0] auCCWstatusCode, auCWstatusCode;
wire [CELL_INDEX_WIDTH-1:0] auCCWcellIndex, auCWcellIndex;
wire [(1<<FOFB_INDEX_WIDTH)-1:0] auCCW_FOFBbitmap, auCW_FOFBbitmap;
(* mark_debug = cellCountDebug *)
wire [CELL_COUNT_WIDTH-1:0] auCCWpacketCounter, auCWpacketCounter;
wire [(1<<FOFB_INDEX_WIDTH)-1:0] auCCWfofbIndex, auCWfofbIndex;
wire                 [31:0] ccwX, ccwY, ccwS, cwX, cwY, cwS;
fofbReadLink #(.dbg(ccwLinkDebug)) readCCW (
    .auroraClk(auClk),
    .FAstrobe(auFAstrobe),
    .allBPMpresent(auReadoutValid),
    .TVALID(auCellCCWlinkTVALID),
    .TLAST(auCellCCWlinkTLAST),
    .TDATA(auCellCCWlinkTDATA),
    .statusStrobe(auCCWstatusStrobe),
    .statusCode(auCCWstatusCode),
    .statusFOFBenabled(auCCWstatusFOFBenabled),
    .statusCellIndex(auCCWcellIndex),
    .cellCounter(auCCWpacketCounter),
    .bpmBitmap(auCCW_FOFBbitmap),
    .sysClk(sysClk),
    .readoutAddress(fofbDSPreadoutAddress),
    .readoutX(ccwX),
    .readoutY(ccwY),
    .readoutS(ccwS));
fofbReadLink #(.dbg(cwLinkDebug)) readCW (
    .auroraClk(auClk),
    .FAstrobe(auFAstrobe),
    .allBPMpresent(auReadoutValid),
    .TVALID(auCellCWlinkTVALID),
    .TLAST(auCellCWlinkTLAST),
    .TDATA(auCellCWlinkTDATA),
    .statusStrobe(auCWstatusStrobe),
    .statusCode(auCWstatusCode),
    .statusFOFBenabled(auCWstatusFOFBenabled),
    .statusCellIndex(auCWcellIndex),
    .cellCounter(auCWpacketCounter),
    .bpmBitmap(auCW_FOFBbitmap),
    .sysClk(sysClk),
    .readoutAddress(fofbDSPreadoutAddress),
    .readoutX(cwX),
    .readoutY(cwY),
    .readoutS(cwS));

//
// Merge cell info from packet reception and get into system clock domain.
//
(* mark_debug = cellCountDebug *) wire       mergedTVALID;
(* mark_debug = cellCountDebug *) wire [0:0] mergedTUSER;
                                  wire [7:0] mergedTDATA;
wire [CELL_INDEX_WIDTH-1:0] mergedCellIndex = mergedTDATA[0+:CELL_INDEX_WIDTH];
wire [1:0]                 mergedStatus = mergedTDATA[CELL_INDEX_WIDTH+:2];
wire                       mergedLink = mergedTDATA[CELL_INDEX_WIDTH+2];
assign sysStatusStrobe = mergedTVALID;
assign sysStatusCode = { mergedLink, mergedStatus };
wire mergedFOFBenabled = mergedTUSER[0];

localparam LINK_CCW = 1'b0, LINK_CW = 1'b1;
localparam ST_SUCCESS = 2'd0;

fofbReadLinksMux fofbReadLinksMux (
    .ACLK(auClk),
    .ARESETN(~auReset),
    .S00_AXIS_ACLK(auClk),
    .S01_AXIS_ACLK(auClk),
    .S00_AXIS_ARESETN(1'b1),
    .S01_AXIS_ARESETN(1'b1),
    .S00_AXIS_TVALID(auCCWstatusStrobe),
    .S00_AXIS_TDATA({LINK_CCW, auCCWstatusCode, auCCWcellIndex}),
    .S00_AXIS_TUSER(auCCWstatusFOFBenabled),
    .S01_AXIS_TVALID(auCWstatusStrobe),
    .S01_AXIS_TDATA({LINK_CW, auCWstatusCode, auCWcellIndex}),
    .S01_AXIS_TUSER(auCWstatusFOFBenabled),
    .M00_AXIS_ACLK(sysClk),
    .M00_AXIS_ARESETN(1'b1),
    .M00_AXIS_TVALID(mergedTVALID),
    .M00_AXIS_TREADY(1'b1),
    .M00_AXIS_TDATA(mergedTDATA),
    .M00_AXIS_TUSER(mergedTUSER),
    .S00_ARB_REQ_SUPPRESS(1'b0),
    .S01_ARB_REQ_SUPPRESS(1'b0));

//
// Forward link packet counts to system clock domain
//
reg [CELL_COUNT_WIDTH-1:0] auCCWpacketCount, auCWpacketCount;
reg [CELL_COUNT_WIDTH-1:0] ccwPacketCount, cwPacketCount;
reg auPkCountToggle = 0;
reg sysPkCountToggle_m = 0, sysPkCountToggle = 0, sysPkCountToggle_d = 0;
always @(posedge auClk) begin
    if (auFAstrobe) begin
        auCCWpacketCount <= auCCWpacketCounter;
        auCWpacketCount <= auCWpacketCounter;
        auPkCountToggle <= !auPkCountToggle;
    end
end
always @(posedge sysClk) begin
    sysPkCountToggle_m <= auPkCountToggle;
    sysPkCountToggle   <= sysPkCountToggle_m;
    sysPkCountToggle_d <= sysPkCountToggle;
    if (sysPkCountToggle != sysPkCountToggle_d) begin
        sysPkCountToggle_d <= !sysPkCountToggle_d;
        ccwPacketCount <= auCCWpacketCount;
        cwPacketCount <= auCWpacketCount;
    end
end

//
// Keep track of the cells to which we've sent valid data.
// When we've sent data from all cells mark the readout as valid.
//
localparam SEQNO_WIDTH = 3;
(* mark_debug = cellCountDebug *)
reg [CELL_COUNT_WIDTH-1:0] cellCounter, fofbCounter;
reg [SEQNO_WIDTH-1:0] seqno = 0;
reg [$clog2(SYSCLK_RATE/1000000)-1:0] usDivider;
reg [READOUT_TIMER_WIDTH-1:0] readoutTime, readoutTimer;
(* mark_debug = cellCountDebug *) reg timeoutToggle = 0, timeoutToggle_d = 0;
reg [MAX_CELLS-1:0] cellBitmap, fofbBitmap;
reg timeoutFlag;
always @(posedge sysClk) begin
    timeoutToggle_d <= timeoutToggle;
    sysTimeoutStrobe <= (timeoutToggle != timeoutToggle_d);
    if (FAstrobe) begin
        cellCounter <= 0;
        fofbCounter <= 0;
        cellBitmap <= 0;
        fofbBitmap <= 0;
        readoutActive <= 1;
        readoutValid <= 0;
        usDivider <= ((SYSCLK_RATE/1000000)/2)-1;
        readoutTimer <= 0;
        readTimeout <= 0;
        timeoutFlag <= 0;
        rxBitmap <= cellBitmap;
        fofbEnableBitmap <= fofbBitmap;
    end
    else if (readoutActive) begin
        if (cellCounter == cellCount) begin
            fofbEnabled <= (fofbCounter == cellCount);
            seqno <= seqno + 1;
            readoutValid <= 1;
            readoutTime <= readoutTimer;
            readoutActive <= 0;
        end
        else if (timeoutFlag) begin
            fofbEnabled <= 0;
            readTimeout <= 1;
            timeoutToggle <= !timeoutToggle;
            readoutTime <= readoutTimer;
            readoutActive <= 0;
        end
        if (mergedTVALID && (mergedStatus == ST_SUCCESS)) begin
            cellBitmap[mergedCellIndex] <= 1;
            if (!cellBitmap[mergedCellIndex]) begin
                cellCounter <= cellCounter + 1;
            end
            if (mergedFOFBenabled) begin
                fofbBitmap[mergedCellIndex] <= 1;
                if (!fofbBitmap[mergedCellIndex]) begin
                    fofbCounter <= fofbCounter + 1;
                end
            end
        end
        if (usDivider == 0) begin
            readoutTimer <= readoutTimer + 1;
            usDivider <= SYSCLK_RATE/1000000-1;
            if (readoutTimer == {READOUT_TIMER_WIDTH{1'b1}}) begin
                timeoutFlag <= 1;
            end
        end
        else begin
            usDivider <= usDivider - 1;
        end
    end
end

//
// Keep track of which buffers contain valid data from a particular BPM.
//
reg auCCWcellInhibit_m, auCWcellInhibit_m;
always @(posedge auClk)begin
    auReadoutValid_m <= readoutValid;
    auReadoutValid   <= auReadoutValid_m;
    auCCWcellInhibit_m <= ccwInhibit;
    auCWcellInhibit_m  <= cwInhibit;
    if (auFAstrobe) begin
        auCCWcellInhibit <= auCCWcellInhibit_m;
        auCWcellInhibit  <= auCWcellInhibit_m;
    end
end

//
// DSP readout
// Yes, we are using the 'au' clock domain bitmaps in the system clock domain,
// but that's acceptable since the DSP readout occurs only after the bitmaps
// have been modified.
//
(*mark_debug=dspReadoutDebug*) reg ccwHasBPM, cwHasBPM;
(*mark_debug=dspReadoutDebug*) reg [31:0] saveBPMx, saveBPMy;
always @(posedge sysClk) begin
    // The one cycle latency in extracting the bit from the bitmap matches the
    // one cycle latency to read the values from the 'readLink' DPRAM.
    ccwHasBPM <= readoutValid && auCCW_FOFBbitmap[fofbDSPreadoutAddress];
    cwHasBPM <= readoutValid && auCW_FOFBbitmap[fofbDSPreadoutAddress];
end
assign fofbDSPreadoutX = ccwHasBPM ? ccwX : (cwHasBPM ? cwX : saveBPMx);
assign fofbDSPreadoutY = ccwHasBPM ? ccwY : (cwHasBPM ? cwY : saveBPMy);
assign fofbDSPreadoutS = ccwHasBPM ? ccwS : (cwHasBPM ? cwS : 0);

//
// Store values so we can use them next cycle if no new data arrive
//
reg [63:0] saveDPRAM [0:(1<<FOFB_INDEX_WIDTH)-1];
reg [FOFB_INDEX_WIDTH-1:0] fofbDSPreadoutAddress_d;
wire fofbDSPreadoutValid=(fofbDSPreadoutAddress[0]!=fofbDSPreadoutAddress_d[0]);
always @(posedge sysClk) begin
    fofbDSPreadoutAddress_d <= fofbDSPreadoutAddress;
    {saveBPMy, saveBPMx} <= saveDPRAM[fofbDSPreadoutAddress];
    if (fofbDSPreadoutValid) begin
        saveDPRAM[fofbDSPreadoutAddress_d] <= {fofbDSPreadoutY,fofbDSPreadoutX};
    end
end

//
// MicroBlaze status
//
assign csr = { readoutActive, readoutValid, readoutTime, seqno,
            {32-2-READOUT_TIMER_WIDTH-SEQNO_WIDTH-3-(3*CELL_COUNT_WIDTH){1'b0}},
                                     useFakeData, cwInhibit, ccwInhibit,
                                     cwPacketCount, ccwPacketCount, cellCount };

//
// MicroBlaze readout DPRAM
// Use for diagnostic printout and, for now, to multicast
// values to the old fast orbit feedback system.
//
reg [95:0] uBdpram [0:(1<<FOFB_INDEX_WIDTH)-1];
reg [95:0] uBq;
assign uBreadoutX=uBq[0+:32], uBreadoutY=uBq[32+:32], uBreadoutS=uBq[64+:32];
reg [FOFB_INDEX_WIDTH-1:0] uBreadoutAddress;
always @(posedge sysClk) begin
    if (uBreadoutStrobe) uBreadoutAddress <= GPIO_OUT[FOFB_INDEX_WIDTH-1:0];
    uBq <= uBdpram[uBreadoutAddress];
    if (fofbDSPreadoutValid) begin
        uBdpram[fofbDSPreadoutAddress_d] <=
                            {fofbDSPreadoutS, fofbDSPreadoutY, fofbDSPreadoutX};
    end
end

endmodule
