/* Marble QSFP Readout wrapper
 * This module is not a drop-in replacement for the
 * bmb7-specific qsfpReadout.v. It uses a different
 * interface and requires different software in the
 * processor core (whatever is driving the data bus).
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

module qsfpMarble #(
  parameter QSFP_COUNT  = 2,
  parameter CLOCK_RATE  = 100000000,
  parameter BIT_RATE    = 100000
  )(
  input                           clk,
  // Bus interface
  input  [$clog2(QSFP_COUNT)+7:0] readAddress,  // QSFP register to read
  output                    [7:0] readData,     // Data read from QSFP register
  input                           freeze,       // i2c_chunk freeze
  output                          run_stat,     // i2c_chunk run status
  output                          updated,      // i2c_chunk updated flag
  // I2C physical pins
  inout                           SCL,
  inout                           SDA
);

// ====================== GPIO bus ========================
wire [7:0] roffset = readAddress[7:0];
// I'm being annoyingly generic here.  There are only 2 QSFPs on marble.
wire [$clog2(QSFP_COUNT)-1:0] rqsfp = readAddress[$clog2(QSFP_COUNT)+7:8];  // QSFP number 0 or 1

`include "marble_i2c.vh"
`include "qsfp_memory.vh"
wire [9:0] offset_decoded = (rqsfp == 0) && (roffset == QSFP_OVERRIDE_PRESENT) ? U34_PORT0 :
                            (rqsfp == 0) && (roffset == QSFP_MODULE_STATUS_OFFSET) ? QSFP1_MODULE_STATUS :
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
                            (rqsfp == 1) && (roffset == QSFP_OVERRIDE_PRESENT) ? U34_PORT1 :
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
IOBUF iobuf_scl(.T(scl_t), .I(1'b0), .O(scl_i), .IO(SCL));
wire sda_t;
wire sda_i;
IOBUF iobuf_sda(.T(sda_t), .I(1'b0), .O(sda_i), .IO(SDA));

// ====================== Localbus ========================
localparam I2C_CHUNK_RESULTS_OFFSET = 12'h0800;
wire [11:0] lb_addr = I2C_CHUNK_RESULTS_OFFSET | offset_decoded;
wire [7:0] lb_dout;
assign readData = lb_dout;

// ====================== I2C Memory ======================
reg i2c_rst;    // TODO unused
initial begin
  i2c_rst = 1'b0;
end

localparam TICK_SCALE = $clog2(CLOCK_RATE/(14*BIT_RATE));

i2c_chunk #(
  .initial_file("marble_i2c.dat"),
  .tick_scale(TICK_SCALE)
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
  .scl(i2c_t), // output
  .sda_drive(sda_t), // output
  .sda_sense(sda_i), // input
  .scl_sense(scl_i), // input
  .trig_mode(1'b0), // input
  .rst(i2c_rst), // input
  .intp(1'b0) // input
);

endmodule
