/* Simulated version of fofbReadLinkxMux.v
 */

module fofbReadLinksMuxSim (
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
  output reg M00_AXIS_TVALID=0,
  input M00_AXIS_TREADY,
  output reg [7:0] M00_AXIS_TDATA=0,
  output reg M00_AXIS_TUSER=0,
  input S00_ARB_REQ_SUPPRESS,
  input S01_ARB_REQ_SUPPRESS
);

/* FIFO-buffer both S00 and S01 inputs and forward to M00 output
*/

// Two FIFOs
localparam FIFO_DEPTH = 40; // 8 packets
localparam FIFO_CW = $clog2(FIFO_DEPTH+1);
// FIFO_00
reg [8:0] ram00 [0:FIFO_DEPTH-1];
reg [FIFO_CW-1:0] ip00=0; // Input pointer
reg [FIFO_CW-1:0] op00=0; // Output pointer
reg full00=1'b0; // One extra bit
wire empty00 = (ip00 == op00) & ~full00;
// FIFO_01
reg [8:0] ram01 [0:FIFO_DEPTH-1];
reg [FIFO_CW-1:0] ip01=0; // Input pointer
reg [FIFO_CW-1:0] op01=0; // Output pointer
reg full01=1'b0; // One extra bit
wire empty01 = (ip01 == op01) & ~full01;

// FIFO_00 Input
always @(posedge S00_AXIS_ACLK) begin
  if (~S00_AXIS_ARESETN) begin
    ip00 <= 0;
    full00 <= 1'b0;
  end else begin
    if (S00_AXIS_TVALID) begin
      ram00[ip00] <= {S00_AXIS_TUSER, S00_AXIS_TDATA};
      if (ip00 == FIFO_DEPTH-1) begin
        if (op00 == 0) full00 <= 1'b1;
        ip00 <= 0;
      end else begin
        if (op00 == ip00 +1) full00 <= 1'b1;
        ip00 <= ip00 + 1;
      end
    end
  end
end

// FIFO_01 Input
always @(posedge S01_AXIS_ACLK) begin
  if (~S01_AXIS_ARESETN) begin
    ip01 <= 0;
    full01 <= 1'b0;
  end else begin
    if (S01_AXIS_TVALID) begin
      ram01[ip01] <= {S01_AXIS_TUSER, S01_AXIS_TDATA};
      if (ip01 == FIFO_DEPTH-1) begin
        if (op01 == 0) full01 <= 1'b1;
        ip01 <= 0;
      end else begin
        if (op01 == ip01 +1) full01 <= 1'b1;
        ip01 <= ip01 + 1;
      end
    end
  end
end

reg sel=1'b0;
// Output of FIFO_00 and FIFO_01
// Currently only toggles when FIFO is empty. Could change this to
// toggle on TLAST if we want to.
always @(posedge M00_AXIS_ACLK) begin
  M00_AXIS_TUSER <= 1'b0;
  M00_AXIS_TVALID <= 1'b0;
  if (~M00_AXIS_ARESETN) begin
    op00 <= 0;
    op01 <= 0;
    sel <= 1'b0;
  end else if (M00_AXIS_TREADY) begin
    if (~sel) begin
      if (~empty00) begin
        {M00_AXIS_TUSER, M00_AXIS_TDATA} <= ram00[op00];
        M00_AXIS_TVALID <= 1'b1;
        if (op00 == FIFO_DEPTH-1) begin
          op00 <= 0;
        end else begin
          op00 <= op00 + 1;
        end
      end else begin  // If empty, toggle sel
        if (!S00_ARB_REQ_SUPPRESS) sel <= 1'b1;
      end
    end else begin // if (sel)
      if (~empty01) begin
        {M00_AXIS_TUSER, M00_AXIS_TDATA} <= ram01[op01];
        M00_AXIS_TVALID <= 1'b1;
        if (op01 == FIFO_DEPTH-1) begin
          op01 <= 0;
        end else begin
          op01 <= op01 + 1;
        end
      end else begin  // If empty, toggle sel
        if (!S01_ARB_REQ_SUPPRESS) sel <= 1'b0;
      end
    end
  end
end

endmodule
