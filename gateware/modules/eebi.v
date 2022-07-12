// Errant Electron Beam Interlock
module eebi #(
    parameter SUM_THRESHOLD = 20000,
    parameter SYSCLK_RATE   = 100000000,
    parameter EEBI_COUNT    = 2,
    parameter dbg           = "false"
    ) (
    input  wire        sysClk,

    // Control/Status
    input wire         sysCsrStrobe,
    input wire  [31:0] sysCsrWriteData,
    output wire [31:0] sysCsr,
    input  wire [63:0] sysTimestamp,
    output reg  [63:0] sysMostRecentFaultTime,

    // Start of Aurora user clock domain nets
    input  wire        auroraUserClk,

    // Marker for beginning of data transfer session
    (* mark_debug = dbg *)
    input  wire        auroraFAstrobe,

    // Raw values from BPM
    input  wire [111:0]localBPMvalues,
    (* mark_debug = dbg *)
    input  wire        localBPMvaluesVALID,

    // Interlock
    (* mark_debug = dbg *)
    output reg         eebiRelay = 0,
    (* mark_debug = dbg *)
    input  wire        eebiResetButton_n);

localparam FOFB_INDEX_WIDTH   = 9;
localparam BEAM_CURRENT_WIDTH = 10;
localparam BEAM_TIMER_RELOAD  = 20 * SYSCLK_RATE;
localparam BEAM_TIMER_WIDTH   = $clog2(BEAM_TIMER_RELOAD+1)+1;
localparam EEBI_SELECT_WIDTH  = $clog2(EEBI_COUNT);
localparam FAULTS_WIDTH       = EEBI_COUNT * 3;

// Status
wire [2:0] sysEEBIstate;
reg  [2:0] sysEEBIstate_d = 0, sysEEBImostRecentFaultState = 0;

// Interlock parameters
// Set in system clock domain and used in Aurora clock domain.
// No clock domain crossing needed for these since they are used
// only when known to be stable.
// Position values in nm, current values in mA.
reg   [(EEBI_COUNT*2*FOFB_INDEX_WIDTH)-1:0] bpmSelect;
reg                    [(EEBI_COUNT*2)-1:0] planeSelect;
reg                 [(EEBI_COUNT*2*32)-1:0] offset, diffLimit;
reg                   [(EEBI_COUNT*32)-1:0] skewLimit;
reg                                  [31:0] buttonSumThreshold = SUM_THRESHOLD;
reg                          sysBeamAboveLimit;
reg   [BEAM_TIMER_WIDTH-1:0] sysBeamCurrentTimer;
wire sysBeamCurrentTimeout = sysBeamCurrentTimer[BEAM_TIMER_WIDTH-1];
reg                          sysCoefficientsValid = 0;
reg [(EEBI_SELECT_WIDTH+3)-1:0] sysAddressLatch;
wire                  [2:0] sysAddressCoefficientSelect = sysAddressLatch[2:0];
wire[EEBI_SELECT_WIDTH-1:0] sysAddressEEBIselect = sysAddressLatch[3+:
                                                             EEBI_SELECT_WIDTH];
