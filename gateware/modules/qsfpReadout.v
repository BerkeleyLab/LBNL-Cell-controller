//
// Read values from QSFP module(s).
// Very basic -- no clock stretching.
//            -- No ACK check.  If there's no module present we'll just read 1s
// The pullups inside the FPGA are quite weak so 100 kb/s is the limit.
//
module qsfpReadout #(
    parameter dbg         = "false",
    parameter QSFP_COUNT  = 2,
    parameter CLOCK_RATE  = 100000000,
    parameter BIT_RATE    = 100000,
    parameter IIC_ADDRESS = 7'h50) (
    input  wire                          clk,
    input  wire [$clog2(QSFP_COUNT)+6:0] readAddress,
    output wire                   [15:0] readData,
    (* mark_debug=dbg *)
    input  wire         [QSFP_COUNT-1:0] PRESENT_n,
    output wire         [QSFP_COUNT-1:0] RESET_n,
    output wire         [QSFP_COUNT-1:0] MODSEL_n,
    output wire         [QSFP_COUNT-1:0] LPMODE,
    inout wire                           SCL,
    inout wire                           SDA);

// Force correct number of bits in case IIC_ADDRESS is overridden with
// an integer or some other value with the wrong number of bits.
wire [6:0] iicAddress;
assign iicAddress = IIC_ADDRESS;

// Timing
parameter TICK_DIVISOR = (CLOCK_RATE+(BIT_RATE*4)-1) / (BIT_RATE*4);
parameter TICK_COUNTER_RELOAD = TICK_DIVISOR - 1;
(* mark_debug=dbg *)reg [$clog2(TICK_DIVISOR)-1:0] tickCounter = 0;
(* mark_debug=dbg *)reg                            tick = 0;

// Result DPRAM
// Write 16 bit words to ensure that multi-byte read values are consistent
reg [15:0] dpram [0:(256*QSFP_COUNT)-1];
reg [15:0] dpram_q;
(* mark_debug=dbg *)reg                           dpram_wen = 0;
(* mark_debug=dbg *)reg                    [15:0] rbuf = 0;
(* mark_debug=dbg *)wire [$clog2(QSFP_COUNT)+6:0] writeAddress;
always @(posedge clk) begin
    dpram_q <= dpram[readAddress];
    if (dpram_wen) dpram[writeAddress] <= rbuf;
end
assign readData = dpram_q;

// State machine
localparam S_START        = 0,
           S_SEND         = 1,
           S_READ         = 2,
           S_STOP         = 3,
           S_SELECT       = 4,
           S_MODSEL_DELAY = 5;
