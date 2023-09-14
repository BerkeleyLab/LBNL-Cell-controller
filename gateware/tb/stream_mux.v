/* Stream multiplexer
 * First-word-fallthrough FIFO: data is available on M00_TDATA/TVALID
 * whenever the FIFO is not empty, but the FIFO will not increment unless
 * M00_TREADY is asserted
 */

module stream_mux #(
  // Width of tdata ports
  parameter DW = 32,
  // PACKET_MODE==1: Toggles FIFO on TLAST
  // PACKET_MODE==0: Toggles FIFO on empty
  parameter [0:0] PACKET_MODE=1'b1,
  // The bit to trigger a FIFO toggle if PACKET_MODE==1
  parameter TLAST_BIT=DW-1
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
localparam FIFO_CW = $clog2(FIFO_DEPTH+1);
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

// Only used when PACKET_MODE==1
wire pktsw00 = ram00[op00][TLAST_BIT];
wire pktsw01 = ram01[op01][TLAST_BIT];

// FIFO_00 Input
always @(posedge s00_aclk) begin
  if (~s00_aresetn) begin
    ipf00 <= 0;
    dropped00 <= 0;
  end else begin
    if (s00_tvalid) begin
      if (!full00) begin
        ram00[ip00] <= s00_tdata;
        ipf00 <= ipf00 + 1; // Intentional rollover
      end else begin // full00
        $display("00 dropped {%d, %x}", s00_tdata);
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
        ram01[ip01] <= s01_tdata;
        ipf01 <= ipf01 + 1; // Intentional rollover
      end else begin // full01
        $display("01 dropped {%d, %x}", s01_tdata);
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

// Output of FIFO_00 and FIFO_01
// Currently only toggles when FIFO is empty. Could change this to
// toggle on TLAST if we want to.
always @(posedge m00_aclk) begin
  if (~m00_aresetn) begin
    opf00 <= 0;
    opf01 <= 0;
    sel <= 1'b0;
  end else begin
    if (~sel) begin
      if (~empty00) begin
        if (m00_tready) begin
          opf00 <= opf00 + 1; // Intentional rollover
        end
        if (PACKET_MODE & pktsw00) begin
          sel <= 1'b1;
          $display("Toggling to 01");
        end
      end else begin  // If empty, toggle sel
        if (!PACKET_MODE) begin
          if ((~s00_arb_req_suppress) && ~empty01) begin
            sel <= 1'b1;
            //$display("Toggling to 01");
          end
        end
      end
    end else begin // if (sel)
      if (~empty01) begin
        if (m00_tready) begin
          opf01 <= opf01 + 1; // Intentional rollover
        end
        if (PACKET_MODE & pktsw01) begin
          sel <= 1'b0;
          $display("Toggling to 00");
        end
      end else begin  // If empty, toggle sel
        if (!PACKET_MODE) begin
          if ((~s01_arb_req_suppress) && ~empty00) begin
            sel <= 1'b0;
            //$display("Toggling to 00");
          end
        end
      end
    end
  end
end

endmodule
