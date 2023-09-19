//
// Multiply position deviations by inverse sensitivity matrix row(s).
// Apply FIR to matrix multiplication result(s).
//
// Matrix Multiplication Scaling
// =============================
// Coefficient waveform record element range is [-1,1) A/um.  Sent as a 32 bit
// integer so the coefficient matrix element least significant bit has
// the value 1/2^31 A/um.
// Position errors are in units of nm.
// Thus the least significant bit of the full width product is 1/2^31 mA.
// Multiplier is configured to discard least significant 16 bits of the product
// so the least significant bit of the accumulators is 1/2^15 mA.
// The least significant five bits of the accumulator are discarded so the
// least significant bit of the matrix multiplication result is 1/2^10 mA.
//
// Output Scaling
// ==============
// The FIR filter output is clipped to 26 bits so the full scale range
// is a a little more than +/-32.7 A.
//
module fofbCalc #(
    parameter RESULT_COUNT        = 1,
    parameter RESULT_WIDTH        = 26,
    parameter COEFFICIENT_WIDTH   = 32,
    parameter MATRIX_COLUMN_WIDTH = 9,
    parameter COEF_ROWS_WIDTH = RESULT_COUNT == 1 ? 1 : $clog2(RESULT_COUNT),
    parameter MATMUL_DEBUG    = "false",
    parameter FIR_DEBUG       = "false") (
    input  wire                                  clk,

    input  wire                                  coefficientWriteStrobe,
    input  wire                                  firReloadStrobe,
    input  wire                                  firConfigStrobe,
    input  wire            [COEF_ROWS_WIDTH-1:0] coefficientWriteRow,
    input  wire                                  coefficientWritePlane,
    input  wire      [MATRIX_COLUMN_WIDTH-1:0] coefficientWriteColumn,
    input  wire          [COEFFICIENT_WIDTH-1:0] coefficientWriteValue,
    output reg                                   firReloadBusy,
    output reg                                   firConfigBusy,
    output reg                                   firReloadTLASTmissing,
    output reg                                   firReloadTLASTunexpected,

    input  wire                           [31:0] fofbReadoutCSR,
    output reg         [MATRIX_COLUMN_WIDTH-1:0] fofbDSPreadoutAddress,
    input  wire                           [31:0] fofbDSPreadoutX,
    input  wire                           [31:0] fofbDSPreadoutY,
    input  wire                           [31:0] fofbDSPreadoutS,

    // Proportional and derivative (FIR) control action -- parallel ouput
    output reg                                   doutToggle = 0,
    output wire[(RESULT_COUNT*RESULT_WIDTH)-1:0] dout);

localparam XYDATA_WIDTH       = 25;
localparam PRODUCT_WIDTH      = XYDATA_WIDTH + COEFFICIENT_WIDTH - 16;
localparam PRODUCT_WIDEN      = MATRIX_COLUMN_WIDTH;
localparam ACCUMULATOR_WIDTH  = PRODUCT_WIDTH + PRODUCT_WIDEN;
localparam MATMUL_LSB_OFFSET  = 5;
localparam MULTIPLIER_LATENCY = 4;

///////////////////////////////////////////////////////////////////////////////
// Extract position values and saturate to desired width.
// Option of using fake data to check latency and such.
(*mark_debug=MATMUL_DEBUG*) wire signed [XYDATA_WIDTH-1:0] xNarrow, yNarrow;
reduceWidth #(.IWIDTH(32), .OWIDTH(XYDATA_WIDTH)) reduceX (.I(fofbDSPreadoutX),
                                                           .O(xNarrow));
reduceWidth #(.IWIDTH(32), .OWIDTH(XYDATA_WIDTH)) reduceY (.I(fofbDSPreadoutY),
                                                           .O(yNarrow));
(*mark_debug=MATMUL_DEBUG*) reg signed [XYDATA_WIDTH-1:0] xFake, yFake;
(*mark_debug=MATMUL_DEBUG*)wire signed [XYDATA_WIDTH-1:0] xVal, yVal;
wire useFakeData = fofbReadoutCSR[20];
assign xVal = useFakeData ? xFake : xNarrow;
assign yVal = useFakeData ? yFake : yNarrow;

///////////////////////////////////////////////////////////////////////////////
// Compute dot product of clipped beam position offset vector
// and salient rows of inverse sensitivity matrix.

// Computation state machine
localparam ST_IDLE       = 2'd0,
           ST_FILL       = 2'd1,
           ST_ACCUMULATE = 2'd2;
reg [1:0] state = ST_IDLE;

wire fofbReadoutActive = fofbReadoutCSR[31];
wire fofbReadoutValid = fofbReadoutCSR[30];
reg fofbReadoutActive_d, fofbReadoutValid_d = 0;
(*mark_debug=MATMUL_DEBUG*)reg accumulate = 0, clear = 0;
(*mark_debug=FIR_DEBUG*) reg sumValid = 0;
localparam FAKE_DATA_COUNTER_WIDTH = 12;
reg [FAKE_DATA_COUNTER_WIDTH-1:0] fakeDataCounter = 0;

