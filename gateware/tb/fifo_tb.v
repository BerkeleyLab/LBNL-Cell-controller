`timescale 1ns/1ns

module fifo_tb;

reg clk=1'b0;
always #5 clk <= ~clk;

// VCD dump file for gtkwave
reg [32*8-1:0] dumpfile; // 32-chars max
initial begin
  if (! $value$plusargs("df=%s", dumpfile)) begin
    $display("No dumpfile name supplied; Wave data will not be saved.");
  end else begin
    $dumpfile(dumpfile);
    $dumpvars;
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] timeout=0;
always @(posedge clk) begin
  if (timeout > 0) timeout <= timeout - 1;
end
wire to = ~(|timeout);

reg [31:0] counter=0;
always @(posedge clk) counter <= counter + 1;

reg [31:0] n00_valid=0;
reg [31:0] n01_valid=0;
always @(posedge clk) begin
  if (n00_valid > 0) n00_valid <= n00_valid-1;
  if (n01_valid > 0) n01_valid <= n01_valid-1;
end
wire S00_AXIS_TVALID=(n00_valid > 0);
wire [31:0] S00_AXIS_TDATA=counter;
wire S00_AXIS_TLAST=(n00_valid == 1);
wire S01_AXIS_TVALID=(n01_valid > 0);
wire [31:0] S01_AXIS_TDATA=counter;
wire S01_AXIS_TLAST=(n01_valid == 1);
wire M00_AXIS_TVALID;
wire [31:0] M00_AXIS_TDATA;
wire M00_AXIS_TLAST;
forwardCellLinkMux dut (
  .ACLK(clk), // input
  .ARESETN(1'b1), // input
  .S00_AXIS_ACLK(clk), // input
  .S01_AXIS_ACLK(clk), // input
  .S00_AXIS_ARESETN(1'b1), // input
  .S01_AXIS_ARESETN(1'b1), // input
  .S00_AXIS_TVALID(S00_AXIS_TVALID), // input
  .S00_AXIS_TDATA(S00_AXIS_TDATA), // input [31:0]
  .S00_AXIS_TLAST(S00_AXIS_TLAST), // input
  .S01_AXIS_TVALID(S01_AXIS_TVALID), // input
  .S01_AXIS_TDATA(S01_AXIS_TDATA), // input [31:0]
  .S01_AXIS_TLAST(S01_AXIS_TLAST), // input
  .M00_AXIS_ACLK(clk), // input
  .M00_AXIS_ARESETN(1'b1), // input
  .M00_AXIS_TVALID(M00_AXIS_TVALID), // output
  .M00_AXIS_TREADY(1'b1), // input
  .M00_AXIS_TDATA(M00_AXIS_TDATA), // output [31:0]
  .M00_AXIS_TLAST(M00_AXIS_TLAST), // output
  .S00_ARB_REQ_SUPPRESS(1'b0), // input
  .S01_ARB_REQ_SUPPRESS(1'b0) // input
);

// =========== Stimulus =============
initial begin
          // Start with 16 words on S00
          n00_valid = 16;
          timeout = TOSET;
  #20     wait (dut.mux.empty00 | to);
          // Then 8 words on S01
          n01_valid = 8;
          timeout = TOSET;
  #20     wait (dut.mux.empty01 | to);
          // Then 70 words on both S00 and S01 (can we get it to drop?)
          n00_valid = 70;
          n01_valid = 70;
          timeout = TOSET;
  #20     wait ((dut.mux.empty00 & dut.mux.empty01) | to);
  #100    $display("Done");
          $finish(0);
end

endmodule