always @(posedge sysClk) begin
    sysEEBIstate_d <= sysEEBIstate;
    if ((sysEEBIstate < EEBIstate_UNDERCURRENT)
     && (sysEEBIstate_d >= EEBIstate_UNDERCURRENT)) begin
        sysEEBImostRecentFaultState <= sysEEBIstate;
        sysMostRecentFaultTime      <= sysTimestamp;
    end
    if (sysCsrStrobe) begin
        if (sysCsrWriteData[31]) begin
            sysAddressLatch <= sysCsrWriteData[3:0];
            sysEEBIreset <= sysCsrWriteData[30];
        end
        else begin
            case (sysAddressCoefficientSelect)
            4'h0: begin
                bpmSelect[((sysAddressEEBIselect*2)+0)*FOFB_INDEX_WIDTH+:
                      FOFB_INDEX_WIDTH]<= sysCsrWriteData[0+:FOFB_INDEX_WIDTH];
                planeSelect[sysAddressEEBIselect*2+0] <=
                                          sysCsrWriteData[0+FOFB_INDEX_WIDTH];
                bpmSelect[((sysAddressEEBIselect*2)+1)*FOFB_INDEX_WIDTH+:
                      FOFB_INDEX_WIDTH]<= sysCsrWriteData[16+:FOFB_INDEX_WIDTH];
                planeSelect[sysAddressEEBIselect*2+1] <=
                                          sysCsrWriteData[16+FOFB_INDEX_WIDTH];
            end
            4'h1: offset[((sysAddressEEBIselect*2)+0)*32+:32] <=
                                   {sysCsrWriteData[30], sysCsrWriteData[30:0]};
            4'h2: offset[((sysAddressEEBIselect*2)+1)*32+:32] <=
                                   {sysCsrWriteData[30], sysCsrWriteData[30:0]};
            4'h3: diffLimit[((sysAddressEEBIselect*2)+0)*32+:32] <=
                                                  {1'b0, sysCsrWriteData[30:0]};
            4'h4: diffLimit[((sysAddressEEBIselect*2)+1)*32+:32] <=
                                                  {1'b0, sysCsrWriteData[30:0]};
            4'h5: skewLimit[sysAddressEEBIselect*32+:32] <=
                                                  {1'b0, sysCsrWriteData[30:0]};
            4'h6: buttonSumThreshold <= {1'b0, sysCsrWriteData[30:0]};
            4'h7: begin
                sysBeamCurrentTimer <= BEAM_TIMER_RELOAD;
                sysBeamAboveLimit <= sysCsrWriteData[0];
                sysCoefficientsValid <= sysCsrWriteData[1];
            end
            default: ;
            endcase
        end
    end
    else begin
        if (!sysBeamCurrentTimeout) begin
            sysBeamCurrentTimer <= sysBeamCurrentTimer -1 ;
        end
    end
end

// Dissect incoming data
(* mark_debug = dbg *) wire signed [31:0] bpmValueY, bpmValueX;
(* mark_debug = dbg *) wire        [31:0] bpmValueS;
(* mark_debug = dbg *) wire         [8:0] bpmIndex;
assign bpmIndex = localBPMvalues[96+:9];
assign bpmValueX = localBPMvalues[64+:32];
assign bpmValueY = localBPMvalues[32+:32];
assign bpmValueS = localBPMvalues[ 0+:32];

(* mark_debug = dbg *) reg [(EEBI_COUNT*2)-1:0] clipFaults;
(* mark_debug = dbg *) reg     [EEBI_COUNT-1:0] bpmTimeouts;
(* mark_debug = dbg *) reg [FAULTS_WIDTH-1:0] beamFaults, beamFaults_d;
(* mark_debug = dbg *) reg [FAULTS_WIDTH-1:0] firstBeamFaults = 0;
reg bpmTimeout;

genvar i;
generate
for (i = 0 ; i < EEBI_COUNT ; i = i + 1) begin
// EEBI tests of incoming data
(* mark_debug = dbg *) reg haveBPM0 = 0, haveBPM1 = 0;
(* mark_debug = dbg *) reg validBPM0 = 0, validBPM1 = 0;
(* mark_debug = dbg *) reg  signed [31:0] bpmDiff0, bpmDiff1, skew;
(* mark_debug = dbg *) reg                filterEnable = 0;
(* mark_debug = dbg *) wire signed [31:0] filteredDiff0, filteredDiff1;
(* mark_debug = dbg *) reg         [31:0] absDiff0, absDiff1, absSkew;
(* mark_debug = dbg *) reg                diffFault0, diffFault1, skewFault;
(* mark_debug = dbg *) reg diffTrip0 = 0, diffTrip1 = 0, skewTrip = 0;
localparam bpmState_IDLE     = 3'd0,
           bpmState_WAIT     = 3'd1,
           bpmState_FILTER   = 3'd2,
           bpmState_COMPUTE1 = 3'd3,
           bpmState_COMPUTE2 = 3'd4,
           bpmState_COMPUTE3 = 3'd5,
           bpmState_CHECK    = 3'd6,
           bpmState_DONE     = 3'd7;
(* mark_debug = dbg *) reg   [2:0] bpmCheckState = bpmState_IDLE;

wire [FOFB_INDEX_WIDTH-1:0] bpmSelect0 =
                        bpmSelect[((i*2)+0)*FOFB_INDEX_WIDTH+:FOFB_INDEX_WIDTH];
wire [FOFB_INDEX_WIDTH-1:0] bpmSelect1 =
                        bpmSelect[((i*2)+1)*FOFB_INDEX_WIDTH+:FOFB_INDEX_WIDTH];
wire planeSelect0 = planeSelect[(i*2)+0];
wire planeSelect1 = planeSelect[(i*2)+1];
wire signed [31:0] offset0 = offset[((i*2)+0)*32+:32];
wire signed [31:0] offset1 = offset[((i*2)+1)*32+:32];
wire [31:0] diffLimit0 = diffLimit[((i*2)+0)*32+:32];
wire [31:0] diffLimit1 = diffLimit[((i*2)+1)*32+:32];
wire [31:0] skewLim    = skewLimit[i*32+:32];

lowpass #(.WIDTH(32),.L2_ALPHA(5)) lowpass0 (.clk(auroraUserClk),
                                             .en(filterEnable),
                                             .u(bpmDiff0),
                                             .y(filteredDiff0));
lowpass #(.WIDTH(32),.L2_ALPHA(5)) lowpass1 (.clk(auroraUserClk),
                                             .en(filterEnable),
                                             .u(bpmDiff1),
                                             .y(filteredDiff1));

