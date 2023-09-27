/* Input buffer for Verilator top-level flattened stream packet interface
*/

module cell_stream_ibuf #(
  parameter NAME = ""
) (
  input clk,

  // Stream packet MUX input
  input         stream_mux_strobe,
  input  [31:0] stream_in_header,
  input  [31:0] stream_in_datax,
  input  [31:0] stream_in_datay,
  input  [31:0] stream_in_datas,

  output        tvalid,
  output        tlast,
  output [31:0] tdata
);

reg [31:0] ram [0:3];
integer I;
initial begin
  for (I = 0; I < 4 ; I = I + 1) ram [I] = 0;
end

reg sending=0;
assign tvalid = sending;
assign tlast = sending && (&optr);
assign tdata = ram[optr];
reg [1:0] optr=0;

always @(posedge clk) begin
  if (sending) begin
    $display("%s: optr -> %d; data -> 0x%x", NAME, optr, ram[optr]);
    if (&optr) begin
      optr <= 0;
      sending <= 1'b0;
    end else begin
      optr <= optr + 1;
    end
  end else begin
    if (stream_mux_strobe) begin
      $display("%s: strobe", NAME);
      ram[0] <= stream_in_header;
      ram[1] <= stream_in_datax;
      ram[2] <= stream_in_datay;
      ram[3] <= stream_in_datas;
      sending <= 1'b1;
    end
  end
end

endmodule
