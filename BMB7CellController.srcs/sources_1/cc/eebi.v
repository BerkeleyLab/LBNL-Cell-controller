// Errant Electron Beam Interlock
module eebi #(
    parameter SUM_TRIGGER_THRESHOLD = 20000,
    parameter SYSCLK_RATE           = 100000000,
    parameter EEBI_COUNT            = 2,
    parameter dbg                   = "false") (
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
    output wire        eebiRelay,
    (* mark_debug = dbg *)
    input  wire        eebiResetButton_n);

localparam FOFB_INDEX_WIDTH   = 9;
localparam BEAM_CURRENT_WIDTH = 10;
parameter  BEAM_TIMER_WIDTH   = $clog2(20*SYSCLK_RATE);
parameter  EEBI_SELECT_WIDTH  = $clog2(EEBI_COUNT);

// Status
wire [2:0] sysEEBIstate;
reg  [2:0] sysEEBIstate_d, sysEEBImostRecentFault;
reg        bpmTimeout;
assign sysCsr = { !eebiResetButton_n, 3'b0,
                   1'b0, coefficientsValid, bpmTimeout, beamCurrentTimeout,
                   8'b0,
                   5'b0, sysEEBImostRecentFault,
                   3'b0, sysBeamAboveLimit,sysBeamCurrentTimeout,sysEEBIstate };

// Interlock parameters
// Set in system clock domain and used in Aurora clock domain.
// No clock domain crossing needed for these since they are used
// only when known to be stable.
// Position values in nm, current values in mA.
reg   [(EEBI_COUNT*2*FOFB_INDEX_WIDTH)-1:0] bpmSelect;
reg                    [(EEBI_COUNT*2)-1:0] planeSelect;
reg                 [(EEBI_COUNT*2*32)-1:0] offset, diffLimit;
reg                   [(EEBI_COUNT*32)-1:0] skewLimit;
reg                          sysBeamAboveLimit;
reg   [BEAM_TIMER_WIDTH-1:0] beamCurrentTimer;
reg                          sysBeamCurrentTimeout = 0;
reg                          sysCoefficientsValid = 0;
reg [(EEBI_SELECT_WIDTH+3)-1:0] sysAddressLatch;
wire                  [2:0] sysAddressCoefficientSelect = sysAddressLatch[2:0];
wire[EEBI_SELECT_WIDTH-1:0] sysAddressEEBIselect = sysAddressLatch[3+:
                                                             EEBI_SELECT_WIDTH];
always @(posedge sysClk) begin
    sysEEBIstate_d <= sysEEBIstate;
    if ((sysEEBIstate[2] == 0) && (sysEEBIstate_d[2] == 1)) begin
        sysEEBImostRecentFault <= sysEEBIstate;
        sysMostRecentFaultTime <= sysTimestamp;
    end

    beamCurrentTimer <= beamCurrentTimer - 1;
    if (beamCurrentTimer == 0) sysBeamCurrentTimeout <= 1;

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
            4'h1: offset[((sysAddressEEBIselect*2)+0)*32] <=
                                   {sysCsrWriteData[30], sysCsrWriteData[30:0]};
            4'h2: offset[((sysAddressEEBIselect*2)+1)*32] <=
                                   {sysCsrWriteData[30], sysCsrWriteData[30:0]};
            4'h3: diffLimit[((sysAddressEEBIselect*2)+0)*32+:32] <=
                                                  {1'b0, sysCsrWriteData[30:0]};
            4'h4: diffLimit[((sysAddressEEBIselect*2)+1)*32+:32] <=
                                                  {1'b0, sysCsrWriteData[30:0]};
            4'h5: skewLimit[sysAddressEEBIselect*32+:32] <=
                                                  {1'b0, sysCsrWriteData[30:0]};
            4'h7: begin
                beamCurrentTimer <= {BEAM_TIMER_WIDTH{1'b1}};
                sysBeamCurrentTimeout <= 0;
                sysBeamAboveLimit <= sysCsrWriteData[0];
                sysCoefficientsValid <= sysCsrWriteData[1];
            end
            default: ;
            endcase
        end
    end
end

// Dissect incoming data
(* mark_debug = dbg *) wire [31:0] bpmValueS, bpmValueY, bpmValueX;
(* mark_debug = dbg *) wire  [8:0] bpmIndex;
assign bpmIndex = localBPMvalues[96+:9];
assign bpmValueX = localBPMvalues[64+:32];
assign bpmValueY = localBPMvalues[32+:32];
assign bpmValueS = localBPMvalues[ 0+:32];

(* mark_debug = dbg *) reg [(EEBI_COUNT*2)-1:0] clipFaults;
(* mark_debug = dbg *) reg     [EEBI_COUNT-1:0] bpmTimeouts, bpmTrips;

genvar i;
generate
for (i = 0 ; i < EEBI_COUNT ; i = i + 1) begin
// EEBI tests of incoming data
(* mark_debug = dbg *) reg         haveBPM0, haveBPM1;
(* mark_debug = dbg *) reg         validBPM0, validBPM1;
(* mark_debug = dbg *) reg  [31:0] bpmDiff0, bpmDiff1;
(* mark_debug = dbg *) reg         filterEnable;
(* mark_debug = dbg *) wire [31:0] filteredDiff0, filteredDiff1;
(* mark_debug = dbg *) reg  [31:0] absDiff0, absDiff1, skew, absSkew;
(* mark_debug = dbg *) reg         diffFault0, diffFault1, skewFault;
localparam bpmState_IDLE     = 3'd0,
           bpmState_WAIT     = 3'd1,
           bpmState_FILTER   = 3'd2,
           bpmState_COMPUTE1 = 3'd3,
           bpmState_COMPUTE2 = 3'd4,
           bpmState_COMPUTE3 = 3'd5,
           bpmState_DONE     = 3'd6;
(* mark_debug = dbg *) reg   [2:0] bpmCheckState = bpmState_IDLE;

wire [FOFB_INDEX_WIDTH-1:0] bpmSelect0 =
                        bpmSelect[((i*2)+0)*FOFB_INDEX_WIDTH+:FOFB_INDEX_WIDTH];
wire [FOFB_INDEX_WIDTH-1:0] bpmSelect1 =
                        bpmSelect[((i*2)+1)*FOFB_INDEX_WIDTH+:FOFB_INDEX_WIDTH];
wire planeSelect0 = planeSelect[(i*2)+0];
wire planeSelect1 = planeSelect[(i*2)+1];
wire [31:0] offset0 = offset[((i*2)+0)*32+:32];
wire [31:0] offset1 = offset[((i*2)+1)*32+:32];
wire [31:0] diffLimit0 = diffLimit[((i*2)+0)*32+:32];
wire [31:0] diffLimit1 = diffLimit[((i*2)+1)*32+:32];

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
                clipFaults[(i*2)+0] <= bpmValueS[30];
                validBPM0 <= (bpmValueS[29:0] > SUM_TRIGGER_THRESHOLD);
                haveBPM0 <= 1;
            end
            if (localBPMvaluesVALID && !haveBPM1 && (bpmIndex==bpmSelect1)) begin
                bpmDiff1 <= (planeSelect1 ? bpmValueY : bpmValueX) - offset1;
                clipFaults[(i*2)+1] <= bpmValueS[30];
                validBPM1 <= (bpmValueS[29:0] > SUM_TRIGGER_THRESHOLD);
                haveBPM1 <= 1;
            end
        end

        bpmState_FILTER: begin
            filterEnable <= 0;
            bpmCheckState <= bpmState_COMPUTE1;
        end
        bpmState_COMPUTE1: bpmCheckState <= bpmState_COMPUTE2;
        bpmState_COMPUTE2: bpmCheckState <= bpmState_COMPUTE3;
        bpmState_COMPUTE3: bpmCheckState <= bpmState_DONE;
        bpmState_DONE: begin
            bpmTrips[i] <= (validBPM0
                          && validBPM1
                          && (diffFault0 || diffFault1 || skewFault));
        end

        default: ;
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
    skewFault <= (absSkew > skewLimit);
end
end
endgenerate

// EEBI
localparam EEBIstate_UNCONFIGURED = 3'd0,
           EEBIstate_TIMEOUT      = 3'd1,
           EEBIstate_CLIPPING     = 3'd2,
           EEBIstate_TRIPPED      = 3'd3,
           EEBIstate_UNDERCURRENT = 3'd4,
           EEBIstate_ARMED        = 3'd5;
(* mark_debug = dbg *) reg [2:0] EEBIstate = EEBIstate_UNCONFIGURED;
assign eebiRelay = EEBIstate[2];

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
    bpmTrip      <= |bpmTrips;

    if (EEBIstate == EEBIstate_TRIPPED) begin
        if (eebiReset) begin
            EEBIstate <= EEBIstate_TIMEOUT;
        end
    end
    else if (!coefficientsValid) begin
        EEBIstate <= EEBIstate_UNCONFIGURED;
    end
    else if (!beamCurrentTimeout && !beamAboveLimit) begin
        EEBIstate <= EEBIstate_UNDERCURRENT;
    end
    else if (bpmTimeout) begin
        EEBIstate <= EEBIstate_TIMEOUT;
    end
    else if (bpmClipFault) begin
        EEBIstate <= EEBIstate_CLIPPING;
    end
    else if (bpmTrip) begin
        EEBIstate <= EEBIstate_TRIPPED;
    end
    else begin
        EEBIstate <= EEBIstate_ARMED;
    end
end

forwardData #(.DATA_WIDTH(3)) forwardEEBIstate (
            .inClk(auroraUserClk),
            .inData(EEBIstate),
            .outClk(sysClk),
            .outData(sysEEBIstate));

endmodule
