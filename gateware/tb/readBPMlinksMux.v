/* Simulated version of readBPMlinksMux.v
 * First-word-fallthrough FIFO: data is available on M00_AXIS_TDATA/TVALID
 * whenever the FIFO is not empty, but the FIFO will not increment unless
 * M00_AXIS_TREADY is asserted
 */

module readBPMlinksMux (
  input ACLK, // unused
  input ARESETN, // unused
  input S00_AXIS_ACLK,
  input S01_AXIS_ACLK,
  input S00_AXIS_ARESETN,
  input S01_AXIS_ARESETN,
  // Input Stream 00
  input S00_AXIS_TVALID,
  input [111:0] S00_AXIS_TDATA,
  // Input Stream 01
  input S01_AXIS_TVALID,
  input [111:0] S01_AXIS_TDATA,
  // Output Stream
  input M00_AXIS_ACLK,
  input M00_AXIS_ARESETN,
  output M00_AXIS_TVALID,
  input M00_AXIS_TREADY,
  output [111:0] M00_AXIS_TDATA,
  input S00_ARB_REQ_SUPPRESS,
  input S01_ARB_REQ_SUPPRESS
);

localparam DW = 112; // TDATA

stream_mux #(
  .DW(DW),
  .PACKET_MODE(1'b0)
) mux (
  .aclk(ACLK), // input
  .aresetn(ARESETN), // input
  .s00_aclk(S00_AXIS_ACLK), // input
  .s01_aclk(S01_AXIS_ACLK), // input
  .s00_aresetn(S00_AXIS_ARESETN), // input
  .s01_aresetn(S01_AXIS_ARESETN), // input
  .s00_tvalid(S00_AXIS_TVALID), // input
  .s00_tdata(S00_AXIS_TDATA), // input [DW-1:0]
  .s01_tvalid(S01_AXIS_TVALID), // input
  .s01_tdata(S01_AXIS_TDATA), // input [DW-1:0]
  .m00_aclk(M00_AXIS_ACLK), // input
  .m00_aresetn(M00_AXIS_ARESETN), // input
  .m00_tvalid(M00_AXIS_TVALID), // output
  .m00_tready(M00_AXIS_TREADY), // input
  .m00_tdata(M00_AXIS_TDATA), // output [31:0]
  .s00_arb_req_suppress(S00_ARB_REQ_SUPPRESS), // input
  .s01_arb_req_suppress(S01_ARB_REQ_SUPPRESS) // input
);

/* FIFO-buffer both S00 and S01 inputs and forward to M00 output

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

// FIFO_00 Input
always @(posedge S00_AXIS_ACLK) begin
  if (~S00_AXIS_ARESETN) begin
    ipf00 <= 0;
    dropped00 <= 0;
  end else begin
    if (S00_AXIS_TVALID) begin
      if (!full00) begin
        ram00[ip00] <= S00_AXIS_TDATA;
        ipf00 <= ipf00 + 1; // Intentional rollover
      end else begin // full00
        $display("00 dropped {%d, %x}", S00_AXIS_TLAST, S00_AXIS_TDATA);
        dropped00 <= dropped00 + 1;
      end
    end
  end
end

// FIFO_01 Input
always @(posedge S01_AXIS_ACLK) begin
  if (~S01_AXIS_ARESETN) begin
    ipf01 <= 0;
  end else begin
    if (S01_AXIS_TVALID) begin
      if (!full01) begin
        ram01[ip01] <= S01_AXIS_TDATA;
        ipf01 <= ipf01 + 1; // Intentional rollover
      end else begin // full01
        $display("01 dropped {%d, %x}", S01_AXIS_TLAST, S01_AXIS_TDATA);
        dropped01 <= dropped01 + 1;
      end
    end
  end
end

wire [111:0] f00_tdata = ram00[op00];
wire f00_tvalid = ~empty00;

wire [111:0] f01_tdata = ram01[op01];
wire f01_tvalid = ~empty01;

reg sel=1'b0;
assign M00_AXIS_TDATA = sel ? f01_tdata : f00_tdata;
assign M00_AXIS_TVALID = sel ? f01_tvalid : f00_tvalid;

// Output of FIFO_00 and FIFO_01
// Currently only toggles when FIFO is empty. Could change this to
// toggle every time if we want
always @(posedge M00_AXIS_ACLK) begin
  if (~M00_AXIS_ARESETN) begin
    opf00 <= 0;
    opf01 <= 0;
    sel <= 1'b0;
  end else begin
    if (~sel) begin
      if (~empty00) begin
        if (M00_AXIS_TREADY) begin
          opf00 <= opf00 + 1; // Intentional rollover
        end
      end else begin  // If empty, toggle sel
        if ((~S00_ARB_REQ_SUPPRESS) && ~empty01) begin
          sel <= 1'b1;
          $display("Toggling to 01");
        end
      end
    end else begin // if (sel)
      if (~empty01) begin
        if (M00_AXIS_TREADY) begin
          opf01 <= opf01 + 1; // Intentional rollover
        end
      end else begin  // If empty, toggle sel
        if ((~S01_ARB_REQ_SUPPRESS) && ~empty00) begin
          sel <= 1'b0;
          $display("Toggling to 00");
        end
      end
    end
  end
end
*/

endmodule