always @(posedge clk) begin
    fofbReadoutActive_d <= fofbReadoutActive;
    fofbReadoutValid_d <= fofbReadoutValid;
    case (state)
    // Wait for new data to arrive or acquisition interval to end
    ST_IDLE: begin
        sumValid <= 0;
        if ((fofbReadoutValid && !fofbReadoutValid_d)
         ||  (!fofbReadoutActive && fofbReadoutActive_d)) begin
            fofbDSPreadoutAddress <= fofbDSPreadoutAddress + 1;
            clear <= 1;
            state <= ST_FILL;
        end
        else begin
            fofbDSPreadoutAddress <= 0;
        end
    end

    // Fill multiplier pipeline
    ST_FILL: begin
        xFake <= 0;
        yFake <= 0;
        clear <= 0;
        fofbDSPreadoutAddress <= fofbDSPreadoutAddress + 1;
        if (fofbDSPreadoutAddress[2:0] == MULTIPLIER_LATENCY) begin
            accumulate <= 1;
            state <= ST_ACCUMULATE;
        end
    end

    // Accumulate
    ST_ACCUMULATE: begin
        fofbDSPreadoutAddress <= fofbDSPreadoutAddress + 1;
        if (fofbDSPreadoutAddress == MULTIPLIER_LATENCY) begin
            if (fakeDataCounter[FAKE_DATA_COUNTER_WIDTH-1]) begin
                fakeDataCounter <= 0;
                xFake <=  1000000;
                yFake <= -1000000;
            end
            else begin
                fakeDataCounter <= fakeDataCounter + 1;
            end
            accumulate <= 0;
            sumValid <= 1;
            state <= ST_IDLE;
        end
    end
    default: ;
    endcase
end

wire [RESULT_COUNT-1:0] firReloadReady, firConfigReady;
wire [RESULT_COUNT-1:0] fir_reload_tlast_missing, fir_reload_tlast_unexpected;
always @(posedge clk) begin
    firReloadBusy <= |(~firReloadReady);
    firConfigBusy <= |(~firConfigReady);
    firReloadTLASTmissing <= |fir_reload_tlast_missing;
    firReloadTLASTunexpected <= |fir_reload_tlast_unexpected;
end

// Matrix mulitplication result
localparam FIR_INPUT_WIDTH = 32;
wire [RESULT_COUNT*FIR_INPUT_WIDTH-1:0] matrixProduct;

//////////////////////////////////////////////////////////////////////////////
// Replicated multiply-accumulate operations -- one per output value
genvar r;
generate
for (r = 0 ; r < RESULT_COUNT ; r = r + 1) begin : fofbRow
localparam MAT_DBG = (r == 0) ? MATMUL_DEBUG : "false";
localparam FIR_DBG = (r == 0) ? FIR_DEBUG : "false";
(*mark_debug=MAT_DBG*)wire[COEFFICIENT_WIDTH-1:0]coefficientY,coefficientX;
wire weaX, weaY;
assign weaX = coefficientWriteStrobe && (coefficientWritePlane == 0)
                                     && (coefficientWriteRow == r);
assign weaY = coefficientWriteStrobe && (coefficientWritePlane == 1)
                                     && (coefficientWriteRow == r);

// Coefficient DPRAM -- half a row of inverse sensitivity matrix each
fofbDataDPRAM #(.DATA_WIDTH(COEFFICIENT_WIDTH)) coefficientDPRAMX (
                                            .clk(clk),
                                            .wea(weaX),
                                            .addra(coefficientWriteColumn),
                                            .dina(coefficientWriteValue),
                                            .addrb(fofbDSPreadoutAddress),
                                            .doutb(coefficientX));
fofbDataDPRAM #(.DATA_WIDTH(COEFFICIENT_WIDTH)) coefficientDPRAMY (
                                            .clk(clk),
                                            .wea(weaY),
                                            .addra(coefficientWriteColumn),
                                            .dina(coefficientWriteValue),
                                            .addrb(fofbDSPreadoutAddress),
                                            .doutb(coefficientY));

// Multiply position error by coefficient
wire [PRODUCT_WIDTH-1:0] productY, productX;
(*mark_debug=MAT_DBG*)reg[ACCUMULATOR_WIDTH-1:0]accumulatorY, accumulatorX;
`ifndef SIMULATE
`ifndef TESTBENCH
fofbCoefficientMul mulX (.CLK(clk),
                         .A(xVal),
                         .B(coefficientX),
                         .P(productX));
fofbCoefficientMul mulY (.CLK(clk),
                         .A(yVal),
                         .B(coefficientY),
                         .P(productY));
`endif
`endif

// Accumulate dot product
localparam SUM_WIDTH = ACCUMULATOR_WIDTH + 1;
wire [SUM_WIDTH-1:0] sum;
assign sum = {accumulatorX[ACCUMULATOR_WIDTH-1], accumulatorX} +
             {accumulatorY[ACCUMULATOR_WIDTH-1], accumulatorY};
