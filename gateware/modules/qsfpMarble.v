/* Marble QSFP Readout wrapper
 * Attempting to be drop-in compatible (as much as possible) with
 * bmb7-specific qsfpReadout.v
 */

/* TODO
*   1. QSFP1_MOD_PRS, QSFP2_MOD_PRS readable via U34 (PCAL9555AHF) over I2C (low means module present, high means absent)
*      Need to interpose lb_addr to occasionally read from U34_PORT0 and U34_PORT1
*   2. Figure out how to test this in-situ
*
* Notes:
* Software reads by presenting actual I2C register address to bus and
* expecting the result roughly immediately available?
            int qidx = (qsfp * 256 + offset) >> 1;  // NOTE the shift! Even offsets only!
            GPIO_WRITE(GPIO_IDX_QSFP_IIC, qidx);
            v = GPIO_READ(GPIO_IDX_QSFP_IIC);
* Bytes are packed two-at-a-time: [15:8] = byte0; [7:0] = byte1
*   E.g.: s = "hello world"
*         xaction0:
*           addr = STRING_OFFSET
*           rdata[15:8] = "h"
*           rdata[7:0]  = "e"
*         xaction1:
*           addr = STRING_OFFSET+2
*           rdata[15:8] = "l"
*           rdata[7:0]  = "l"
*         xaction2:
*           addr = STRING_OFFSET+4
*           rdata[15:8] = "o"
*           rdata[7:0]  = " "
*         xaction3:
*           addr = STRING_OFFSET+6
*           rdata[15:8] = "w"
*           rdata[7:0]  = "o"
*         xaction4:
*           addr = STRING_OFFSET+8
*           rdata[15:8] = "r"
*           rdata[7:0]  = "l"
*         xaction5:
*           addr = STRING_OFFSET+10
*           rdata[15:8] = "d"
*           rdata[7:0]  = "\0"
*/

module qsfpMarble (
  parameter QSFP_COUNT  = 2,
  parameter CLOCK_RATE  = 100000000,
  parameter BIT_RATE    = 100000
  )(
  input                           clk,
  // Bus interface
  input  [$clog2(QSFP_COUNT)+6:0] readAddress, // QSFP register to read
  output                   [15:0] readData,    // Data read from QSFP register
  // QSFP pin values periodically read from Marble GPIO mux (U34) and presented here
  output         [QSFP_COUNT-1:0] PRESENT_n,   // NOTE! Opposite direction vs bmb7
  output         [QSFP_COUNT-1:0] RESET_n,
  output         [QSFP_COUNT-1:0] MODSEL_n,
  output         [QSFP_COUNT-1:0] LPMODE,
  // I2C physical pins
  inout                           SCL,
  inout                           SDA
);

