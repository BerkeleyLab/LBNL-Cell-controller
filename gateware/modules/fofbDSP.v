//
// Compute power supply setpoints
//
module fofbDSP #(
    parameter SOFT_START_STEPS             = 1024,
    parameter RESULT_COUNT                 = 1,
    parameter MATRIX_MULTIPLY_RESULT_WIDTH = 26,
    parameter FOFB_MATRIX_ADDR_WIDTH       = -1,
    parameter MATMUL_DEBUG                 = "false",
    parameter FIR_DEBUG                    = "false",
    parameter TX_AXIS_DEBUG                = "false") (
    input  wire                             clk,
    input  wire                             csrStrobe,
    input  wire                      [31:0] GPIO_OUT,
    output wire                      [31:0] firStatus,
    input wire                              fofbEnabled,

    // Read BPM deviations
    input  wire                       [31:0] fofbReadoutCSR,
    output wire [FOFB_MATRIX_ADDR_WIDTH-1:0] fofbDSPreadoutAddress,
    input  wire                       [31:0] fofbDSPreadoutX,
    input  wire                       [31:0] fofbDSPreadoutY,
    input  wire                       [31:0] fofbDSPreadoutS,

    // Results
    (*mark_debug=TX_AXIS_DEBUG*) output wire        SETPOINT_TVALID,
    (*mark_debug=TX_AXIS_DEBUG*) output wire        SETPOINT_TLAST,
    (*mark_debug=TX_AXIS_DEBUG*) output wire [31:0] SETPOINT_TDATA);

localparam COEF_ROWINDEX_WIDTH = RESULT_COUNT == 1 ? 1 : $clog2(RESULT_COUNT);
localparam XYDATA_WIDTH        = 25;
localparam COEFFICIENT_WIDTH   = 32;
localparam PRODUCT_WIDTH       = XYDATA_WIDTH + COEFFICIENT_WIDTH;
localparam PRODUCT_WIDEN       = FOFB_MATRIX_ADDR_WIDTH;
localparam ACCUMULATOR_WIDTH   = PRODUCT_WIDTH + PRODUCT_WIDEN;
localparam MULTIPLIER_LATENCY  = 4;

