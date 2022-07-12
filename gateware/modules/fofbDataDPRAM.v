// Dual port RAM for cell readout data and other DSP applications
// Holds S, Y, X for cell readouts
module fofbDataDPRAM #(
        parameter ADDR_WIDTH = 9,
        parameter DATA_WIDTH = 3*32) (
        input  wire                  clk,
        input  wire                  wea,
        input  wire [ADDR_WIDTH-1:0] addra,
        input  wire [DATA_WIDTH-1:0] dina,
        input  wire [ADDR_WIDTH-1:0] addrb,
        output reg  [DATA_WIDTH-1:0] doutb);

reg [DATA_WIDTH-1:0] dpram[0:(1<<ADDR_WIDTH)-1];

always @(posedge clk) begin
    if (wea) dpram[addra] <= dina;
    doutb <= dpram[addrb];
end

endmodule
