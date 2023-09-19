/* Cell Controller AXI Stream loopback for simulation
 */

module axi_stream_loopback (
  input close_loop_ccw,
  input close_loop_cw,
  // CELL CCW AXI Stream TX (input)
  input [31:0] CELL_CCW_AXI_STREAM_TX_tdata,
  input CELL_CCW_AXI_STREAM_TX_tlast,
  input CELL_CCW_AXI_STREAM_TX_tvalid,
  // CELL CCW AXI Stream RX (output)
  output [31:0] CELL_CCW_AXI_STREAM_RX_tdata,
  output CELL_CCW_AXI_STREAM_RX_tlast,
  output CELL_CCW_AXI_STREAM_RX_tvalid,
  // CELL CW AXI Stream TX (input)
  input [31:0] CELL_CW_AXI_STREAM_TX_tdata,
  input CELL_CW_AXI_STREAM_TX_tlast,
  input CELL_CW_AXI_STREAM_TX_tvalid,
  // CELL CW AXI Stream RX (output)
  output [31:0] CELL_CW_AXI_STREAM_RX_tdata,
  output CELL_CW_AXI_STREAM_RX_tlast,
  output CELL_CW_AXI_STREAM_RX_tvalid
);

assign CELL_CCW_AXI_STREAM_RX_tdata = close_loop_ccw ? CELL_CCW_AXI_STREAM_TX_tdata : 0;
assign CELL_CCW_AXI_STREAM_RX_tlast = close_loop_ccw ? CELL_CCW_AXI_STREAM_TX_tlast : 0;
assign CELL_CCW_AXI_STREAM_RX_tvalid = close_loop_ccw ? CELL_CCW_AXI_STREAM_TX_tvalid : 0;

assign CELL_CW_AXI_STREAM_RX_tdata = close_loop_cw ? CELL_CW_AXI_STREAM_TX_tdata : 0;
assign CELL_CW_AXI_STREAM_RX_tlast = close_loop_cw ? CELL_CW_AXI_STREAM_TX_tlast : 0;
assign CELL_CW_AXI_STREAM_RX_tvalid = close_loop_cw ? CELL_CW_AXI_STREAM_TX_tvalid : 0;

endmodule
