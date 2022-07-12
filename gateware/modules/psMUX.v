// Multiplex power supply setpoint streams
// Switch only between packets.

module psMUX #(
    parameter DEBUG     = "false",
    parameter AXI_WIDTH = 32
    ) (
    input  wire                                     clk,

    (*mark_debug=DEBUG*)input  wire                 AWGrequest,
    (*mark_debug=DEBUG*)output reg                  AWGenabled = 0,

    (*mark_debug=DEBUG*)input  wire [AXI_WIDTH-1:0] fofbTDATA,
    (*mark_debug=DEBUG*)input  wire                 fofbTVALID,
    (*mark_debug=DEBUG*)input  wire                 fofbTLAST,

    (*mark_debug=DEBUG*)input  wire [AXI_WIDTH-1:0] awgTDATA,
    (*mark_debug=DEBUG*)input  wire                 awgTVALID,
    (*mark_debug=DEBUG*)input  wire                 awgTLAST,

    (*mark_debug=DEBUG*)output reg  [AXI_WIDTH-1:0] psTDATA,
    (*mark_debug=DEBUG*)output reg                  psTVALID = 0,
    (*mark_debug=DEBUG*)output reg                  psTLAST = 0);

always @(posedge clk) begin
    if ((fofbTVALID == 0) && (awgTVALID == 0)) begin
        AWGenabled <= AWGrequest;
    end
    if (AWGenabled) begin
        psTDATA  <= awgTDATA;
        psTVALID <= awgTVALID;
        psTLAST  <= awgTLAST ;
    end
    else begin
        psTDATA  <= fofbTDATA;
        psTVALID <= fofbTVALID;
        psTLAST  <= fofbTLAST ;
    end
end

endmodule