// ====================== GPIO bus ========================
// read offset is shifted for 16-bit access
wire [7:0] roffset = {readAddress[6:0], 1'b0};
// I'm being annoyingly generic here.  There are only 2 QSFPs on marble.
wire [$clog2(QSFP_COUNT)-1:0] rqsfp = readAddress[$clog2(QSFP_COUNT)+6:7];  // QSFP number 0 or 1
reg [15:0] rdata;
assign readData = rdata;
initial begin
  rdata = 16'h0000;
end
`include "marble_i2c.vh"
`include "qsfp_memory.vh"
wire [9:0] offset_decoded = (rqsfp == 0) && (roffset == QSFP_MODULE_STATUS_OFFSET) ? QSFP1_MODULE_STATUS :
                            (rqsfp == 0) && (roffset == QSFP_TEMPERATURE_OFFSET) ? QSFP1_TEMPERATURE :
                            (rqsfp == 0) && (roffset == QSFP_VSUPPLY_OFFSET) ? QSFP1_VSUPPLY :
                            (rqsfp == 0) && (roffset == QSFP_RXPOWER_0_OFFSET) ? QSFP1_RXPOWER :
                            (rqsfp == 0) && (roffset == QSFP_IDENTIFIER_OFFSET) ? QSFP1_IDENTIFIER :
                            (rqsfp == 0) && (roffset == QSFP_VENDOR_NAME_OFFSET) ? QSFP1_VENDOR_NAME :
                            (rqsfp == 0) && (roffset == QSFP_PART_NAME_OFFSET) ? QSFP1_PART_NAME :
                            (rqsfp == 0) && (roffset == QSFP_REVISION_CODE_OFFSET) ? QSFP1_REVISION_CODE :
                            (rqsfp == 0) && (roffset == QSFP_WAVELENGTH_OFFSET) ? QSFP1_WAVELENGTH:
                            (rqsfp == 0) && (roffset == QSFP_SERIAL_NUMBER_OFFSET) ? QSFP1_SER_NUM :
                            (rqsfp == 0) && (roffset == QSFP_DATE_CODE_OFFSET) ? QSFP1_DATE_CODE :
                            (rqsfp == 1) && (roffset == QSFP_MODULE_STATUS_OFFSET) ? QSFP2_MODULE_STATUS :
                            (rqsfp == 1) && (roffset == QSFP_TEMPERATURE_OFFSET) ? QSFP2_TEMPERATURE :
                            (rqsfp == 1) && (roffset == QSFP_VSUPPLY_OFFSET) ? QSFP2_VSUPPLY :
                            (rqsfp == 1) && (roffset == QSFP_RXPOWER_0_OFFSET) ? QSFP2_RXPOWER :
                            (rqsfp == 1) && (roffset == QSFP_IDENTIFIER_OFFSET) ? QSFP2_IDENTIFIER :
                            (rqsfp == 1) && (roffset == QSFP_VENDOR_NAME_OFFSET) ? QSFP2_VENDOR_NAME :
                            (rqsfp == 1) && (roffset == QSFP_PART_NAME_OFFSET) ? QSFP2_PART_NAME :
                            (rqsfp == 1) && (roffset == QSFP_REVISION_CODE_OFFSET) ? QSFP2_REVISION_CODE :
                            (rqsfp == 1) && (roffset == QSFP_WAVELENGTH_OFFSET) ? QSFP2_WAVELENGTH:
                            (rqsfp == 1) && (roffset == QSFP_SERIAL_NUMBER_OFFSET) ? QSFP2_SER_NUM :
                            (rqsfp == 1) && (roffset == QSFP_DATE_CODE_OFFSET) ? QSFP2_DATE_CODE :
                            10'h0;
// ====================== I2C pins ========================
reg scl_t = 1'b1;
wire scl_i;
IOBUF iobuf_scl(.T(SCL_t), .I(1'b0), .O(SCL_i), .IO(SCL));
wire sda_t;
wire sda_i;
IOBUF iobuf_sda(.T(sda_t), .I(1'b0), .O(SDA_i), .IO(SDA));

// ==================== Special Pins ======================
reg [QSFP_COUNT-1:0] present_n;
assign PRESENT_N = present_n;
reg [QSFP_COUNT-1:0] reset_n;
assign RESET_N = reset_n;
reg [QSFP_COUNT-1:0] modsel_n;
assign MODSEL_N = modsel_n;
reg [QSFP_COUNT-1:0] lpmode;
assign LPMODE = lpmode;
initial begin
  present_n = {QSFP_COUNT{1'b0}};
  reset_n   = {QSFP_COUNT{1'b0}};
  modsel_n  = {QSFP_COUNT{1'b0}};
  lpmode    = {QSFP_COUNT{1'b0}};
end

// ====================== Localbus ========================
reg lb_lsb;
localparam I2C_CHUNK_RESULTS_OFFSET = 12'h0800;
wire [11:0] lb_addr = I2C_CHUNK_RESULTS_OFFSET | (offset_decoded + lb_lsb);
wire [7:0] lb_dout;

reg [$clog2(QSFP_COUNT)+6:0] readAddress_r;
reg [7:0] lb_dout0, lb_dout1;
initial begin
  readAddress_r = 0;
  lb_lsb = 1'b0;    // Address has changed, kick off 2-byte read
  lb_lsb_0 = 1'b0;  // Delayed version of lb_lsb
  lb_dout0 = 8'h00;
  lb_dout1 = 8'h00;
end

always @(posedge clk) begin
  readAddress_r <= readAddress;
  lb_dout0 <= lb_dout;
  lb_dout1 <= lb_dout0;
  lb_lsb <= 1'b0;
  lb_lsb_0 <= lb_lsb;
  if (readAddress_r != readAddress) begin
    // Whenever address changes, read the next highest address too
    lb_lsb <= 1'b1;
  end
  if (lb_lsb_0) begin
    rdata <= {lb_dout0, lb_dout}; // Hopefully this latches the correct bytes
  end
end

// ====================== I2C Memory ======================
reg freeze;   // TODO unused
reg i2c_rst;  // TODO unused
wire run_stat;  // TODO unused
wire updated; // TODO unused
initial begin
  i2c_rst = 1'b0;
  freeze = 1'b0;
end

i2c_chunk #(
  .initial_file("prog.dat")
  ) i2c_chunk_i (
  .clk(clk), // input
  .lb_addr(lb_addr), // input [11:0]
  .lb_din(8'h00), // input [7:0]
  .lb_write(1'b0), // input
  .lb_dout(lb_dout), // output [7:0]
  .run_cmd(1'b1), // input
  .trace_cmd(1'b0), // input
  .freeze(freeze), // input
  .run_stat(run_stat), // output
  .analyze_armed(), // output
  .analyze_run(), // output
  .updated(updated), // output
  .err_flag(), // output
  .hw_config(), // output [3:0]
  .scl(i2c_scl), // output
  .sda_drive(sda_drive), // output
  .sda_sense(sda_sense), // input
  .scl_sense(i2c_scl), // input
  .trig_mode(1'b0), // input
  .rst(i2c_rst), // input
  .intp(1'b0) // input
);

endmodule
