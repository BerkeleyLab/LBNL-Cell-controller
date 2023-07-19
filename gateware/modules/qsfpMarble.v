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
*/

module qsfpMarble #(
  parameter QSFP_COUNT  = 2,
  parameter CLOCK_RATE  = 100000000,
  parameter BIT_RATE    = 100000
  )(
  input                           clk,
  // Bus interface
  input  [$clog2(QSFP_COUNT)+7:0] readAddress,  // QSFP register to read
  output                    [7:0] readData      // Data read from QSFP register
`ifndef SIMULATE
  // I2C physical pins
  ,inout                           SCL,
  inout                           SDA,
  output                          scl_mon,
  output                          sda_mon,
  // Diagnostic led should blink if program is running (and program
  // sets/clearn hw_config)
//`ifdef QSFP_DEBUG_BUS
  input                           freeze,       // i2c_chunk freeze
  output                          run_stat,     // i2c_chunk run status
  output                          updated,      // i2c_chunk updated flag
  input                           bus_claim,
  input [11:0]                    lb_addr,
  input  [7:0]                    lb_din,
  output [7:0]                    lb_dout,
  input                           lb_write,
  input                           run_cmd,
  output                          led,
  output                          busmux_reset,
  output                          i2c_run_cmd_out // debug
//`endif
`endif
);

// ====================== GPIO bus ========================
wire [7:0] roffset = readAddress[7:0];
// I'm being annoyingly generic here.  There are only 2 QSFPs on marble.
wire [$clog2(QSFP_COUNT)-1:0] rqsfp = readAddress[$clog2(QSFP_COUNT)+7:8];  // QSFP number 0 or 1

`include "marble_i2c.vh"
`include "qsfp_memory.vh"
wire [9:0] offset_decoded = (rqsfp == 0) && (roffset == QSFP_OVERRIDE_PRESENT) ? U34_PORT_DATA :
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
                            (rqsfp == 1) && (roffset == QSFP_OVERRIDE_PRESENT) ? U34_PORT_DATA+1:
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
`ifndef SIMULATE
wire scl_t;
wire scl_i;
//IOBUF iobuf_scl(.T(scl_t), .I(1'b0), .O(scl_i), .IO(SCL));
assign SCL = scl_t == 1'b1 ? 1'bZ : 1'b0;
assign scl_i = SCL;
assign scl_mon = scl_i;
wire sda_t;
wire sda_i;
//IOBUF iobuf_sda(.T(sda_t), .I(1'b0), .O(sda_i), .IO(SDA));
assign SDA = sda_t == 1'b1 ? 1'bZ : 1'b0;
assign sda_i = SDA;
assign sda_mon = sda_i;
`endif

// ====================== Localbus ========================
localparam I2C_CHUNK_RESULTS_OFFSET = 12'h800;
//`ifdef QSFP_DEBUG_BUS
`ifdef SIMULATE
wire [11:0] i2c_lb_addr = I2C_CHUNK_RESULTS_OFFSET | offset_decoded;
assign readData = ram[i2c_lb_addr];
`else
wire [11:0] i2c_lb_addr = bus_claim ? lb_addr : I2C_CHUNK_RESULTS_OFFSET | offset_decoded;
assign readData = lb_dout;
`endif
//`else
/*
wire [7:0] lb_dout;
wire [7:0] lb_din = 8'h00;
wire lb_write = 1'b0;
wire [11:0] i2c_lb_addr = I2C_CHUNK_RESULTS_OFFSET | offset_decoded;
wire run_cmd = 1'b1;
//`endif
*/

// ====================== I2C Memory ======================
reg i2c_rst;    // TODO unused
initial begin
  i2c_rst = 1'b0;
end

localparam TICK_SCALE = $clog2(CLOCK_RATE/(14*BIT_RATE));

// Annoyingly, i2c_chunk needs to see a rising edge on run_cmd to actually
// start.  Not compatible with a constant 1'b1
// This gives 3 clk cycles of 0 at startup followed by 1 clk cycle of 1
`ifndef SIMULATE
wire [3:0] i2c_hw_config;
reg [1:0] i2c_starter;
assign i2c_run_cmd_out = i2c_run_cmd;
initial begin
  i2c_starter = 0;
end
always @(posedge clk) begin
  if (~(&i2c_starter)) i2c_starter <= i2c_starter + 1;
end
assign led = i2c_hw_config[0];
assign busmux_reset = i2c_hw_config[1];
wire i2c_run_cmd = run_cmd & (&i2c_starter);
i2c_chunk #(
  .initial_file("marble_i2c.dat"),
  .tick_scale(TICK_SCALE)
  ) i2c_chunk_i (
  .clk(clk), // input
  .lb_addr(i2c_lb_addr), // input [11:0]
  .lb_din(lb_din), // input [7:0]
  .lb_write(lb_write), // input
  .lb_dout(lb_dout), // output [7:0]
  .run_cmd(i2c_run_cmd), // input
  .trace_cmd(1'b0), // input
  .freeze(freeze), // input
  .run_stat(run_stat), // output
  .analyze_armed(), // output
  .analyze_run(), // output
  .updated(updated), // output
  .err_flag(), // output
  .hw_config(i2c_hw_config), // output [3:0]
  .scl(scl_t), // output
  .sda_drive(sda_t), // output
  .sda_sense(sda_i), // input
  .scl_sense(scl_i), // input
  .trig_mode(1'b0), // input
  .rst(i2c_rst), // input
  .intp(1'b0) // input
);
`else
reg [7:0] ram [0:'h1000];
initial begin
  ram[QSFP1_VENDOR_NAME+0]  = "q";
  ram[QSFP1_VENDOR_NAME+1]  = "s";
  ram[QSFP1_VENDOR_NAME+2]  = "f";
  ram[QSFP1_VENDOR_NAME+3]  = "p";
  ram[QSFP1_VENDOR_NAME+4]  = ".";
  ram[QSFP1_VENDOR_NAME+5]  = "c";
  ram[QSFP1_VENDOR_NAME+6]  = "o";
  ram[QSFP1_VENDOR_NAME+7]  = "m";
  ram[QSFP1_VENDOR_NAME+8]  = " ";
  ram[QSFP1_VENDOR_NAME+9]  = "p";
  ram[QSFP1_VENDOR_NAME+10] = "a";
  ram[QSFP1_VENDOR_NAME+11] = "r";
  ram[QSFP1_VENDOR_NAME+12] = "t";
  ram[QSFP1_VENDOR_NAME+13] = "y";
  ram[QSFP1_VENDOR_NAME+14] = 0;
  ram[QSFP1_VENDOR_NAME+15] = 0;

  ram[U34_PORT_DATA]    = 8'h47;
  ram[U34_PORT_DATA+1]  = 8'h77;

  ram[QSFP1_PART_NAME+0]  = "T";
  ram[QSFP1_PART_NAME+1]  = "H";
  ram[QSFP1_PART_NAME+2]  = "A";
  ram[QSFP1_PART_NAME+3]  = "T";
  ram[QSFP1_PART_NAME+4]  = "-";
  ram[QSFP1_PART_NAME+5]  = "O";
  ram[QSFP1_PART_NAME+6]  = "L";
  ram[QSFP1_PART_NAME+7]  = " ";
  ram[QSFP1_PART_NAME+8]  = "Q";
  ram[QSFP1_PART_NAME+9]  = "S";
  ram[QSFP1_PART_NAME+10] = "F";
  ram[QSFP1_PART_NAME+11] = "P";
  ram[QSFP1_PART_NAME+12] = 0;
  ram[QSFP1_PART_NAME+13] = 0;
  ram[QSFP1_PART_NAME+14] = 0;
  ram[QSFP1_PART_NAME+15] = 0;
end

always @(posedge clk) begin
end
`endif

endmodule
