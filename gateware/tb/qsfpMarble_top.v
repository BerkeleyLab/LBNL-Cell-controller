`timescale 1ns/1ns
/* Top level module for Verilating for qsfpMarble simulation
 */

module qsfpMarble_top (
  input   clk,
  output  [31:0] GPIO_IN,
  input   [31:0] GPIO_OUT,
  input   GPIO_STROBE
);

reg buffer_freeze;
initial begin
  buffer_freeze = 1'b0;
end

localparam QSFP_COUNT = 2;
localparam SYSCLK_RATE = 100_000_000;

reg [$clog2(QSFP_COUNT)+7:0] readAddress;
wire [7:0] readData;
wire SCL, SDA;
wire scl_mon, sda_mon;

reg i2c_updated, i2c_run_stat;
initial begin
  i2c_updated = 1'b0;
  i2c_run_stat = 1'b0;
end

assign GPIO_IN = {{22{1'b0}}, i2c_updated, i2c_run_stat, readData};
always @(posedge clk) begin
    if (GPIO_STROBE) begin
        //$display("STROBE: readAddress <= 0x%h", GPIO_OUT[$clog2(QSFP_COUNT)+7:0]);
        readAddress <= GPIO_OUT[$clog2(QSFP_COUNT)+7:0];
        buffer_freeze <= GPIO_OUT[16];
    end
end

wire scl, sda;

qsfpMarble #(
  .QSFP_COUNT(QSFP_COUNT),
  .CLOCK_RATE(SYSCLK_RATE),
  .BIT_RATE(100000)
  ) qsfpMarble_i (
  .clk(clk), // input
  .readAddress(readAddress), // input [$clog2(QSFP_COUNT)+7:0]
  .readData(readData), // output [7:0]
  .freeze(1'b0), // input
  .run_stat(), // output
  .updated(), // output
  .SCL(scl),
  .SDA(sda),
  .scl_mon(),
  .sda_mon(),
  .led(),
  .busmux_reset()
);

endmodule
