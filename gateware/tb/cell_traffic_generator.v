/* Cell Controller Interposer and Traffic Generator for testing/simulation
 * Generates a single packet locally in response to rising edge on 'FAstrobe'
 * which goes out on the CCW link if 'out_ccw' (otherwise the CW link)
 * After the first packet goes out, it becomes a transparent feedthrough
 * on both the CCW and CW links.
 */

module cell_traffic_generator #(
  parameter [4:0] CELL_INDEX = 0
) (
  input clk,  // Domain?
  input FAstrobe,
  input out_ccw, // 1 = output on CCW stream, 0 = output on CW stream
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

// When FAstrobe received,
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

reg [4:0] cell_index=CELL_INDEX;
localparam [8:0] fofb_index=0;

localparam [31:0] FAKE_CRC = 32'hADADFACE;

reg [PKTW-1:0] pkt_counter=0;
reg [31:0] pktram [0:PKT_SIZE_WORDS-1];
integer I;
initial begin
  for (I = 0; I < PKT_SIZE_WORDS; I = I + 1) pktram[I] = 32'h0;
  pktram[0] = {MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
  pktram[4] = FAKE_CRC;
end

reg running=1'b0;
reg phase=1'b0;

wire local_override = running;
reg out_ccw_r=1'b1;
wire en_ccw = out_ccw_r;
wire en_cw = ~out_ccw_r;

reg stop=1'b0;
reg [31:0] tdata=0;
reg tvalid=1'b0;
reg tlast=1'b0;

reg FAstrobe_r=1'b0;
wire FAstrobe_re = FAstrobe & ~FAstrobe_r;
always @(posedge clk) begin
  FAstrobe_r <= FAstrobe;
  if (!running) begin
    tvalid <= 1'b0;
    phase <= 1'b0;
    pkt_counter <= 0;
    tdata <= 0;
    stop <= 1'b0;
    // Prepare new packet
    pktram[0] <= {MAGIC, 1'b1, cell_index, 1'b0, fofb_index};
    if (FAstrobe_re) begin
      tdata <= pktram[0];
      out_ccw_r <= out_ccw;
      running <= 1'b1;
    end
  end else begin
    if (stop) begin
      stop <= 1'b0;
      running <= 1'b0;
    end
    phase <= ~phase;
    tlast <= 1'b0;
    tvalid <= 1'b0;
    if (phase) begin  // Assert data
      tdata <= pktram[pkt_counter];
      tvalid <= 1'b0;
    end else begin // ~phase. Assert TVALID and increment counter
      tvalid <= 1'b1;
      if (pkt_counter == PKT_SIZE_WORDS - 1) begin
        tlast <= 1'b1;
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

assign CELL_CCW_AXI_STREAM_TX_tdata_out  = local_override & en_ccw ? tdata  : CELL_CCW_AXI_STREAM_TX_tdata_in;
assign CELL_CCW_AXI_STREAM_TX_tlast_out  = local_override & en_ccw ? tlast  : CELL_CCW_AXI_STREAM_TX_tlast_in;
assign CELL_CCW_AXI_STREAM_TX_tvalid_out = local_override & en_ccw ? tvalid : CELL_CCW_AXI_STREAM_TX_tvalid_in;

assign CELL_CW_AXI_STREAM_TX_tdata_out   = local_override & en_cw ? tdata   : CELL_CW_AXI_STREAM_TX_tdata_in;
assign CELL_CW_AXI_STREAM_TX_tlast_out   = local_override & en_cw ? tlast   : CELL_CW_AXI_STREAM_TX_tlast_in;
assign CELL_CW_AXI_STREAM_TX_tvalid_out  = local_override & en_cw ? tvalid  : CELL_CW_AXI_STREAM_TX_tvalid_in;


endmodule
