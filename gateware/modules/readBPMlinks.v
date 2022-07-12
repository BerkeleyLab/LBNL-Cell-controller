//
// Read values from BPM links and produce a packet containing merged values.
// Nets with names beginning with 'sys' are in the system clock domain.
// All other nets are in the Aurora user clock domain.
//
module readBPMlinks #(
    parameter faStrobeDebug    = "false",
    parameter bpmSetpointDebug = "false",
    parameter ccwInDebug       = "false",
    parameter cwInDebug        = "false",
    parameter mergedDebug      = "false",
    parameter outDebug         = "false",
    parameter stateDebug       = "false") (
    input  wire        sysClk,

    // Control/Status
    input wire         sysCsrStrobe,
    input wire  [31:0] GPIO_OUT,
    output wire [31:0] sysCsr,
    output wire [31:0] sysAdditionalStatus,
    output reg  [31:0] sysRxBitmap,
    input wire         sysLocalFOFBenabled,

    // Local BPM setpoints (from IOC)
    (* mark_debug = bpmSetpointDebug *)
    input  wire [31:0] sysSetpointWriteData,
    (* mark_debug = bpmSetpointDebug *)
    input  wire [15:0] sysSetpointAddress,
    (* mark_debug = bpmSetpointDebug *)
    input  wire        sysSetpointWriteEnable,
    (* mark_debug = bpmSetpointDebug *)
    output reg  [31:0] sysSetpointReadData,

    // Start of Aurora user clock domain nets
    input  wire        auroraUserClk,

    // Marker for beginning of data transfer session
    (* mark_debug = faStrobeDebug *)
    input  wire        auroraFAstrobe,

    // BPM links
    (* mark_debug = ccwInDebug *)
    input  wire [31:0] BPM_CCW_AXI_STREAM_RX_tdata,
    (* mark_debug = ccwInDebug *)
    input  wire        BPM_CCW_AXI_STREAM_RX_tvalid,
    (* mark_debug = ccwInDebug *)
    input  wire        BPM_CCW_AXI_STREAM_RX_tlast,
    (* mark_debug = ccwInDebug *)
    input  wire        BPM_CCW_AXI_STREAM_RX_CRC_pass,
    (* mark_debug = ccwInDebug *)
    input  wire        BPM_CCW_AXI_STREAM_RX_CRC_valid,
    output wire        CCWstatusStrobe,
    output wire  [1:0] CCWstatusCode,

    (* mark_debug = cwInDebug *)
    input  wire [31:0] BPM_CW_AXI_STREAM_RX_tdata,
    (* mark_debug = cwInDebug *)
    input  wire        BPM_CW_AXI_STREAM_RX_tvalid,
    (* mark_debug = cwInDebug *)
    input  wire        BPM_CW_AXI_STREAM_RX_tlast,
    (* mark_debug = cwInDebug *)
    input  wire        BPM_CW_AXI_STREAM_RX_CRC_pass,
    (* mark_debug = cwInDebug *)
    input  wire        BPM_CW_AXI_STREAM_RX_CRC_valid,
    output wire        CWstatusStrobe,
    output wire  [1:0] CWstatusCode,

    // Raw values from BPM
    (* mark_debug = mergedDebug *)
    output wire [111:0]mergedLinkTDATA,
    (* mark_debug = mergedDebug *)
    output wire        mergedLinkTVALID,

    // Outgoing packet with our values (position deviation)
    (* mark_debug = outDebug *)
    output reg  [31:0] localBPMs_tdata,
    (* mark_debug = outDebug *)
    output reg         localBPMs_tvalid,
    (* mark_debug = outDebug *)
    output reg         localBPMs_tlast);

localparam MAX_CELLS          = 32;
parameter CELL_COUNT_WIDTH    = $clog2(MAX_CELLS + 1);
parameter CELL_INDEX_WIDTH    = $clog2(MAX_CELLS);
localparam MAX_BPMS_PER_CELL  = 32;
parameter BPM_COUNT_WIDTH     = $clog2(MAX_BPMS_PER_CELL + 1);
parameter BPM_INDEX_WIDTH     = $clog2(MAX_BPMS_PER_CELL);
parameter FOFB_INDEX_WIDTH    = 9;

