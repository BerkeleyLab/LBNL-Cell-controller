//
// Read values from BPM links and produce a packet containing merged values.
// Nets with names beginning with 'sys' are in the system clock domain.
// All other nets are in the Aurora user clock domain.
//
module writeBPMTestLink #(
    parameter faStrobeDebug    = "false",
    parameter stateDebug       = "false",
    parameter testInDebug      = "false") (
    // Start of Aurora user clock domain nets
    input  wire         auroraUserClk,

    // Marker for beginning of data transfer session
    (* mark_debug = faStrobeDebug *)
    input  wire         auroraFAstrobe,
    input  wire         auroraChannelUp,

    // BPM links
    (* mark_debug = testInDebug *)
    output  wire  [31:0] BPM_TEST_AXI_STREAM_TX_tdata,
    (* mark_debug = testInDebug *)
    output  wire         BPM_TEST_AXI_STREAM_TX_tvalid,
    (* mark_debug = testInDebug *)
    output  wire         BPM_TEST_AXI_STREAM_TX_tlast,
    (* mark_debug = testInDebug *)
    input  wire         BPM_TEST_AXI_STREAM_TX_tready,
    output wire         TESTstatusStrobe,
    output wire  [1:0]  TESTstatusCode,
    output wire  [2:0]  dbgFwState
);

localparam MAX_CELLS          = 32;
parameter CELL_COUNT_WIDTH    = $clog2(MAX_CELLS + 1);
parameter CELL_INDEX_WIDTH    = $clog2(MAX_CELLS);
localparam MAX_BPMS_PER_CELL  = 32;
parameter BPM_COUNT_WIDTH     = $clog2(MAX_BPMS_PER_CELL + 1);
parameter BPM_INDEX_WIDTH     = $clog2(MAX_BPMS_PER_CELL);
parameter FOFB_INDEX_WIDTH    = 9;

// Could be made register in the future if needed
localparam BPM_COUNT_PER_SECTOR = 16;
localparam CELL_INDEX = 12;
localparam BPM_GLOBAL_INDEX = 2;

assign TESTstatusStrobe = 0;
assign TESTstatusCode = 0;

wire  [BPM_COUNT_WIDTH-1:0] BPMcount = BPM_COUNT_PER_SECTOR;
wire [CELL_INDEX_WIDTH-1:0] cellIndex = CELL_INDEX;

// Dissect merged data word
reg [BPM_INDEX_WIDTH-1:0]                   BPMIndex = 0;
wire [FOFB_INDEX_WIDTH-BPM_INDEX_WIDTH-1:0] BPMGlobalPrefix = BPM_GLOBAL_INDEX;
wire [FOFB_INDEX_WIDTH-1:0] FOFBIndex = {
    BPMGlobalPrefix,
    BPMIndex
};

