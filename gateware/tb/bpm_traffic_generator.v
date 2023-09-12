/* BPM Traffic Generator for testing/simulation
 */

module bpm_traffic_generator #(
  parameter [4:0] CELL_INDEX = 0,
  parameter [8:0] FOFB_INDEX_INIT = 0,
  parameter [8:0] FOFB_INDEX_MAX = 7
) (
  input clk,  // Domain?
  input FAstrobe,
  input [1:0] mode, // 0 = alternate, 1 = CCW only, 2 = CW only, 3 = both
  // BPM CCW AXI Stream
  output [31:0] BPM_CCW_AXI_STREAM_RX_tdata,
  output BPM_CCW_AXI_STREAM_RX_tlast,
  output BPM_CCW_AXI_STREAM_RX_tvalid,
  // BPM CW AXI Stream
  output [31:0] BPM_CW_AXI_STREAM_RX_tdata,
  output BPM_CW_AXI_STREAM_RX_tlast,
  output BPM_CW_AXI_STREAM_RX_tvalid
);

localparam PKT_SIZE_WORDS = 5;
localparam PKTW = $clog2(PKT_SIZE_WORDS+1);
localparam [15:0] MAGIC = 16'hA5BE;

// When FAstrobe received,
//  Generate 1 fake packet for each BPM
//  Send each fake packet either A) over both links or B) alternating links

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

reg [4:0] cell_index=CELL_INDEX;
reg [8:0] fofb_index=FOFB_INDEX_INIT;

localparam [31:0] FAKE_CRC = 32'hADADFACE;

reg [PKTW-1:0] pkt_counter=0;
// Note pktram is 33-bit registers (MSb is TLAST)
reg [32:0] pktram [0:PKT_SIZE_WORDS-1];
integer I;
initial begin
  // MSb is TLAST
  for (I = 0; I < PKT_SIZE_WORDS; I = I + 1) pktram[I] = 33'h0;
  pktram[0] = {1'b0, MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
  // NOTE: brittle point - TLAST=1 needs to be placed at pktram[PKT_SIZE_WORDS-1][32]
  pktram[4] = {1'b1, FAKE_CRC};
end


reg running=1'b0;
// Use this to determine on which channel the data goes out
reg alternate=1'b1;
reg [1:0] ch_bitmap=2'b11;
// Bit positions
localparam CCW = 0;
localparam CW = 1;

reg [31:0] tdata_ccw=0, tdata_cw=0;
reg tvalid_ccw=1'b0, tvalid_cw=1'b0;
reg tlast_ccw=1'b0, tlast_cw=1'b0;

reg FAstrobe_r=1'b0;
wire FAstrobe_re = FAstrobe & ~FAstrobe_r;
always @(posedge clk) begin
  FAstrobe_r <= FAstrobe;
  if (!running) begin
    tvalid_ccw <= 1'b0;
    tvalid_cw <= 1'b0;
    pkt_counter <= 0;
    tdata_ccw <= 0;
    tdata_cw <= 0;
    if (FAstrobe_re) begin
      if (mode == 0) begin
        alternate <= 1'b1;
        ch_bitmap <= 2'b01;
      end else begin
        alternate <= 1'b0;
        ch_bitmap <= mode;
      end
      fofb_index <= FOFB_INDEX_INIT;
      running <= 1'b1;
      // Prepare new packet
      pktram[0] <= {MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
      fofb_index <= fofb_index + 1;
    end
  end else begin
    tlast_ccw <= 1'b0;
    tlast_cw <= 1'b0;
    tvalid_ccw <= 1'b0;
    tvalid_cw <= 1'b0;
    // Assert data, assert TVALID, and increment counter
    if (ch_bitmap[CCW]) begin
      {tlast_ccw, tdata_ccw} <= pktram[pkt_counter];
      tvalid_ccw <= 1'b1;
    end
    if (ch_bitmap[CW]) begin
      {tlast_cw, tdata_cw} <= pktram[pkt_counter];
      tvalid_cw <= 1'b1;
    end
    if (pkt_counter == PKT_SIZE_WORDS - 1) begin
      // Done with one packet
      if (fofb_index == FOFB_INDEX_MAX) begin
        running <= 1'b0;
      end else begin
        // Prepare new packet
        pktram[0] <= {1'b0, MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
        fofb_index <= fofb_index + 1;
        if (alternate) ch_bitmap <= {ch_bitmap[0], ch_bitmap[1]};
      end
      pkt_counter <= 0;
    end else begin
      // Increment
      pkt_counter <= pkt_counter + 1;
    end
  end
end

assign BPM_CCW_AXI_STREAM_RX_tdata = tdata_ccw;
assign BPM_CCW_AXI_STREAM_RX_tlast = tlast_ccw;
assign BPM_CCW_AXI_STREAM_RX_tvalid = tvalid_ccw;

assign BPM_CW_AXI_STREAM_RX_tdata = tdata_cw;
assign BPM_CW_AXI_STREAM_RX_tlast = tlast_cw;
assign BPM_CW_AXI_STREAM_RX_tvalid = tvalid_cw;

endmodule
