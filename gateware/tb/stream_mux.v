/* Stream multiplexer
 * First-word-fallthrough FIFO: data is available on M00_TDATA/TVALID
 * whenever the FIFO is not empty, but the FIFO will not increment unless
 * M00_TREADY is asserted
 *
 * TODO: In packet mode, we don't want to break up packets (only toggle on
 *       TLAST), but if the packet has gaps the FIFO may empty and we might
 *       want to block in some cases.  We can't indefinitely block, because
 *       we want to ensure we select the opposite FIFO if one is empty for
 *       a "long time".
 */

module stream_mux #(
  // DW = Width of tdata ports
  parameter DW = 32,
  // PACKET_MODE==1: Toggles FIFO on TLAST (with configurable timeout)
  // PACKET_MODE==0: Toggles FIFO on empty
  parameter [0:0] PACKET_MODE=1'b1,
  // In PACKET_MODE, TLAST_BIT is the bit to trigger a FIFO toggle
  parameter TLAST_BIT=DW-1,
  // In PACKET_MODE, wait for IDLE_CYCLE_TIMEOUT cycles of empty FIFO before arbitrating
  parameter IDLE_CYCLE_TIMEOUT=10,
  // Use NAME to self-identify in $display statements
  parameter NAME="",
  // Set TALK to 1'b1 to enable $display chatter
  parameter [0:0] TALK=1
) (
  input aclk, // unused
  input aresetn, // unused
  input s00_aclk,
  input s01_aclk,
  input s00_aresetn,
  input s01_aresetn,
  // Input Stream 00
  input s00_tvalid,
  input [DW-1:0] s00_tdata,
  // Input Stream 01
  input s01_tvalid,
  input [DW-1:0] s01_tdata,
  // Output Stream
  input m00_aclk,
  input m00_aresetn,
  output m00_tvalid,
  input m00_tready,
  output [DW-1:0] m00_tdata,
  input s00_arb_req_suppress,
  input s01_arb_req_suppress
);

localparam RAM_WIDTH = DW; // {TLAST, TDATA}
/* FIFO-buffer both S00 and S01 inputs and forward to M00 output
*/

// Two FIFOs
localparam FIFO_DEPTH = 256; // Must be power of 2 for below full/empty scheme to work
localparam FIFO_CW = $clog2(FIFO_DEPTH);
// FIFO_00
reg [RAM_WIDTH-1:0] ram00 [0:FIFO_DEPTH-1];
reg [FIFO_CW:0] ipf00=0, opf00=0; // One extra bit for full calculation
wire [FIFO_CW-1:0] ip00=ipf00[FIFO_CW-1:0]; // Input pointer
wire [FIFO_CW-1:0] op00=opf00[FIFO_CW-1:0]; // Output pointer
wire full00=(ip00 == op00) && (ipf00[FIFO_CW] != opf00[FIFO_CW]);
wire empty00=(ipf00 == opf00);
reg [31:0] dropped00=0;
// FIFO_01
reg [RAM_WIDTH-1:0] ram01 [0:FIFO_DEPTH-1];
reg [FIFO_CW:0] ipf01=0, opf01=0; // One extra bit for full calculation
wire [FIFO_CW-1:0] ip01=ipf01[FIFO_CW-1:0]; // Input pointer
wire [FIFO_CW-1:0] op01=opf01[FIFO_CW-1:0]; // Output pointer
wire full01=(ip01 == op01) && (ipf01[FIFO_CW] != opf01[FIFO_CW]);
wire empty01=(ipf01 == opf01);
reg [31:0] dropped01=0;
integer I;
initial begin
  for (I = 0; I < FIFO_DEPTH-1; I = I + 1) begin
    ram00[I] = 0;
    ram01[I] = 0;
  end
end

// Switch at packet boundaries if using PACKET_MODE and if nonselected
// FIFO has contents (not empty)
wire pktsw00 = PACKET_MODE & ram00[op00][TLAST_BIT] & ~empty01;
wire pktsw01 = PACKET_MODE & ram01[op01][TLAST_BIT] & ~empty00;

// Debug
wire tlast_in_00 = PACKET_MODE & s00_tdata[TLAST_BIT];
reg [FIFO_CW-1:0] last_tlast00=0;
always @(posedge s00_aclk) begin
  if (tlast_in_00) begin
    if (last_tlast00 != ip00) begin
      //$display("%s 00 Storing TLAST=1 at %d", NAME, ip00);
      last_tlast00 <= ip00;
    end
  end
end
wire tlast_in_01 = PACKET_MODE & s01_tdata[TLAST_BIT];
reg [FIFO_CW-1:0] last_tlast01=0;
always @(posedge s01_aclk) begin
  if (tlast_in_01) begin
    if (last_tlast01 != ip01) begin
      //$display("%s 01 Storing TLAST=1 at %d", NAME, ip01);
      last_tlast01 <= ip01;
    end
  end
