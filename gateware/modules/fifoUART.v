//
// Simple UART and FIFO
// Use this to simplify console I/O
//
module fifoUART #(
    parameter CLK_RATE = 100000000,
    parameter BIT_RATE = 115200) (
    input wire         clk,
    input wire         strobe,
    input  wire [31:0] control,
    output wire [31:0] status,
    output wire        TxData,
    input  wire        RxData);

localparam FULLBIT_RELOAD = ((CLK_RATE + (BIT_RATE/2)) / BIT_RATE) - 1;
localparam HALFBIT_RELOAD = ((CLK_RATE + BIT_RATE) / (BIT_RATE*2)) - 1;
parameter CLKDIVIDER_WIDTH = $clog2(FULLBIT_RELOAD+1);
localparam L2_FIFO_SIZE = 12;


reg       txFull = 0, txOverrun = 0;
reg [3:0] txBitsLeft = 0;
reg       txStart = 0, txActive = 0;
reg [CLKDIVIDER_WIDTH-1:0] txDivider = 0;

reg [7:0] txDPRAM [0:(1<<L2_FIFO_SIZE)-1];
reg [7:0] txFIFO;
reg [L2_FIFO_SIZE-1:0] txFifoHead = 0, txFifoTail = 0;

reg [9:0] txShift = 10'h3FF;
assign TxData = txShift[0];

reg       rxActive = 0, RxData_d0, RxData_d1, rxReady = 0;
reg [7:0] rxByte;
reg [3:0] rxBitsLeft = 0;
reg [CLKDIVIDER_WIDTH-1:0] rxDivider = 0;
assign status = {txFull, txOverrun, {32-3-8{1'b0}}, rxReady, rxByte};

always @(posedge clk) begin
    //
    // Transmitter
    //
    if ((txFifoHead + {{L2_FIFO_SIZE-1{1'b0}},1'b1}) == txFifoTail) begin
        if (strobe && !control[8]) begin
            txOverrun <= 1;
        end
        txFull <= 1;
    end
    else begin
        txFull <= 0;
        if (strobe && !control[8]) begin
            txDPRAM[txFifoHead] <= control[7:0];
            txFifoHead <= txFifoHead + 1;
        end
    end

    txFIFO <= txDPRAM[txFifoTail];
    if (txStart) begin
        txShift <= { 1'b1, txFIFO, 1'b0 };
        txFifoTail <= txFifoTail + 1;
        txStart <= 0;
        txActive <= 1;
        txBitsLeft <= 9;
        txDivider <= FULLBIT_RELOAD;
    end
    else if (txActive) begin
        if (txDivider == 0) begin
            txShift <= { 1'b1, txShift[9:1] };
            if (txBitsLeft == 0) begin
                txActive <= 0;
            end
            else begin
                txBitsLeft <= txBitsLeft - 1;
                txDivider <= FULLBIT_RELOAD;
            end
        end
        else begin
            txDivider <= txDivider - 1;
        end
    end
    else begin
        if (txFifoHead != txFifoTail) begin
            txStart <= 1;
        end
    end

    //
    // Receiver
    // Simple double-buffer.  No FIFO.
    //
    RxData_d0 <= RxData;
    RxData_d1 <= RxData_d0;
    if (strobe && control[8] && rxReady) rxReady <= 0;
    if (rxActive) begin
        if (rxDivider == 0) begin
            rxDivider <= FULLBIT_RELOAD;
            rxBitsLeft <= rxBitsLeft - 1;
            if (rxBitsLeft == 9) begin
                if (RxData_d0) begin
                    rxActive <= 0;
                end
            end
            else if (rxBitsLeft == 0) begin
                if (RxData_d0 && !rxReady) rxReady <= 1;
                rxActive <= 0;
            end
            else begin
                rxByte <= { RxData_d0, rxByte[7:1] };
            end
        end
        else begin
            rxDivider <= rxDivider - 1;
        end
    end
    else if ((RxData_d0 == 0) && (RxData_d1 == 1)) begin
        rxBitsLeft <= 9;
        rxActive <= 1;
        rxDivider <= HALFBIT_RELOAD;
    end
end

endmodule