//
// Cell settings from IOC -- updated at beginning of transfer session
// This ensures consistent set of BPM count and setpoints.
//
reg                         sysCsrSetpointBank;
reg  [CELL_INDEX_WIDTH-1:0] sysCsrCellIndex;
reg   [BPM_COUNT_WIDTH-1:0] sysCsrBPMcount;
wire  [BPM_COUNT_WIDTH-1:0] sysReadoutBPMcount;
reg                         sysCCWinhibit = 0;
reg                         sysCWinhibit = 0;
wire                        auSetpointBank;
wire [CELL_INDEX_WIDTH-1:0] auCellIndex;
wire  [BPM_COUNT_WIDTH-1:0] auBPMcount;
wire                        auCCWinhibit;
wire                        auCWinhibit;
reg                         readoutSetpointBank;
reg  [CELL_INDEX_WIDTH-1:0] readoutCellIndex;
reg   [BPM_COUNT_WIDTH-1:0] readoutBPMcount, readoutBPMcounter;
reg                         readoutCCWinhibit;
reg                         readoutCWinhibit;

// Setpoint extraction
(* mark_debug = bpmSetpointDebug *) reg [31:0] readoutSetpointData;

// Keep track of the BPMs from which we've received data
(* mark_debug = stateDebug *) reg [MAX_BPMS_PER_CELL-1:0] receivedBitmap;
(* mark_debug = stateDebug *) reg   [BPM_COUNT_WIDTH-1:0] CCWpacketCounter;
(* mark_debug = stateDebug *) reg   [BPM_COUNT_WIDTH-1:0] CCWpacketCount;
(* mark_debug = stateDebug *) reg   [BPM_COUNT_WIDTH-1:0] CWpacketCounter;
(* mark_debug = stateDebug *) reg   [BPM_COUNT_WIDTH-1:0] CWpacketCount;
wire  [BPM_COUNT_WIDTH-1:0] sysCCWpacketCount, sysCWpacketCount;

