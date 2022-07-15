// Reduce a net's width
module reduceWidth #(
    parameter IWIDTH = 12,
    parameter OWIDTH = 8) (
    input  wire [IWIDTH-1:0] I,
    output reg  [OWIDTH-1:0] O);

wire signBit;
assign signBit = I[IWIDTH-1];
wire [IWIDTH-OWIDTH-1:0] checkBits;
assign checkBits = I[IWIDTH-2-:IWIDTH-OWIDTH];

always @(I, signBit, checkBits) begin
    if ((signBit == 1'b0) && (|checkBits == 1'b1)) begin
        O = {1'b0, {OWIDTH-1{1'b1}}};
    end
    else if ((signBit == 1'b1) && (&checkBits != 1'b1)) begin
        O = {1'b1, {OWIDTH-1{1'b0}}};
    end
    else begin
        O = I[OWIDTH-1:0];
    end
end
endmodule
