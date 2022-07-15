// Saturating addition
module saturateAdd #(
    parameter   AWIDTH = 8,
    parameter   BWIDTH = 8,
    parameter SUMWIDTH = 8) (
    input  wire   [AWIDTH-1:0] A,
    input  wire   [BWIDTH-1:0] B,
    output wire [SUMWIDTH-1:0] SUM);

localparam FULLWIDTH = (AWIDTH > BWIDTH) ? AWIDTH+1 : BWIDTH+1;

wire [FULLWIDTH-1:-0] fullWidthA, fullWidthB, fullWidthSum;
assign fullWidthA = {{FULLWIDTH-AWIDTH{A[AWIDTH-1]}}, A};
assign fullWidthB = {{FULLWIDTH-BWIDTH{B[BWIDTH-1]}}, B};
assign fullWidthSum = fullWidthA + fullWidthB;
reduceWidth #(.IWIDTH(FULLWIDTH),.OWIDTH(SUMWIDTH))rw(.I(fullWidthSum),.O(SUM));
endmodule