always @(posedge auroraUserClk) begin
    if (auroraFAstrobe) begin
        filterEnable <= 0;
        if (bpmCheckState == bpmState_DONE) begin
            bpmTimeouts[i] <= 0;
        end
        else begin
            bpmTimeouts[i] <= 1;
        end
        haveBPM0 <= 0;
        haveBPM1 <= 0;
        if ({planeSelect0, bpmSelect0} != {planeSelect1, bpmSelect1}) begin
            bpmCheckState <= bpmState_WAIT;
        end
    end
    else begin
        case (bpmCheckState)
        bpmState_IDLE: ;
        bpmState_WAIT: begin
            if (haveBPM0 && haveBPM1) begin
                bpmCheckState <= bpmState_FILTER;
                filterEnable <= 1;
            end
            else begin
                filterEnable <= 0;
            end
            if (localBPMvaluesVALID && !haveBPM0 && (bpmIndex==bpmSelect0)) begin
                bpmDiff0 <= (planeSelect0 ? bpmValueY : bpmValueX) - offset0;
`ifdef IVERILOG
                $display("EEBI: %d planeSelect:%d: bpmIndex:%d S:%d Y:%d X:%d offset0:%d", i, planeSelect0, bpmIndex, bpmValueS, bpmValueY, bpmValueX, offset0);
`endif
                clipFaults[(i*2)+0] <= bpmValueS[30];
                validBPM0 <= (bpmValueS[29:0] > buttonSumThreshold);
                haveBPM0 <= 1;
            end
            if (localBPMvaluesVALID && !haveBPM1 && (bpmIndex==bpmSelect1)) begin
                bpmDiff1 <= (planeSelect1 ? bpmValueY : bpmValueX) - offset1;
                clipFaults[(i*2)+1] <= bpmValueS[30];
                validBPM1 <= (bpmValueS[29:0] > buttonSumThreshold);
                haveBPM1 <= 1;
            end
        end

        bpmState_FILTER: begin
`ifdef IVERILOG
            $display("EEBI: %d diff0:%d  diff1:%d", i, bpmDiff0, bpmDiff1);
`endif
            filterEnable <= 0;
            bpmCheckState <= bpmState_COMPUTE1;
        end
        bpmState_COMPUTE1: bpmCheckState <= bpmState_COMPUTE2;
        bpmState_COMPUTE2: bpmCheckState <= bpmState_COMPUTE3;
        bpmState_COMPUTE3: bpmCheckState <= bpmState_CHECK;
        bpmState_CHECK: begin
`ifdef IVERILOG
            $display("EEBI: %d filt00:%d  filt01:%d", i, filteredDiff0, filteredDiff1);
            $display("EEBI: %d valid0:%d valid1:%d diff0:%d diff1:%d skew:%d", i, validBPM0, validBPM1, diffFault0, diffFault1, skewFault);
`endif
            beamFaults[(i*3)+0] <= validBPM0 && diffFault0;
            beamFaults[(i*3)+1] <= validBPM1 && diffFault1;
            beamFaults[(i*3)+2] <= validBPM0 && validBPM1 && skewFault;
            bpmCheckState <= bpmState_DONE;
        end
        bpmState_DONE: ;
        default: bpmCheckState <= bpmState_IDLE;
        endcase
    end

    // Computation pipeline stage 1
    absDiff0 <= filteredDiff0[31] ? -filteredDiff0 : filteredDiff0;
    absDiff1 <= filteredDiff1[31] ? -filteredDiff1 : filteredDiff1;
    skew <= filteredDiff0 - filteredDiff1;

    // Computation pipeline stage 2
    absSkew <= skew[31] ? -skew : skew;
    diffFault0 <= (absDiff0 > diffLimit0);
    diffFault1 <= (absDiff1 > diffLimit1);

    // Computation pipeline stage 3
    skewFault <= (absSkew > skewLim);
