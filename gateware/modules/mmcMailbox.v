//
// Communicate with on-board microcontroller
//
module mmcMailbox #(
    parameter ADDRESS_WIDTH = 11,
    parameter DEBUG         = "false"
    ) (
    input         clk,
    input  [31:0] GPIO_OUT,
    input         GPIO_STROBE,
    output [31:0] csr,

    (*mark_debug=DEBUG*) input  SCLK,
    (*mark_debug=DEBUG*) input  CSB,
    (*mark_debug=DEBUG*) input  MOSI,
    (*mark_debug=DEBUG*) output MISO);

localparam DATA_WIDTH = 8;

// System access to DPRAM
wire [ADDRESS_WIDTH-1:0] sysAddress = GPIO_STROBE ?
                             GPIO_OUT[DATA_WIDTH+:ADDRESS_WIDTH] : sysAddrLatch;
reg [ADDRESS_WIDTH-1:0] sysAddrLatch;
reg [DATA_WIDTH-1:0] dpram [0:(1<<ADDRESS_WIDTH)-1];
reg [DATA_WIDTH-1:0] dpramSys, dpramMMC;

assign csr = { {32-ADDRESS_WIDTH-DATA_WIDTH{1'b0}}, sysAddrLatch, dpramSys };
wire sysWriteEnable = GPIO_STROBE && GPIO_OUT[31];


// MMC access to DPRAM
(*mark_debug=DEBUG*) wire [DATA_WIDTH-1:0] mmcRxAddr, mmcRxData;
(*mark_debug=DEBUG*) wire mmcReadStrobe, mmcWriteStrobe;
(*mark_debug=DEBUG*) reg  [DATA_WIDTH-1:0] mmcTxData;
(*mark_debug=DEBUG*) reg [ADDRESS_WIDTH-1:4] mmcAddrLatch;
wire [ADDRESS_WIDTH-1:0] mmcAddress = {mmcAddrLatch, mmcRxAddr[3:0]};
wire mmcWriteEnable = mmcWriteStrobe && mmcRxAddr[7:4] == 4'h5;

///////////////////////////////////////////////////////////////////////////////
// Based on Vivado language template for true DPRAM.
// Be cautious when making changes to the following two blocks.  It is very
// easy to break the tool's inference of a block RAM.
always @(posedge clk) begin
    // System access
    dpramSys <= dpram[sysAddress];
    if (sysWriteEnable) begin
        dpram[sysAddress] <= GPIO_OUT[DATA_WIDTH-1:0];
    end
end
always @(posedge clk) begin
    // MMC (SPI) access
    dpramMMC <= dpram[mmcAddress];
    if (mmcWriteEnable) begin
        dpram[mmcAddress] <= mmcRxData;
    end
end
///////////////////////////////////////////////////////////////////////////////

// Non-DPRAM code
always @(posedge clk) begin
    if (GPIO_STROBE) begin
        sysAddrLatch <= GPIO_OUT[DATA_WIDTH+:ADDRESS_WIDTH];
    end
    if (mmcReadStrobe) begin
        mmcTxData <= dpramMMC;
    end
    if (mmcWriteStrobe) begin
        if (mmcRxAddr == 8'h22) begin
            mmcAddrLatch <= mmcRxData[0+:ADDRESS_WIDTH-4];
        end
    end
end

// SPI link from MMC
wire [3:0] spi_pins_debug;
spi_gate spi (
    .SCLK(SCLK),
    .CSB(CSB),
    .MOSI(MOSI),
    .MISO(MISO),
    .config_clk(clk),
    .config_w(mmcWriteStrobe),
    .config_r(mmcReadStrobe),
    .config_a(mmcRxAddr),
    .config_d(mmcRxData),
    .tx_data(mmcTxData),
    .spi_pins_debug(spi_pins_debug));

generate
if (DEBUG != "TRUE" && DEBUG != "true" && DEBUG != "FALSE" && DEBUG != "false") begin
    mmcMailbox_DEBUG_only_TRUE_or_FALSE_SUPPORTED();
end
endgenerate

generate
if (DEBUG == "TRUE" || DEBUG == "true") begin

`ifndef SIMULATE
wire [255:0] probe;
ila_td256_s4096_cap mmcm_ila_td256_s4096_cap_inst (
    .clk(clk),
    .probe0(probe)
);

assign probe[0]       = mmcWriteStrobe;
assign probe[1]       = mmcReadStrobe;
assign probe[2]       = sysWriteEnable;
assign probe[3]       = mmcWriteEnable;

assign probe[23:16]   = mmcRxAddr;
assign probe[31:24]   = mmcRxData;
assign probe[39:32]   = mmcTxData;

assign probe[43:40]   = spi_pins_debug;

assign probe[138:128] = sysAddress;
assign probe[170:160] = mmcAddress;

assign probe[199:192] = dpramSys;
assign probe[231:224] = dpramMMC;

`endif

end // end if
endgenerate

endmodule