`include "gpioIDX.v"
wire [3:0] csrAction = GPIO_OUT[GPIO_DSP_CMD_SHIFT+:4];

// Status register
wire firReloadBusy, firConfigBusy;
wire firReloadTLASTmissing, firReloadTLASTunexpected;
assign firStatus = { {28{1'b0}}, firReloadTLASTunexpected,
                                 firReloadTLASTmissing,
                                 firConfigBusy,
                                 firReloadBusy };

// Inverse sensitivity matrix, FIR, and gain coefficient updates
reg [COEF_ROWINDEX_WIDTH-1:0] coefficientWriteRow;
reg                           coefficientWritePlane; // 0=X, 1=Y
reg [FOFB_MATRIX_ADDR_WIDTH-1:0] coefficientWriteColumn;
reg [COEFFICIENT_WIDTH/2-1:0] coefficientHighLatch;
wire  [COEFFICIENT_WIDTH-1:0] coefficientWriteValue = { coefficientHighLatch,
                                            GPIO_OUT[COEFFICIENT_WIDTH/2-1:0] };
wire matrixWriteStrobe = csrStrobe &&
                              (csrAction == GPIO_DSP_CMD_WRITE_MATRIX_ELEMENT);
wire firReloadStrobe = csrStrobe && (csrAction == GPIO_DSP_CMD_FIR_RELOAD);
wire firConfigStrobe = csrStrobe && (csrAction == GPIO_DSP_CMD_FIR_CONFIG);

// DSP/FOFB control
always @(posedge clk) begin
    if (csrStrobe) begin
        case (csrAction)
        GPIO_DSP_CMD_LATCH_ADDRESS: begin
            coefficientWriteColumn <= GPIO_OUT[0+:FOFB_MATRIX_ADDR_WIDTH];
            coefficientWritePlane <= GPIO_OUT[FOFB_MATRIX_ADDR_WIDTH+:1];
            coefficientWriteRow <= GPIO_OUT[FOFB_MATRIX_ADDR_WIDTH+1+:
                                                           COEF_ROWINDEX_WIDTH];
        end
        GPIO_DSP_CMD_LATCH_HIGH_VALUE: begin
            coefficientHighLatch <= GPIO_OUT[COEFFICIENT_WIDTH/2-1:0];
        end
        default: ;
        endcase
    end
end

// Fast orbit feedback corrector setpoint calculation
wire                                                  fofbToggle;
wire[(RESULT_COUNT*MATRIX_MULTIPLY_RESULT_WIDTH)-1:0] fofbData;
fofbCalc #(
    .RESULT_COUNT(RESULT_COUNT),
    .RESULT_WIDTH(MATRIX_MULTIPLY_RESULT_WIDTH),
    .MATRIX_COLUMN_WIDTH(FOFB_MATRIX_ADDR_WIDTH),
    .COEFFICIENT_WIDTH(COEFFICIENT_WIDTH),
    .MATMUL_DEBUG(MATMUL_DEBUG),
    .FIR_DEBUG(FIR_DEBUG))
        fofbCalc (.clk(clk),
                  .coefficientWriteStrobe(matrixWriteStrobe),
                  .firReloadStrobe(firReloadStrobe),
                  .firConfigStrobe(firConfigStrobe),
                  .coefficientWriteRow(coefficientWriteRow),
                  .coefficientWritePlane(coefficientWritePlane),
                  .coefficientWriteColumn(coefficientWriteColumn),
                  .coefficientWriteValue(coefficientWriteValue),
                  .firReloadBusy(firReloadBusy),
                  .firConfigBusy(firConfigBusy),
                  .firReloadTLASTmissing(firReloadTLASTmissing),
                  .firReloadTLASTunexpected(firReloadTLASTunexpected),
                  .fofbReadoutCSR(fofbReadoutCSR),
                  .fofbDSPreadoutAddress(fofbDSPreadoutAddress),
                  .fofbDSPreadoutX(fofbDSPreadoutX),
                  .fofbDSPreadoutY(fofbDSPreadoutY),
                  .fofbDSPreadoutS(fofbDSPreadoutS),
                  .doutToggle(fofbToggle),
                  .dout(fofbData));

// Convert setpoint values to floating point AXI stream
wire gainWriteStrobe = csrStrobe && (csrAction==GPIO_DSP_CMD_WRITE_FOFB_GAIN);
wire ffbClipWriteStrobe=csrStrobe&&(csrAction==GPIO_DSP_CMD_WRITE_FFB_CLIP_LIMIT);
wire psOffsetWriteStrobe=csrStrobe && (csrAction==GPIO_DSP_CMD_WRITE_PS_OFFSET);
wire psClipWriteStrobe=csrStrobe&&(csrAction==GPIO_DSP_CMD_WRITE_PS_CLIP_LIMIT);
psSetpointCalc #(
    .SOFT_START_STEPS(SOFT_START_STEPS),
    .RESULT_COUNT(RESULT_COUNT),
    .DIN_WIDTH(MATRIX_MULTIPLY_RESULT_WIDTH))
  psSetpointCalc (
    .clk(clk),
    .fofbEnabled(fofbEnabled),
    .gainWriteStrobe(gainWriteStrobe),
    .ffbClipWriteStrobe(ffbClipWriteStrobe),
    .psOffsetWriteStrobe(psOffsetWriteStrobe),
    .psClipWriteStrobe(psClipWriteStrobe),
    .writeAddress(coefficientWriteRow),
    .writeData(coefficientWriteValue),
    .dinToggle(fofbToggle),
    .din(fofbData),
    .SETPOINT_TVALID(SETPOINT_TVALID),
    .SETPOINT_TLAST(SETPOINT_TLAST),
    .SETPOINT_TDATA(SETPOINT_TDATA));

endmodule
