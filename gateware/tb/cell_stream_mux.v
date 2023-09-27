/*
*/

module cell_stream_mux (
  input clk,

  // Stream packet MUX input
  input         stream_mux_strobe,
  input   [1:0] stream_mux_sel,
  input  [31:0] stream_in_header,
  input  [31:0] stream_in_datax,
  input  [31:0] stream_in_datay,
  input  [31:0] stream_in_datas,

  // Stream packet MUX output
  output        stream_mux_valid,
  output  [1:0] stream_mux_src,
  output [31:0] stream_out_header,
  output [31:0] stream_out_datax,
  output [31:0] stream_out_datay,
  output [31:0] stream_out_datas,

  // Cell CCW Stream OUT
  input  [31:0] CELL_CCW_AXI_STREAM_TX_tdata,
  input         CELL_CCW_AXI_STREAM_TX_tlast,
  input         CELL_CCW_AXI_STREAM_TX_tvalid,

  // Cell CCW Stream IN
  output [31:0] CELL_CCW_AXI_STREAM_RX_tdata,
  output        CELL_CCW_AXI_STREAM_RX_tlast,
  output        CELL_CCW_AXI_STREAM_RX_tvalid,

  // Cell CW Stream OUT
  input  [31:0] CELL_CW_AXI_STREAM_TX_tdata,
  input         CELL_CW_AXI_STREAM_TX_tlast,
  input         CELL_CW_AXI_STREAM_TX_tvalid,

  // Cell CW Stream IN
  output [31:0] CELL_CW_AXI_STREAM_RX_tdata,
  output        CELL_CW_AXI_STREAM_RX_tlast,
  output        CELL_CW_AXI_STREAM_RX_tvalid,

  // BPM CCW Stream IN
  output        BPM_CCW_AXI_STREAM_RX_tlast,
  output        BPM_CCW_AXI_STREAM_RX_tvalid,
  output [31:0] BPM_CCW_AXI_STREAM_RX_tdata,

  // BPM CW Stream IN
  output        BPM_CW_AXI_STREAM_RX_tlast,
  output        BPM_CW_AXI_STREAM_RX_tvalid,
  output [31:0] BPM_CW_AXI_STREAM_RX_tdata
);

localparam [1:0] NSTREAM_CELL_CCW = 0;
localparam [1:0] NSTREAM_CELL_CW  = 1;
localparam [1:0] NSTREAM_BPM_CCW  = 2;
localparam [1:0] NSTREAM_BPM_CW   = 3;

// DEBUG
always @(posedge clk) begin
  if (stream_mux_strobe) $display("stream_mux_strobe: %d", stream_mux_sel);
end

reg valid=1'b0;
// Allow one outgoing packet to pend
reg [1:0] src=0, src_pend=0;
reg [31:0] header=0, header_pend=0;
reg [31:0] datax=0, datax_pend=0;
reg [31:0] datay=0, datay_pend=0;
reg [31:0] datas=0, datas_pend=0;
reg pend_sel=1'b0;
reg pended=1'b0;
assign stream_mux_valid = valid;
assign stream_mux_src = pend_sel ? src_pend : src;
assign stream_out_header = pend_sel ? header_pend : header;
assign stream_out_datax = pend_sel ? datax_pend : datax;
assign stream_out_datay = pend_sel ? datay_pend : datay;
assign stream_out_datas = pend_sel ? datas_pend : datas;

//cell_ccw_valid
wire cell_ccw_valid;
wire [31:0] cell_ccw_header, cell_ccw_datax, cell_ccw_datay, cell_ccw_datas;
wire cell_cw_valid;
wire [31:0] cell_cw_header, cell_cw_datax, cell_cw_datay, cell_cw_datas;

always @(posedge clk) begin
  valid <= 1'b0; // Strobe
  if (pended) begin
    src <= src_pend;
    header <= header_pend;
    datax <= datax_pend;
    datay <= datay_pend;
    datas <= datas_pend;
    pended <= 1'b0;
    valid <= 1'b1;
  end
  if (cell_ccw_valid) begin
    if (valid) begin // parallel output is occupied; pend
      src_pend <= NSTREAM_CELL_CCW;
      header_pend <= cell_ccw_header;
      datax_pend <= cell_ccw_datax;
      datay_pend <= cell_ccw_datay;
      datas_pend <= cell_ccw_datas;
      pended <= 1'b1;
    end else begin  // parallel output is free
      src <= NSTREAM_CELL_CCW;
      header <= cell_ccw_header;
      datax <= cell_ccw_datax;
      datay <= cell_ccw_datay;
      datas <= cell_ccw_datas;
      valid <= 1'b1;
    end
    // Catch case of cell_ccw and cell_cw asserted simultaneously
    // Pend cw in this case (ccw gets priority).
    if (cell_cw_valid) begin
      src_pend <= NSTREAM_CELL_CW;
      header_pend <= cell_cw_header;
      datax_pend <= cell_cw_datax;
      datay_pend <= cell_cw_datay;
      datas_pend <= cell_cw_datas;
      pended <= 1'b1;
    end
  end else if (cell_cw_valid) begin
    if (valid) begin // parallel output is occupied; pend
      src_pend <= NSTREAM_CELL_CW;
      header_pend <= cell_cw_header;
      datax_pend <= cell_cw_datax;
      datay_pend <= cell_cw_datay;
      datas_pend <= cell_cw_datas;
      pended <= 1'b1;
    end else begin  // parallel output is free
      src <= NSTREAM_CELL_CW;
      header <= cell_cw_header;
      datax <= cell_cw_datax;
      datay <= cell_cw_datay;
      datas <= cell_cw_datas;
      valid <= 1'b1;
    end
  end
