// Saturating subtraction
module saturateSub #(
    parameter    AWIDTH = 8,
    parameter    BWIDTH = 8,
    parameter DIFFWIDTH = 8) (
    input  wire    [AWIDTH-1:0] A,
    input  wire    [BWIDTH-1:0] B,
    output wire [DIFFWIDTH-1:0] DIFF);

localparam FULLWIDTH = (AWIDTH > BWIDTH) ? AWIDTH+1 : BWIDTH+1;

wire [FULLWIDTH-1:-0] fullWidthA, fullWidthB, fullWidthDiff;
assign fullWidthA = {{FULLWIDTH-AWIDTH{A[AWIDTH-1]}}, A};
assign fullWidthB = {{FULLWIDTH-BWIDTH{B[BWIDTH-1]}}, B};
assign fullWidthDiff = fullWidthA - fullWidthB;
reduceWidth #(.IWIDTH(FULLWIDTH),.OWIDTH(DIFFWIDTH))rw(.I(fullWidthDiff),.O(DIFF));
endmodule
