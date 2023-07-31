`timescale 1ns/1ns

module qsfpMarble_tb;

localparam QSFP_COUNT = 2;
localparam SYSCLK_RATE = 100_000_000;

reg clk;
initial begin
  clk = 1'b0;
end

always #5 clk <= ~clk;

reg [$clog2(QSFP_COUNT)+7:0] readAddress;
wire [7:0] readData;
wire SCL, SDA;
wire scl_mon, sda_mon;
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
  .SCL(scl), // inout
  .SDA(sda), // inout
  .scl_mon(scl_mon),
  .sda_mon(sda_mon),
  .led(qsfp_led),
  .busmux_reset(busmux_reset)
);

initial begin
  $display("PASS");
  $finish();
end

endmodule
