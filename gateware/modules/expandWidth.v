// Expand a net's width
module expandWidth #(
    parameter IWIDTH = 8,
    parameter OWIDTH = 12) (
    input  wire [IWIDTH-1:0] I,
    output wire [OWIDTH-1:0] O);

wire signBit;
assign signBit = I[IWIDTH-1];
assign O = {{OWIDTH-IWIDTH{signBit}}, I};
endmodule