localparam SHIFT_TOP = 17;
(* mark_debug=dbg *)reg [2:0] state = S_START;
(* mark_debug=dbg *)reg                    [1:0] phase = 0;
(* mark_debug=dbg *)reg                          reading = 0;
(* mark_debug=dbg *)reg                    [4:0] bitsLeft = 0;
(* mark_debug=dbg *)reg                    [7:0] byteCount = 0;
(* mark_debug=dbg *)reg [$clog2(QSFP_COUNT)-1:0] qsfpCount = 0;
(* mark_debug=dbg *)reg            [SHIFT_TOP:0] txShift = {SHIFT_TOP+1{1'b1}};

// IIC pins
(* mark_debug=dbg *)reg SCL_t = 1'b1;
(* mark_debug=dbg *)wire SCL_i;
IOBUF IOBUF_SCL(.T(SCL_t), .I(1'b0), .O(SCL_i), .IO(SCL));
(* mark_debug=dbg *)wire SDA_i;
IOBUF IOBUF_SDA(.T(txShift[SHIFT_TOP]), .I(1'b0), .O(SDA_i), .IO(SDA));
assign LPMODE = 0;
(* mark_debug=dbg *)reg [QSFP_COUNT-1:0] MODSEL = {{QSFP_COUNT-1{1'b1}}, 1'b0};

//
// Main state machine
//
assign writeAddress = { qsfpCount, byteCount[7:1] };
always @(posedge clk) begin
    if (tickCounter) begin
        tickCounter <= tickCounter - 1;
        tick <= 1'b0;
    end
    else begin
        tickCounter <= TICK_COUNTER_RELOAD;
        tick <= 1'b1;
        phase <= phase + 1;
    end
    dpram_wen <= (tick && (state == S_READ) && (phase == 2'b10) &&
                               (bitsLeft == 0) && (byteCount[0] == 1'b1));
    if (tick) begin
        case (state)
        S_START:
            case (phase)
            2'b00: SCL_t <= 1'b1;
            2'b01: txShift[SHIFT_TOP] <= 1'b0;
            2'b10: SCL_t <= 1'b0;
            2'b11: begin
                if (reading) begin
                    bitsLeft <= 8;
                    txShift <= { iicAddress, 1'b1, 1'b1,
                                 8'hFF,            1'b1 };
                end
                else begin
                    bitsLeft <= 17;
                    txShift <= { iicAddress,    1'b0, 1'b1,
                                 byteCount[7], 7'h00, 1'b1 };
                end
                state <= S_SEND;
            end
            default: ;
            endcase

        S_SEND:
            case (phase)
            2'b00: SCL_t <= 1'b1;
            2'b01: ;
            2'b10: SCL_t <= 1'b0;
            2'b11: begin
                if (bitsLeft) begin
                    txShift <= { txShift[SHIFT_TOP-1:0], 1'b1 };
                    bitsLeft <= bitsLeft - 1;
                end
                else begin
                    bitsLeft <= 8;
                    reading <= 1;
                    if (reading)
                        state <= S_READ;
                    else
                        state <= S_START;
                end
            end
            default: ;
            endcase

        S_READ:
            case (phase)
            2'b00: SCL_t <= 1'b1;
            2'b01: if (bitsLeft != 0) rbuf <= { rbuf[14:0], SDA_i };
            2'b10: SCL_t <= 1'b0;
            2'b11: begin
                if (bitsLeft) begin
                    bitsLeft <= bitsLeft - 1;
                    if ((bitsLeft == 1) && (byteCount[6:0] != 7'h7F)) begin
                        txShift[SHIFT_TOP] <= 0;
                    end
                    else begin
                        txShift[SHIFT_TOP] <= 1;
                    end
                end
                else begin
                    bitsLeft <= 8;
                    byteCount <= byteCount + 1;
                    txShift[SHIFT_TOP] <= 1;
                    if (byteCount[6:0] == 7'h7F) begin
                        reading <= 0;
                        state <= S_STOP;
                    end
                end
            end
            default: ;
            endcase

        S_STOP:
            case (phase)
            2'b00: txShift[SHIFT_TOP] <= 1'b0;
            2'b01: SCL_t <= 1'b1;
            2'b10: txShift[SHIFT_TOP] <= 1'b1;
            2'b11: begin
                if (byteCount[7]) begin
                    state <= S_START;
                end
                else begin
                    state <= S_SELECT;
                end
            end
            default: ;
            endcase

        S_SELECT:
            if (phase == 2'b11) begin
                if (qsfpCount == (QSFP_COUNT - 1)) begin
                    qsfpCount <= 0;
                    MODSEL <= 1;
                end
                else begin
                    qsfpCount <= qsfpCount + 1;
                    MODSEL <= { MODSEL[QSFP_COUNT-2:0], 1'b0 };
                end
                byteCount <= ~0;
                state <= S_MODSEL_DELAY;
            end

        S_MODSEL_DELAY:
            if (phase == 2'b11) begin
                if (byteCount) begin
                    byteCount <= byteCount - 1;
                end
                else begin
                    state <= S_START;
                end
            end

        default: ;
        endcase
    end
end

// Module reset state machine
parameter RESET_DIVISOR = CLOCK_RATE / 100;
reg [$clog2(RESET_DIVISOR)-1:0] resetDivider = RESET_DIVISOR - 1;
(* mark_debug=dbg *)reg resetCheck = 0;
always @(posedge clk) begin
    if (resetDivider == 0) begin
        resetDivider <= RESET_DIVISOR - 1;
        resetCheck <= 1;
    end
    else begin
        resetDivider <= resetDivider - 1;
        resetCheck <= 0;
    end
end

genvar i;
generate
for (i = 0 ; i < QSFP_COUNT ; i = i + 1) begin : qsfp

(* mark_debug=dbg *)reg RESET_a = 1, RESET = 1;
OBUFT OBUFT_MODSEL(.T(!MODSEL[i]), .I(1'b0), .O(MODSEL_n[i]));
OBUFT OBUFT_RESET(.T(!RESET), .I(1'b0), .O(RESET_n[i]));

always @(posedge clk) begin
    if (PRESENT_n[i] == 1) begin
        RESET <= 1;
        RESET_a <= 1;
    end
    else if (resetCheck) begin
        if (RESET_a == 1) begin
            RESET_a <= 0;
        end
        else begin
            RESET <= 0;
        end
    end
end

end /* endfor */
endgenerate

endmodule