end

// FIFO_00 Input
always @(posedge s00_aclk) begin
  if (~s00_aresetn) begin
    ipf00 <= 0;
    dropped00 <= 0;
  end else begin
    if (s00_tvalid) begin
      if (!full00) begin
        //if (TALK) $display("%s 00 Storing 0x%x to %d", NAME, s00_tdata, ip00);
        ram00[ip00] <= s00_tdata;
        ipf00 <= ipf00 + 1; // Intentional rollover
      end else begin // full00
        if (TALK) $display("%s 00 dropped 0x%x", NAME, s00_tdata);
        dropped00 <= dropped00 + 1;
      end
    end
  end
end

// FIFO_01 Input
always @(posedge s01_aclk) begin
  if (~s01_aresetn) begin
    ipf01 <= 0;
    dropped01 <= 0;
  end else begin
    if (s01_tvalid) begin
      if (!full01) begin
        //if (TALK) $display("%s 01 Storing 0x%x to %d", NAME, s01_tdata, ip01);
        ram01[ip01] <= s01_tdata;
        ipf01 <= ipf01 + 1; // Intentional rollover
      end else begin // full01
        if (TALK) $display("%s 01 dropped 0x%x", NAME, s01_tdata);
        dropped01 <= dropped01 + 1;
      end
    end
  end
end

wire [DW-1:0] f00_tdata;
assign f00_tdata = ram00[op00];
wire f00_tvalid = ~empty00;

wire [DW-1:0] f01_tdata;
assign f01_tdata = ram01[op01];
wire f01_tvalid = ~empty01;

reg sel=1'b0;
assign m00_tdata = sel ? f01_tdata : f00_tdata;
assign m00_tvalid = sel ? f01_tvalid : f00_tvalid;

localparam IDLE_CW = $clog2(IDLE_CYCLE_TIMEOUT);
reg [IDLE_CW-1:0] idle_timeout=0;
wire idle_timedout = PACKET_MODE ? idle_timeout == 0 ? (~arb_req_suppress_sel) && ~empty_nonsel : 1'b0 : 1'b1;
/* If selected buffer not empty, idle_timeout <= IDLE_CYCLE_TIMEOUT
 * If selected buffer empty,
 *   If idle_timeout > 0, idle_timeout <= idle_timeout - 1
 *   else sel <= ~sel;
 */

wire            empty_sel = sel ? empty01 : empty00;
wire         empty_nonsel = sel ? empty00 : empty01;
wire            pktsw_sel = sel ? pktsw01 : pktsw00;
wire arb_req_suppress_sel = sel ? s01_arb_req_suppress : s00_arb_req_suppress;
// Output of FIFO_00 and FIFO_01
// Toggle if selected FIFO is empty or if TLAST is
// detected in PACKET_MODE
always @(posedge m00_aclk) begin
  if (~m00_aresetn) begin
    opf00 <= 0;
    opf01 <= 0;
    sel <= 1'b0;
  end else begin
    if (~empty_sel) begin
      idle_timeout <= IDLE_CYCLE_TIMEOUT;
      if (m00_tready) begin
        if (sel) opf01 <= opf01 + 1; // Intentional rollover
        else     opf00 <= opf00 + 1; // Intentional rollover
      end
      if (pktsw_sel) begin
        sel <= ~sel;
        if (TALK) $display("%s Packet toggling to 0%d", NAME, ~sel);
      end
    end else begin  // If empty, toggle sel
      if (idle_timeout > 0) idle_timeout <= idle_timeout - 1;
      if (idle_timedout) begin
        sel <= ~sel;
        if (TALK) $display("%s Timeout toggling to 0%d", NAME, ~sel);
      end
    end
    /*
    if (~sel) begin
      if (~empty00) begin
        if (m00_tready) begin
          opf00 <= opf00 + 1; // Intentional rollover
        end
        if (pktsw00) begin
          sel <= 1'b1;
          if (TALK) $display("%s Toggling to 01", NAME);
        end
      end else begin  // If empty, toggle sel
        if ((~s00_arb_req_suppress) && ~empty01) begin
          sel <= 1'b1;
          if (TALK) $display("%s Toggling to 01", NAME);
        end
      end
    end else begin // if (sel)
      if (~empty01) begin
        if (m00_tready) begin
          opf01 <= opf01 + 1; // Intentional rollover
        end
        if (pktsw01) begin
          sel <= 1'b0;
          if (TALK) $display("%s Toggling to 00", NAME);
        end
      end else begin  // If empty, toggle sel
        if ((~s01_arb_req_suppress) && ~empty00) begin
          sel <= 1'b0;
          if (TALK) $display("%s Toggling to 00", NAME);
        end
      end
    end
    */
  end
end

endmodule
