/* Simulated version of fofbReadLinkxMux.v
 * First-word-fallthrough FIFO: data is available on M00_AXIS_TDATA/TVALID
 * whenever the FIFO is not empty, but the FIFO will not increment unless
 * M00_AXIS_TREADY is asserted
 */

module fofbReadLinksMux (
  input ACLK, // unused
  input ARESETN, // unused
  input S00_AXIS_ACLK,
  input S01_AXIS_ACLK,
  input S00_AXIS_ARESETN,
  input S01_AXIS_ARESETN,
  // Input Stream 00
  input S00_AXIS_TVALID,
  input [7:0] S00_AXIS_TDATA,
  input S00_AXIS_TUSER,
  // Input Stream 01
  input S01_AXIS_TVALID,
  input [7:0] S01_AXIS_TDATA,
  input S01_AXIS_TUSER,
  // Output Stream
  input M00_AXIS_ACLK,
  input M00_AXIS_ARESETN,
  output M00_AXIS_TVALID,
  input M00_AXIS_TREADY,
  output [7:0] M00_AXIS_TDATA,
  output M00_AXIS_TUSER,
  input S00_ARB_REQ_SUPPRESS,
  input S01_ARB_REQ_SUPPRESS
);

localparam DW = 9; // {TUSER, TDATA}
wire [DW-1:0] m00_tdata;
assign {M00_AXIS_TUSER, M00_AXIS_TDATA} = m00_tdata;

stream_mux #(
  .DW(DW),
  .PACKET_MODE(1'b0),
  .NAME("fofbReadLinksMux"),
  .TALK(1'b0)
) mux (
  .aclk(ACLK), // input
  .aresetn(ARESETN), // input
  .s00_aclk(S00_AXIS_ACLK), // input
  .s01_aclk(S01_AXIS_ACLK), // input
  .s00_aresetn(S00_AXIS_ARESETN), // input
  .s01_aresetn(S01_AXIS_ARESETN), // input
  .s00_tvalid(S00_AXIS_TVALID), // input
  .s00_tdata({S00_AXIS_TUSER, S00_AXIS_TDATA}), // input [DW-1:0]
  .s01_tvalid(S01_AXIS_TVALID), // input
  .s01_tdata({S01_AXIS_TUSER, S01_AXIS_TDATA}), // input [DW-1:0]
  .m00_aclk(M00_AXIS_ACLK), // input
  .m00_aresetn(M00_AXIS_ARESETN), // input
  .m00_tvalid(M00_AXIS_TVALID), // output
  .m00_tready(M00_AXIS_TREADY), // input
  .m00_tdata(m00_tdata), // output [31:0]
  .s00_arb_req_suppress(S00_ARB_REQ_SUPPRESS), // input
  .s01_arb_req_suppress(S01_ARB_REQ_SUPPRESS) // input
);

endmodule
