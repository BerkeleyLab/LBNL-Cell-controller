/* Cell Controller AXI Stream loopback for simulation
 */

module axi_stream_loopback (
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

assign CELL_CCW_AXI_STREAM_RX_tdata = CELL_CCW_AXI_STREAM_TX_tdata;
assign CELL_CCW_AXI_STREAM_RX_tlast = CELL_CCW_AXI_STREAM_TX_tlast;
assign CELL_CCW_AXI_STREAM_RX_tvalid = CELL_CCW_AXI_STREAM_TX_tvalid;

assign CELL_CW_AXI_STREAM_RX_tdata = CELL_CW_AXI_STREAM_TX_tdata;
assign CELL_CW_AXI_STREAM_RX_tlast = CELL_CW_AXI_STREAM_TX_tlast;
assign CELL_CW_AXI_STREAM_RX_tvalid = CELL_CW_AXI_STREAM_TX_tvalid;

endmodule
