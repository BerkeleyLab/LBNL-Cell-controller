/* Output buffer for Verilator top-level flattened stream packet interface
*/

module cell_stream_obuf #(
  parameter NAME = ""
) (
  input clk,

  // Stream packet MUX output
  output        stream_mux_valid,
  output [31:0] stream_out_header,
  output [31:0] stream_out_datax,
  output [31:0] stream_out_datay,
  output [31:0] stream_out_datas,

  input         tvalid,
  input         tlast,
  input  [31:0] tdata
);

reg [31:0] ram [0:3];
integer I;
initial begin
  for (I = 0; I < 4 ; I = I + 1) ram [I] = 0;
end

reg [1:0] iptr=0;
reg valid=1'b0;
assign stream_mux_valid = valid;
assign stream_out_header = ram[0];
assign stream_out_datax  = ram[1];
assign stream_out_datay  = ram[2];
assign stream_out_datas  = ram[3];

always @(posedge clk) begin
  valid <= 1'b0;  // valid is 'strobe' (should only be asserted for 1 clk cycle)
  if (tvalid) begin
    if (tlast) begin
      $display("%s: 0x%x, 0x%x, 0x%x, 0x%x", NAME, ram[0], ram[1], ram[2], ram[3]);
      ram[iptr] <= tdata;
      valid <= 1'b1;  // Latched in our last word
      iptr <= 0;
    end else begin
      ram[iptr] <= tdata;
      iptr <= iptr + 1;
    end
  end
end

endmodule
