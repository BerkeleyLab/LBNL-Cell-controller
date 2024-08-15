// Generic FIFO wrapper for bedrock/dsp/fifo.v
// with the option of non FWFT operation

module genericFifo #(
    parameter aw = 3,
    parameter dw = 8,
    parameter fwft = 1
) (
    input clk,

    input [dw - 1: 0] din,
    input we,

    output [dw - 1: 0] dout,
    input re,

    output full,
    output empty,
    output last,

    // -1: empty, 0: single element, 2**aw - 1: full
    output [aw:0] count
);

wire [dw - 1: 0] dout_;
fifo #(
    .aw(aw),
    .dw(dw)
) fifo (
    .clk(clk),
    .din(din),
    .we(we),

    .dout(dout_),
    .re(re),

    .full(full),
    .empty(empty),
    .last(last),
    .count(count)
);

generate

if (fwft) begin
    assign dout = dout_;
end else begin

    reg [dw - 1: 0] dout_r;
    always @(posedge clk) begin
        if (re)
            dout_r <= dout_;
    end

    assign dout = dout_r;
end
endgenerate

endmodule