//
// CSR
//
assign sysCsr ={sysCsrSetpointBank, {7-CELL_INDEX_WIDTH{1'b0}}, sysCsrCellIndex,
                sysCCWinhibit, {7-BPM_COUNT_WIDTH{1'b0}}, sysCCWpacketCount,
                sysCWinhibit,  {7-BPM_COUNT_WIDTH{1'b0}}, sysCWpacketCount,
                {8-BPM_COUNT_WIDTH{1'b0}}, sysCsrBPMcount};
assign sysAdditionalStatus = {
                            {32-BPM_COUNT_WIDTH{1'b0}}, sysReadoutBPMcount };
always @(posedge sysClk) begin
    if (sysCsrStrobe) begin
        if (GPIO_OUT[31])
            sysCsrSetpointBank <= !sysCsrSetpointBank;
        sysCsrCellIndex <= GPIO_OUT[24+:CELL_INDEX_WIDTH];
        sysCCWinhibit <= GPIO_OUT[23];
        sysCWinhibit  <= GPIO_OUT[15];
        sysCsrBPMcount <= GPIO_OUT[0+:BPM_COUNT_WIDTH];
    end
end
forwardData #(.DATA_WIDTH(3+CELL_INDEX_WIDTH+BPM_COUNT_WIDTH)) forwardCmd(
    .inClk(sysClk),
    .inData({sysCCWinhibit,
             sysCWinhibit,
             sysCsrSetpointBank,
             sysCsrCellIndex,
             sysCsrBPMcount}),
    .outClk(auroraUserClk),
    .outData({auCCWinhibit,
              auCWinhibit,
              auSetpointBank,
              auCellIndex,
              auBPMcount}));
forwardData #(.DATA_WIDTH(3*BPM_COUNT_WIDTH)) forwardStatus(
    .inClk(auroraUserClk),
    .inData({readoutBPMcount, CCWpacketCount, CWpacketCount}),
    .outClk(sysClk),
    .outData({sysReadoutBPMcount, sysCCWpacketCount, sysCWpacketCount}));

//
// Read from BPMs and merge into one stream.
// Simple data-only 16-deep MUX.  Since we extract at the same clock
// rate as the incoming data and round-robin arbitrate there's no
// possiblity of a FIFO needing to hold more than half the BPMs in
// a cell.
//
wire [111:0] ccwLinkData, cwLinkData;
(* mark_debug = stateDebug *) wire ccwLinkStrobe, cwLinkStrobe;
(* mark_debug = stateDebug *) reg  mergedLinkTREADY = 0;
readBPMlink #(.dbg("false")) readCCWlink (
              .clk(auroraUserClk),
              .TDATA(BPM_CCW_AXI_STREAM_RX_tdata),
              .TVALID(BPM_CCW_AXI_STREAM_RX_tvalid),
              .TLAST(BPM_CCW_AXI_STREAM_RX_tlast),
              .CRC_VALID(BPM_CCW_AXI_STREAM_RX_CRC_valid),
              .CRC_PASS(BPM_CCW_AXI_STREAM_RX_CRC_pass),
              .inhibit(readoutCCWinhibit),
              .outputStrobe(ccwLinkStrobe),
              .outputData(ccwLinkData),
              .statusStrobe(CCWstatusStrobe),
              .statusCode(CCWstatusCode));
readBPMlink #(.dbg("false")) readCWlink (
              .clk(auroraUserClk),
              .TDATA(BPM_CW_AXI_STREAM_RX_tdata),
              .TVALID(BPM_CW_AXI_STREAM_RX_tvalid),
              .TLAST(BPM_CW_AXI_STREAM_RX_tlast),
              .CRC_VALID(BPM_CW_AXI_STREAM_RX_CRC_valid),
              .CRC_PASS(BPM_CW_AXI_STREAM_RX_CRC_pass),
              .inhibit(readoutCWinhibit),
              .outputStrobe(cwLinkStrobe),
              .outputData(cwLinkData),
              .statusStrobe(CWstatusStrobe),
              .statusCode(CWstatusCode));
readBPMlinksMux readBPMlinksMux (.ACLK(auroraUserClk),
                                 .ARESETN(1'b1),
                                 .S00_AXIS_ACLK(auroraUserClk),
                                 .S01_AXIS_ACLK(auroraUserClk),
                                 .S00_AXIS_ARESETN(1'b1),
                                 .S01_AXIS_ARESETN(1'b1),
                                 .S00_AXIS_TVALID(ccwLinkStrobe),
                                 .S01_AXIS_TVALID(cwLinkStrobe),
                                 .S00_AXIS_TDATA(ccwLinkData),
                                 .S01_AXIS_TDATA(cwLinkData),
                                 .M00_AXIS_ACLK(auroraUserClk),
                                 .M00_AXIS_ARESETN(1'b1),
                                 .M00_AXIS_TVALID(mergedLinkTVALID),
                                 .M00_AXIS_TREADY(mergedLinkTREADY),
                                 .M00_AXIS_TDATA(mergedLinkTDATA),
                                 .S00_ARB_REQ_SUPPRESS(1'b0),
                                 .S01_ARB_REQ_SUPPRESS(1'b0));

// Dissect merged data word
wire                 [15:0] mergedDataHeader;
wire  [BPM_INDEX_WIDTH-1:0] mergedDataBPMindex;
wire [FOFB_INDEX_WIDTH-1:0] mergedDataFOFBindex;
wire                 [31:0] mergedDataX, mergedDataY, mergedDataS;
assign mergedDataHeader    = mergedLinkTDATA[111:96];
assign mergedDataFOFBindex = mergedDataHeader[0+:FOFB_INDEX_WIDTH];
assign mergedDataBPMindex  = mergedDataHeader[0+:BPM_INDEX_WIDTH];
assign mergedDataX         = mergedLinkTDATA[95:64];
assign mergedDataY         = mergedLinkTDATA[63:32];
assign mergedDataS         = mergedLinkTDATA[31:0];

// Forwarded values
wire [31:0] txHeader, txXerror, txYerror;
(* ASYNC_REG="TRUE" *) reg FOFBenabled_m = 0, FOFBenabled = 0;
assign txHeader = {16'hA5BE,
                   FOFBenabled,
                   {6-1-CELL_INDEX_WIDTH{1'b0}}, readoutCellIndex,
                   {10-FOFB_INDEX_WIDTH{1'b0}}, mergedDataFOFBindex};
assign txXerror = mergedDataX - readoutSetpointData;
assign txYerror = mergedDataY - readoutSetpointData;

// Data forwarding state machine
localparam FWST_IDLE          = 0,
           FWST_SEND_HEADER   = 1,
           FWST_SEND_X        = 2,
           FWST_SEND_Y        = 3,
           FWST_SEND_S        = 4;
(* mark_debug = stateDebug *) reg  [2:0] fwState = FWST_IDLE;
always @(posedge auroraUserClk) begin
    FOFBenabled <= FOFBenabled_m;
    if (auroraFAstrobe) begin
        // Start a new readout session
        FOFBenabled_m <= sysLocalFOFBenabled;
        CCWpacketCount <= CCWpacketCounter;
        CCWpacketCounter <= 0;
        readoutCCWinhibit <= auCCWinhibit;
        CWpacketCount <= CWpacketCounter;
        CWpacketCounter <= 0;
        readoutCWinhibit <= auCWinhibit;
        receivedBitmap <= 0;
        readoutSetpointBank <= !auSetpointBank;
        readoutCellIndex <= auCellIndex;
        readoutBPMcount <= readoutBPMcounter;
        readoutBPMcounter <= 0;
        mergedLinkTREADY <= 0;
        localBPMs_tvalid <= 0;
        localBPMs_tlast <= 0;
        fwState <= (auBPMcount == 0) ? FWST_IDLE : FWST_SEND_HEADER;
        // For now I'm not going to worry about clock domain crossing
        // since this value hopefully won't change very often.
        sysRxBitmap <= receivedBitmap;
    end
    else begin
        if (ccwLinkStrobe) CCWpacketCounter <= CCWpacketCounter + 1;
        if ( cwLinkStrobe)  CWpacketCounter <=  CWpacketCounter + 1;
        case (fwState)
        FWST_IDLE: begin
            localBPMs_tvalid <= 0;
            mergedLinkTREADY <= 1; // Toss BPM data until next cycle
        end

        FWST_SEND_HEADER: begin
            if (mergedLinkTVALID) begin
                if (receivedBitmap[mergedDataBPMindex] == 0) begin
                    receivedBitmap[mergedDataBPMindex] <= 1;
                    readoutBPMcounter <= readoutBPMcounter + 1;
                    localBPMs_tvalid <= 1;
                    localBPMs_tdata <= txHeader;
                    mergedLinkTREADY <= 0;
                    fwState <= FWST_SEND_X;
                end
                else begin
                    localBPMs_tvalid <= 0;
                    mergedLinkTREADY <= 1;
                end
            end
            else begin
                localBPMs_tvalid <= 0;
                mergedLinkTREADY <= 0;
            end
        end

        FWST_SEND_X: begin
            localBPMs_tdata <= txXerror;
            fwState <= FWST_SEND_Y;
        end

        FWST_SEND_Y: begin
            localBPMs_tdata <= txYerror;
            fwState <= FWST_SEND_S;
            mergedLinkTREADY <= 1;
        end

        FWST_SEND_S: begin
            localBPMs_tdata <= mergedDataS;
            if (readoutBPMcounter == auBPMcount) begin
                localBPMs_tlast <= 1;
                fwState <= FWST_IDLE;
            end
            else begin
                mergedLinkTREADY <= 0;
                fwState <= FWST_SEND_HEADER;
            end
        end

        default: ;
        endcase
    end
end

//
// Dual port setpoint memory
// Two banks of X0, Y0, X1, Y1, ...
//
parameter SETPOINT_ADDR_WIDTH = $clog2(2*MAX_BPMS_PER_CELL);
reg [31:0] dpram [0:(1 << (1 + SETPOINT_ADDR_WIDTH)) - 1];
(* mark_debug = bpmSetpointDebug *)
wire [SETPOINT_ADDR_WIDTH:0] sysAddr = { sysCsrSetpointBank,
                                  sysSetpointAddress[2+:SETPOINT_ADDR_WIDTH] };
always @(posedge sysClk) begin
    sysSetpointReadData <= dpram[sysAddr];
    if (sysSetpointWriteEnable) dpram[sysAddr] <= sysSetpointWriteData;
end
(* mark_debug = bpmSetpointDebug *)
wire [SETPOINT_ADDR_WIDTH:0] auAddr = { readoutSetpointBank,
                                        mergedDataBPMindex,
                                        fwState[1] };
always @(posedge auroraUserClk) begin
    readoutSetpointData <= dpram[auAddr];
end

endmodule
