// Convert error values from 32 bit fixed point (nm)
// to IEEE-754 double precision (mm).

module errorConvert (
    input              clk,

    input  wire        writeStrobe,
    input  wire        csrStrobe,
    input  wire [31:0] writeData,

    output wire [31:0] status,
    output wire [31:0] resultHi,
    output wire [31:0] resultLo);

wire [31:0] floatValue, productValue;
wire        floatValid, productValid;
wire [63:0] doubleValue, fifoIn;
wire        doubleValid;
wire        empty;
reg         swap = 0;
always @(posedge clk) begin
    if (csrStrobe) swap <= writeData[4];
end
assign status = { 24'h0, empty, 2'h0, swap, 4'h0 };

`ifndef SIMULATE
fixToFloat errorFixToFloat (
  .aclk(clk),                        // input wire aclk
  .s_axis_a_tvalid(writeStrobe),     // input wire s_axis_a_tvalid
  .s_axis_a_tdata(writeData),        // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(floatValid), // output wire m_axis_result_tvalid
  .m_axis_result_tdata(floatValue)); // output wire [31 : 0] m_axis_result_tdata

floatMultiply errorFloatMultiply (
  .aclk(clk),                          // input wire aclk
  .s_axis_a_tvalid(floatValid),        // input wire s_axis_a_tvalid
  .s_axis_a_tdata(floatValue),         // input wire [31 : 0] s_axis_a_tdata
  .s_axis_b_tvalid(1'b1),              // input wire s_axis_b_tvalid
  .s_axis_b_tdata(32'h358637BD),       // input wire [31 : 0] s_axis_b_tdata(1.0e-6)
  .m_axis_result_tvalid(productValid), // output wire m_axis_result_tvalid
  .m_axis_result_tdata(productValue)); // output wire [31 : 0] m_axis_result_tdata

floatToDouble errorFloatToDouble (
  .aclk(clk),                         // input wire aclk
  .s_axis_a_tvalid(productValid),     // input wire s_axis_a_tvalid
  .s_axis_a_tdata(productValue),      // input wire [31 : 0] s_axis_a_tdata
  .m_axis_result_tvalid(doubleValid), // output wire m_axis_result_tvalid
  .m_axis_result_tdata(doubleValue)); // output wire [63 : 0] m_axis_result_tdata
`endif

assign fifoIn = swap ? { doubleValue[7:0],   doubleValue[15:8],
                         doubleValue[23:16], doubleValue[31:24],
                         doubleValue[39:32], doubleValue[47:40],
                         doubleValue[55:48], doubleValue[63:56] } : doubleValue;
`ifndef SIMULATE
floatResultFIFO errorResultFIFO (
  .clk(clk),                        // input wire clk
  .srst(csrStrobe & writeData[1]),  // input wire srst
  .din(fifoIn),                     // input wire [63 : 0] din
  .wr_en(doubleValid),              // input wire wr_en
  .rd_en(csrStrobe & writeData[0]), // input wire rd_en
  .dout({resultHi, resultLo}),      // output wire [63 : 0] dout
  .full(),                          // output wire full
  .empty(empty));                   // output wire empty
`endif

endmodule
