/* Simulated version of readBPMlinksMux.v
 * First-word-fallthrough FIFO: data is available on M00_AXIS_TDATA/TVALID
 * whenever the FIFO is not empty, but the FIFO will not increment unless
 * M00_AXIS_TREADY is asserted
 */

module readBPMlinksMuxSim (
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

/* FIFO-buffer both S00 and S01 inputs and forward to M00 output
*/

// Two FIFOs
localparam FIFO_DEPTH = 40; // 8 packets
localparam FIFO_CW = $clog2(FIFO_DEPTH+1);
// FIFO_00
reg [111:0] ram00 [0:FIFO_DEPTH-1];
reg [FIFO_CW-1:0] ip00=0; // Input pointer
reg [FIFO_CW-1:0] op00=0; // Output pointer
reg full00=1'b0; // One extra bit
wire empty00 = (ip00 == op00) & ~full00;
// FIFO_01
reg [111:0] ram01 [0:FIFO_DEPTH-1];
reg [FIFO_CW-1:0] ip01=0; // Input pointer
reg [FIFO_CW-1:0] op01=0; // Output pointer
reg full01=1'b0; // One extra bit
wire empty01 = (ip01 == op01) & ~full01;
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
    ip00 <= 0;
    full00 <= 1'b0;
  end else begin
    if (S00_AXIS_TVALID) begin
      ram00[ip00] <= S00_AXIS_TDATA;
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
      ram01[ip01] <= S01_AXIS_TDATA;
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
    op00 <= 0;
    op01 <= 0;
    sel <= 1'b0;
  end else begin
    if (~sel) begin
      if (~empty00) begin
        if (M00_AXIS_TREADY) begin
          if (op00 == FIFO_DEPTH-1) begin
            op00 <= 0;
          end else begin
            op00 <= op00 + 1;
          end
        end
      end else begin  // If empty and fifo 01 not empty, toggle sel
        if ((~S00_ARB_REQ_SUPPRESS) && ~empty01) begin
          sel <= 1'b1;
          //$display("Toggling to 01");
        end
      end
    end else begin // if (sel)
      if (~empty01) begin
        if (M00_AXIS_TREADY) begin
          if (op01 == FIFO_DEPTH-1) begin
            op01 <= 0;
          end else begin
            op01 <= op01 + 1;
          end
        end
      end else begin  // If empty and fifo 00 not empty, toggle sel
        if ((~S01_ARB_REQ_SUPPRESS) && ~empty00) begin
          sel <= 1'b0;
          //$display("Toggling to 00");
        end
      end
    end
  end
end

endmodule