always @(posedge clk)begin
    if (clear) begin
        accumulatorX <= 0;
        accumulatorY <= 0;
    end
    else if (accumulate) begin
        accumulatorX <= accumulatorX +
                        {{PRODUCT_WIDEN{productX[PRODUCT_WIDTH-1]}}, productX};
        accumulatorY <= accumulatorY +
                        {{PRODUCT_WIDEN{productY[PRODUCT_WIDTH-1]}}, productY};
    end
end

// Clip matrix multiplication result
localparam FIR_INPUT_WIDTH = 32;
(*mark_debug=MAT_DBG*) wire [FIR_INPUT_WIDTH-1:0] clippedSum;
reduceWidth #(.IWIDTH(SUM_WIDTH-MATMUL_LSB_OFFSET),
              .OWIDTH(FIR_INPUT_WIDTH))
                reduceSum (.I(sum[SUM_WIDTH-1:MATMUL_LSB_OFFSET]),
                           .O(clippedSum));
assign matrixProduct[r*FIR_INPUT_WIDTH+:FIR_INPUT_WIDTH] = clippedSum;

///////////////////////////////////////////////////////////////////////////////
// Apply FIR filter
localparam FIR_OUTPUT_WIDTH = 48;
(*mark_debug=FIR_DBG*) wire [FIR_INPUT_WIDTH-1:0] fir_S_TDATA;
(*mark_debug=FIR_DBG*) wire                       fir_S_TVALID;
(*mark_debug=FIR_DBG*) wire                       fir_S_TREADY;
assign fir_S_TDATA = clippedSum;
assign fir_S_TVALID = sumValid;
(*mark_debug=FIR_DBG*) wire [FIR_OUTPUT_WIDTH-1:0] fir_M_TDATA;
(*mark_debug=FIR_DBG*) wire                        fir_M_TVALID;
(*mark_debug=FIR_DBG*) wire [31:0] fir_reload_TDATA;
(*mark_debug=FIR_DBG*) wire fir_reload_TVALID, fir_reload_TLAST;
assign fir_reload_TDATA = coefficientWriteValue;
assign fir_reload_TVALID = firReloadStrobe && (coefficientWriteRow == r);
assign fir_reload_TLAST = coefficientWritePlane;
(*mark_debug=FIR_DBG*) wire [7:0] fir_config_TDATA;
(*mark_debug=FIR_DBG*) wire fir_config_TVALID;
assign fir_config_TDATA = coefficientWriteValue[7:0];
assign fir_config_TVALID = firConfigStrobe && (coefficientWriteRow == r);
`ifndef SIMULATE
`ifndef TESTBENCH
fofbSupplyFilter fir (
  .aclk(clk),
  .s_axis_data_tvalid(fir_S_TVALID),
  .s_axis_data_tready(fir_S_TREADY),
  .s_axis_data_tdata(fir_S_TDATA),
  .s_axis_config_tvalid(fir_config_TVALID),
  .s_axis_config_tready(firConfigReady[r]),
  .s_axis_config_tdata(fir_config_TDATA),
  .s_axis_reload_tvalid(fir_reload_TVALID),
  .s_axis_reload_tready(firReloadReady[r]),
  .s_axis_reload_tlast(fir_reload_TLAST),
  .s_axis_reload_tdata(fir_reload_TDATA),
  .m_axis_data_tvalid(fir_M_TVALID),
  .m_axis_data_tdata(fir_M_TDATA),
  .event_s_reload_tlast_missing(fir_reload_tlast_missing[r]),
  .event_s_reload_tlast_unexpected(fir_reload_tlast_unexpected[r]));
`endif
`endif

// FIR is configured to have output value contain some bits of fraction
// since this makes the output a multiple of 8 bits as required by AXI.
localparam FIR_FRACTION_WIDTH = 5;
localparam FIR_RAW_WIDTH = FIR_OUTPUT_WIDTH-FIR_FRACTION_WIDTH;
wire [FIR_RAW_WIDTH-1:0] rawFIR;
(*mark_debug=FIR_DBG*) wire  [RESULT_WIDTH-1:0] clippedFIR;
// First get rid of the unused least-significant (fraction) bits
assign rawFIR = fir_M_TDATA[FIR_OUTPUT_WIDTH-1:FIR_FRACTION_WIDTH];
// Then saturate out the most-significant bits
reduceWidth #(.IWIDTH(FIR_RAW_WIDTH),
              .OWIDTH(RESULT_WIDTH))
                reduceFIR (.I(rawFIR),
                           .O(clippedFIR));

// Deliver result
assign dout[RESULT_WIDTH*r+:RESULT_WIDTH] = clippedFIR;
always @(posedge clk) begin
    if ((r == 0) && fir_M_TVALID) begin
        doutToggle <= !doutToggle;
    end
end

end /* endfor */
endgenerate

// End of replicated code

endmodule