end

wire cell_ccw_strobe = stream_mux_strobe & (stream_mux_sel == NSTREAM_CELL_CCW);
wire cell_cw_strobe  = stream_mux_strobe & (stream_mux_sel == NSTREAM_CELL_CW);
wire bpm_ccw_strobe  = stream_mux_strobe & (stream_mux_sel == NSTREAM_BPM_CCW);
wire bpm_cw_strobe   = stream_mux_strobe & (stream_mux_sel == NSTREAM_BPM_CW);

cell_stream_ibuf #(.NAME("Cell CCW")) cell_ccw_ibuf (
  .clk(clk), // input
  .stream_mux_strobe(cell_ccw_strobe), // input
  .stream_in_header(stream_in_header), // input [31:0]
  .stream_in_datax(stream_in_datax), // input [31:0]
  .stream_in_datay(stream_in_datay), // input [31:0]
  .stream_in_datas(stream_in_datas), // input [31:0]
  .tvalid(CELL_CCW_AXI_STREAM_RX_tvalid), // output
  .tlast(CELL_CCW_AXI_STREAM_RX_tlast), // output
  .tdata(CELL_CCW_AXI_STREAM_RX_tdata) // output [31:0]
);

cell_stream_obuf #(.NAME("Cell CCW")) cell_ccw_obuf (
  .clk(clk), // input
  .stream_mux_valid(cell_ccw_valid), // output
  .stream_out_header(cell_ccw_header), // output [31:0]
  .stream_out_datax(cell_ccw_datax), // output [31:0]
  .stream_out_datay(cell_ccw_datay), // output [31:0]
  .stream_out_datas(cell_ccw_datas), // output [31:0]
  .tvalid(CELL_CCW_AXI_STREAM_TX_tvalid), // input
  .tlast(CELL_CCW_AXI_STREAM_TX_tlast), // input
  .tdata(CELL_CCW_AXI_STREAM_TX_tdata) // input [31:0]
);

cell_stream_ibuf #(.NAME("Cell CW")) cell_cw_ibuf (
  .clk(clk), // input
  .stream_mux_strobe(cell_cw_strobe), // input
  .stream_in_header(stream_in_header), // input [31:0]
  .stream_in_datax(stream_in_datax), // input [31:0]
  .stream_in_datay(stream_in_datay), // input [31:0]
  .stream_in_datas(stream_in_datas), // input [31:0]
  .tvalid(CELL_CW_AXI_STREAM_RX_tvalid), // output
  .tlast(CELL_CW_AXI_STREAM_RX_tlast), // output
  .tdata(CELL_CW_AXI_STREAM_RX_tdata) // output [31:0]
);

cell_stream_obuf #(.NAME("Cell CW")) cell_cw_obuf (
  .clk(clk), // input
  .stream_mux_valid(cell_cw_valid), // output
  .stream_out_header(cell_cw_header), // output [31:0]
  .stream_out_datax(cell_cw_datax), // output [31:0]
  .stream_out_datay(cell_cw_datay), // output [31:0]
  .stream_out_datas(cell_cw_datas), // output [31:0]
  .tvalid(CELL_CW_AXI_STREAM_TX_tvalid), // input
  .tlast(CELL_CW_AXI_STREAM_TX_tlast), // input
  .tdata(CELL_CW_AXI_STREAM_TX_tdata) // input [31:0]
);

cell_stream_ibuf #(.NAME("BPM CCW")) bpm_ccw_ibuf (
  .clk(clk), // input
  .stream_mux_strobe(bpm_ccw_strobe), // input
  .stream_in_header(stream_in_header), // input [31:0]
  .stream_in_datax(stream_in_datax), // input [31:0]
  .stream_in_datay(stream_in_datay), // input [31:0]
  .stream_in_datas(stream_in_datas), // input [31:0]
  .tvalid(BPM_CCW_AXI_STREAM_RX_tvalid), // output
  .tlast(BPM_CCW_AXI_STREAM_RX_tlast), // output
  .tdata(BPM_CCW_AXI_STREAM_RX_tdata) // output [31:0]
);

cell_stream_ibuf #(.NAME("BPM CW")) bpm_cw_ibuf (
  .clk(clk), // input
  .stream_mux_strobe(bpm_cw_strobe), // input
  .stream_in_header(stream_in_header), // input [31:0]
  .stream_in_datax(stream_in_datax), // input [31:0]
  .stream_in_datay(stream_in_datay), // input [31:0]
  .stream_in_datas(stream_in_datas), // input [31:0]
  .tvalid(BPM_CW_AXI_STREAM_RX_tvalid), // output
  .tlast(BPM_CW_AXI_STREAM_RX_tlast), // output
  .tdata(BPM_CW_AXI_STREAM_RX_tdata) // output [31:0]
);

endmodule