end
end
endgenerate

// EEBI
localparam EEBIstate_UNCONFIGURED    = 3'd0,
           EEBIstate_CURRENT_TIMEOUT = 3'd1,
           EEBIstate_BPM_TIMEOUT     = 3'd2,
           EEBIstate_CLIPPING        = 3'd3,
           EEBIstate_TRIPPED         = 3'd4,
           EEBIstate_UNDERCURRENT    = 3'd5,
           EEBIstate_ARMED           = 3'd6;
(* mark_debug = dbg *) reg [2:0] EEBIstate = EEBIstate_UNCONFIGURED;

(*ASYNC_REG="true"*) reg coefficientsValid_m;
reg coefficientsValid;
(*ASYNC_REG="true"*) reg beamAboveLimit_m;
reg beamAboveLimit;
(*ASYNC_REG="true"*) reg beamCurrentTimeout_m;
reg beamCurrentTimeout;
(*ASYNC_REG="true"*) reg eebiReset_m;
reg eebiReset = 0, sysEEBIreset = 0;
(* mark_debug = dbg *) reg bpmClipFault, bpmTrip;

always @(posedge auroraUserClk) begin
    coefficientsValid_m  <= sysCoefficientsValid;
    coefficientsValid    <= coefficientsValid_m;
    beamAboveLimit_m     <= sysBeamAboveLimit;
    beamAboveLimit       <= beamAboveLimit_m;
    beamCurrentTimeout_m <= sysBeamCurrentTimeout;
    beamCurrentTimeout   <= beamCurrentTimeout_m;
    eebiReset_m          <= !eebiResetButton_n || sysEEBIreset;
    eebiReset            <= eebiReset_m;
    bpmClipFault <= |clipFaults;
    bpmTimeout   <= |bpmTimeouts;
    bpmTrip      <= |beamFaults;
    beamFaults_d <= beamFaults;

    if (EEBIstate == EEBIstate_TRIPPED) begin
        if (eebiReset) begin
            EEBIstate <= EEBIstate_UNCONFIGURED;
            firstBeamFaults <= 0;
        end
    end
    else if (!coefficientsValid) begin
        EEBIstate <= EEBIstate_UNCONFIGURED;
    end
    else if (beamCurrentTimeout) begin
        EEBIstate <= EEBIstate_CURRENT_TIMEOUT;
    end
    else if (!beamAboveLimit) begin
        EEBIstate <= EEBIstate_UNDERCURRENT;
    end
    else if (bpmTimeout) begin
        EEBIstate <= EEBIstate_BPM_TIMEOUT;
    end
    else if (bpmClipFault) begin
        EEBIstate <= EEBIstate_CLIPPING;
    end
    else if (bpmTrip) begin
        firstBeamFaults <= beamFaults_d;
        EEBIstate <= EEBIstate_TRIPPED;
    end
    else begin
        EEBIstate <= EEBIstate_ARMED;
    end
    eebiRelay <= (EEBIstate >= EEBIstate_UNDERCURRENT);
end

assign sysCsr = { !eebiResetButton_n, eebiReset, 1'b0, eebiRelay,
                  1'b0, bpmTrip, coefficientsValid, bpmTimeout,
                  {8-FAULTS_WIDTH{1'b0}}, firstBeamFaults,
                  {8-FAULTS_WIDTH{1'b0}}, beamFaults,
                  sysBeamAboveLimit, sysBeamCurrentTimeout,
                                    sysEEBImostRecentFaultState, sysEEBIstate };

forwardData #(.DATA_WIDTH(3)) forwardEEBIstate (
            .inClk(auroraUserClk),
            .inData(EEBIstate),
            .outClk(sysClk),
            .outData(sysEEBIstate));

endmodule
