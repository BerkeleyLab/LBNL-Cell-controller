/* Cell Controller Interposer and Traffic Generator for testing/simulation
 * Generates a single packet locally in response to rising edge on 'start'
 * which goes out on the CCW link if 'out_ccw' (otherwise the CW link)
 * After the first packet goes out, it becomes a transparent feedthrough
 * on both the CCW and CW links.
 */

module cell_traffic_generator #(
  parameter [0:0] CELL_INDEX_AUTOINCREMENT = 1'b1
) (
  input clk,  // Domain?
  input start,
  input out_ccw, // 1 = output on CCW stream, 0 = output on CW stream
  input [4:0] cell_index,
  // CELL CCW AXI Stream TX (input)
  input [31:0] CELL_CCW_AXI_STREAM_TX_tdata_in,
  input CELL_CCW_AXI_STREAM_TX_tlast_in,
  input CELL_CCW_AXI_STREAM_TX_tvalid_in,
  // CELL CCW AXI Stream TX (output)
  output [31:0] CELL_CCW_AXI_STREAM_TX_tdata_out,
  output CELL_CCW_AXI_STREAM_TX_tlast_out,
  output CELL_CCW_AXI_STREAM_TX_tvalid_out,
  // CELL CW AXI Stream TX (input)
  input [31:0] CELL_CW_AXI_STREAM_TX_tdata_in,
  input CELL_CW_AXI_STREAM_TX_tlast_in,
  input CELL_CW_AXI_STREAM_TX_tvalid_in,
  // CELL CW AXI Stream TX (output)
  output [31:0] CELL_CW_AXI_STREAM_TX_tdata_out,
  output CELL_CW_AXI_STREAM_TX_tlast_out,
  output CELL_CW_AXI_STREAM_TX_tvalid_out
);

localparam PKT_SIZE_WORDS = 5;
localparam PKTW = $clog2(PKT_SIZE_WORDS+1);
localparam [15:0] MAGIC = 16'hA5BE;

// When start received,
//   If BPM Traffic generator not present/enabled:
//     Enable self-increment of packet "Cell Index"
//     Generate one fake packet with "Cell Index" = 0 (this will self-increment when received on the loopback)

/*
Aurora packets:
  | Header (4B) | Data X (4B) | Data Y (4B) | Data S (4B) | CRC (4B) |

           31                16          15         14             10     9      8               0
  Header: | Magic 0xA5BE (16b) | FOFB Enabled (1b) | Cell Index (5b) | pad (1b) | FOFB Index (9b) |
  Data X: | -------------------------- Beam Position along X axis in nm ------------------------- |
  Data Y: | -------------------------- Beam Position along Y axis in nm ------------------------- |
  Data S: | CRC Fault (1b) | ADC Clipping (1b) | --------------- Sum Value (30b) ---------------- |
  CRC:    | ---------------------------------- Aurora CRC Word ---------------------------------- |
*/

//reg [4:0] cell_index=CELL_INDEX;
localparam [8:0] fofb_index=0;

localparam [31:0] FAKE_CRC = 32'hADADFACE;