// Forwarded values
wire FOFBenabled = 1;
wire [31:0] txHeader = {
                16'hA5BE,
                FOFBenabled,
                {6-1-CELL_INDEX_WIDTH{1'b0}}, cellIndex,
                {10-FOFB_INDEX_WIDTH{1'b0}}, FOFBIndex};
reg [31:0] txXerror = 0;
reg [31:0] txYerror = 0;
reg [31:0] sum = 0;

localparam FIFO_AW = 3;
localparam FIFO_USERW = 1;
localparam FIFO_DATAW = 32;
localparam FIFO_DW = FIFO_USERW + FIFO_DATAW;
localparam FIFO_MAX = 2**FIFO_AW-1;

reg [FIFO_USERW-1:0] fifoUserIn = 0;
reg [FIFO_DATAW-1:0] fifoDataIn = 0;
wire [FIFO_DW-1:0] fifoIn = {fifoUserIn, fifoDataIn};
reg fifoWe = 0;
reg fifoForceRe = 0;
wire [FIFO_DW-1:0] fifoOut;
wire [FIFO_USERW-1:0] fifoUserOut;
wire [FIFO_DATAW-1:0] fifoDataOut;
wire fifoRe;
wire fifoFull, fifoEmpty;
wire signed [FIFO_AW:0] fifoCount;
genericFifo #(
    .aw(FIFO_AW),
    .dw(FIFO_DW),
    .fwft(1))
fifo (
    .clk(auroraUserClk),

    .din(fifoIn),
    .we(fifoWe),

    .dout(fifoOut),
    .re(fifoRe),

    .full(fifoFull),
    .empty(fifoEmpty),

    .count(fifoCount)
);

assign {fifoUserOut, fifoDataOut} = fifoOut;

wire fifoValid = !(fifoEmpty || fifoForceRe);
wire fifoAlmostFull = (fifoCount >= FIFO_MAX-2);

assign fifoRe = (fifoValid && BPM_TEST_AXI_STREAM_TX_tready) || fifoForceRe;
assign BPM_TEST_AXI_STREAM_TX_tdata = fifoDataOut;
assign BPM_TEST_AXI_STREAM_TX_tlast = fifoUserOut;
assign BPM_TEST_AXI_STREAM_TX_tvalid = fifoValid;

// Data forwarding state machine
localparam FWST_IDLE          = 0,
           FWST_EMPTY_FIFO    = 1,
           FWST_PUSH_HEADER   = 2,
           FWST_PUSH_X        = 3,
           FWST_PUSH_Y        = 4,
           FWST_PUSH_S        = 5;
(* mark_debug = stateDebug *) reg  [2:0] fwState = FWST_IDLE;
assign dbgFwState = fwState;
reg [15:0] FAcycleCounter = 0;
always @(posedge auroraUserClk) begin
    if (auroraFAstrobe) begin
        // Start a new readout session
        FAcycleCounter <= FAcycleCounter + 1;
        BPMIndex <= 0;
        fwState <= (BPMcount == 0) ? FWST_IDLE : FWST_EMPTY_FIFO;
    end
    else begin
        fifoWe <= 0;

        case (fwState)
        FWST_IDLE: begin
        end

        FWST_EMPTY_FIFO: begin
            if (!fifoEmpty) begin
                fifoForceRe <= 1;
            end
            else begin
                fifoForceRe <= 0;
                if (auroraChannelUp) begin
                    fwState <= FWST_PUSH_HEADER;
                end
            end
        end

        FWST_PUSH_HEADER: begin
            if (!fifoAlmostFull) begin
                fifoWe <= 1;
                fifoDataIn <= txHeader;
                fifoUserIn <= 0;

                BPMIndex <= BPMIndex + 1;
                txXerror <= {16'hCAFE, {16-BPM_INDEX_WIDTH{1'b0}}, BPMIndex};
                txYerror <= {16'hBEEF, {16-BPM_INDEX_WIDTH{1'b0}}, BPMIndex};
                sum      <= {FAcycleCounter, {16-BPM_INDEX_WIDTH{1'b0}}, BPMIndex};
                fwState <= FWST_PUSH_X;
            end
        end

        FWST_PUSH_X: begin
            if (!fifoAlmostFull) begin
                fifoWe <= 1;
                fifoDataIn <= txXerror;
                fifoUserIn <= 0;
                fwState <= FWST_PUSH_Y;
            end
        end

        FWST_PUSH_Y: begin
            if (!fifoAlmostFull) begin
                fifoWe <= 1;
                fifoDataIn <= txYerror;
                fifoUserIn <= 0;
                fwState <= FWST_PUSH_S;
            end
        end

        FWST_PUSH_S: begin
            if (!fifoAlmostFull) begin
                fifoWe <= 1;
                fifoDataIn <= sum;
                fifoUserIn <= 1;

                if (BPMIndex == BPMcount) begin
                    fwState <= FWST_IDLE;
                end
                else begin
                    fwState <= FWST_PUSH_HEADER;
                end
            end
        end

        default: ;
        endcase
    end
end

endmodule