reg [PKTW-1:0] pkt_counter=0;
// Note pktram is 33-bit registers (MSb is TLAST)
reg [32:0] pktram [0:PKT_SIZE_WORDS-1];
integer I;
initial begin
  // MSb is TLAST
  for (I = 0; I < PKT_SIZE_WORDS; I = I + 1) pktram[I] = 33'h0;
  pktram[0] = {1'b0, MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
  // Dummy data
  pktram[1] = {1'b0, 32'h000000ff};
  pktram[2] = {1'b0, 32'h0000ff00};
  pktram[3] = {1'b0, 32'h00ff0000};
  // NOTE: brittle point - TLAST=1 needs to be placed at pktram[PKT_SIZE_WORDS-1][32]
  pktram[4] = {1'b1, FAKE_CRC};
end

reg running=1'b0;

wire local_override = running;
reg out_ccw_r=1'b1;
wire en_ccw = out_ccw_r;
wire en_cw = ~out_ccw_r;

reg stop=1'b0;
reg [31:0] tdata=0;
reg tvalid=1'b0;
reg tlast=1'b0;

reg start_r=1'b0;
wire start_re = start & ~start_r;
always @(posedge clk) begin
  start_r <= start;
  tlast <= 1'b0;
  if (!running) begin
    tvalid <= 1'b0;
    pkt_counter <= 0;
    tdata <= 0;
    stop <= 1'b0;
    // Prepare new packet
    pktram[0] <= {1'b0, MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
    if (start_re) begin
      //{tlast, tdata} <= pktram[0];
      out_ccw_r <= out_ccw;
      running <= 1'b1;
    end
  end else begin
    if (stop) begin
      stop <= 1'b0;
      running <= 1'b0;
    end else begin
      tvalid <= 1'b1;
      // Assert data, assert TVALID, and increment counter
      {tlast, tdata} <= pktram[pkt_counter];
      if (pkt_counter == PKT_SIZE_WORDS - 1) begin
        stop <= 1'b1;
        pkt_counter <= 0;
      end else begin
        // Increment
        pkt_counter <= pkt_counter + 1;
      end
    end
  end
end

wire tready = 1'b1;

// Automatic cell index incrementing
reg [3:0] ccw_pkt_cntr=0;
wire [4:0] ccw_cell_inc;
wire ccw_cell_wrap;
assign {ccw_cell_wrap, ccw_cell_inc} = CELL_CCW_AXI_STREAM_TX_tdata_in[14:10] + 6'h1;
// Increment cell_index on header (word 0)
wire [31:0] ext_ccw_tdata_cell_inc = (CELL_INDEX_AUTOINCREMENT) && (ccw_pkt_cntr == 0) ?
  {CELL_CCW_AXI_STREAM_TX_tdata_in[31:15], ccw_cell_inc, CELL_CCW_AXI_STREAM_TX_tdata_in[9:0]} :
  CELL_CCW_AXI_STREAM_TX_tdata_in;
wire ccw_tlast = local_override & en_ccw ? tlast   : CELL_CCW_AXI_STREAM_TX_tlast_in;
wire ccw_tvalid = local_override & en_ccw ? tvalid : CELL_CCW_AXI_STREAM_TX_tvalid_in;

assign CELL_CCW_AXI_STREAM_TX_tdata_out  = local_override & en_ccw ? tdata  : ext_ccw_tdata_cell_inc;
assign CELL_CCW_AXI_STREAM_TX_tlast_out  = ccw_tlast;
assign CELL_CCW_AXI_STREAM_TX_tvalid_out = ccw_tvalid;

// Automatic cell index incrementing
reg [3:0] cw_pkt_cntr=0;
wire [4:0] cw_cell_inc;
wire cw_cell_wrap;
assign {cw_cell_wrap, cw_cell_inc} = CELL_CW_AXI_STREAM_TX_tdata_in[14:10] + 6'h1;
// Increment cell_index on header (word 0)
wire [31:0] ext_cw_tdata_cell_inc = (CELL_INDEX_AUTOINCREMENT) && (cw_pkt_cntr == 0) ?
  {CELL_CW_AXI_STREAM_TX_tdata_in[31:15], cw_cell_inc, CELL_CW_AXI_STREAM_TX_tdata_in[9:0]} :
  CELL_CW_AXI_STREAM_TX_tdata_in;
wire cw_tlast = local_override & en_cw ? tlast   : CELL_CW_AXI_STREAM_TX_tlast_in;
wire cw_tvalid = local_override & en_cw ? tvalid  : CELL_CW_AXI_STREAM_TX_tvalid_in;

assign CELL_CW_AXI_STREAM_TX_tdata_out   = local_override & en_cw ? tdata   : ext_cw_tdata_cell_inc;
assign CELL_CW_AXI_STREAM_TX_tlast_out   = cw_tlast;
assign CELL_CW_AXI_STREAM_TX_tvalid_out  = cw_tvalid;

always @(posedge clk) begin
  if (CELL_CW_AXI_STREAM_TX_tvalid_in) begin
    if (cw_tlast) cw_pkt_cntr <= 0;
    else cw_pkt_cntr <= cw_pkt_cntr + 1;
  end else cw_pkt_cntr <= 0;
  if (CELL_CCW_AXI_STREAM_TX_tvalid_in) begin
    if (ccw_tlast) ccw_pkt_cntr <= 0;
    else ccw_pkt_cntr <= ccw_pkt_cntr + 1;
  end else ccw_pkt_cntr <= 0;
end

endmodule
