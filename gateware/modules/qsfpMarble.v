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
`ifndef SIMULERP
  // I2C physical pins
  ,inout                           SCL,
  inout                           SDA,
  output                          scl_mon,
  output                          sda_mon,
  // Diagnostic led should blink if program is running (and program
  // sets/clearn hw_config)
`ifdef QSFP_DEBUG_BUS
  input                           freeze,       // i2c_chunk freeze
  output                          run_stat,     // i2c_chunk run status
  output                          updated,      // i2c_chunk updated flag
  input                           bus_claim,
  input [11:0]                    lb_addr,
  input  [7:0]                    lb_din,
  output [7:0]                    lb_dout,
  input                           lb_write,
  input                           run_cmd,
`endif
  output                          led,
  output                          busmux_reset
`endif
);

// ====================== GPIO bus ========================
wire [7:0] ro = readAddress[7:0];
// I'm being annoyingly generic here.  There are only 2 QSFPs on marble.
wire [$clog2(QSFP_COUNT)-1:0] rqsfp = readAddress[$clog2(QSFP_COUNT)+7:8];  // QSFP number 0 or 1

`include "marble_i2c.vh"
`include "qsfp_memory.vh"

// NOTE! Logic only works in descending order!
wire [9:0] offset_decoded_1 = 
  (ro >= QSFP_DATE_CODE_OFFSET) ? ro - QSFP_DATE_CODE_OFFSET + QSFP1_DATE_CODE :
  (ro >= QSFP_SERIAL_NUMBER_OFFSET) ? ro - QSFP_SERIAL_NUMBER_OFFSET + QSFP1_SER_NUM :
  (ro >= QSFP_WAVELENGTH_OFFSET) ? ro - QSFP_WAVELENGTH_OFFSET + QSFP1_WAVELENGTH :
  (ro >= QSFP_REVISION_CODE_OFFSET) ? ro - QSFP_REVISION_CODE_OFFSET + QSFP1_REVISION_CODE :
  (ro >= QSFP_PART_NAME_OFFSET) ? ro - QSFP_PART_NAME_OFFSET + QSFP1_PART_NAME :
  (ro >= QSFP_VENDOR_NAME_OFFSET) ? ro - QSFP_VENDOR_NAME_OFFSET + QSFP1_VENDOR_NAME :
  (ro >= QSFP_IDENTIFIER_OFFSET) ? ro - QSFP_IDENTIFIER_OFFSET + QSFP1_IDENTIFIER :
  (ro >= QSFP_RXPOWER_0_OFFSET) ? ro - QSFP_RXPOWER_0_OFFSET + QSFP1_RXPOWER :
  (ro >= QSFP_VSUPPLY_OFFSET) ? ro - QSFP_VSUPPLY_OFFSET + QSFP1_VSUPPLY :
  (ro >= QSFP_TEMPERATURE_OFFSET) ? ro - QSFP_TEMPERATURE_OFFSET + QSFP1_TEMPERATURE :
  (ro >= QSFP_MODULE_STATUS_OFFSET) ? ro - QSFP_MODULE_STATUS_OFFSET + QSFP1_MODULE_STATUS :
  (ro >= QSFP_OVERRIDE_PRESENT) ? ro - QSFP_OVERRIDE_PRESENT + U34_PORT_DATA :
  10'h0;

// QSFP2 memory has fixed offset from QSFP1 memory
// In the weird case of U34_PORT_DATA, we want an additional offset of 1 instead,
// (since U34 port0 connects to QSFP1 and port1 connects to QSFP2)
wire [9:0] offset_decoded = (rqsfp == 0) ? offset_decoded_1 : 
  (ro >= QSFP_OVERRIDE_PRESENT) & (ro < QSFP_OVERRIDE_PRESENT + U34_PORT_DATA_SIZE) ?
  ro - QSFP_OVERRIDE_PRESENT + U34_PORT_DATA_SIZE + 1 : offset_decoded_1 + QSFP2_VENDOR_NAME-QSFP1_VENDOR_NAME;

// ====================== I2C pins ========================
`ifndef SIMULERP
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
`ifdef SIMULERP
wire [11:0] i2c_lb_addr = I2C_CHUNK_RESULTS_OFFSET | offset_decoded;
assign readData = ram[i2c_lb_addr];
`else
`ifdef QSFP_DEBUG_BUS
wire [11:0] i2c_lb_addr = bus_claim ? lb_addr : I2C_CHUNK_RESULTS_OFFSET | offset_decoded;
assign readData = lb_dout;
`endif // QSFP_DEBUG_BUS
`endif // SIMULERP
// ====================== I2C Memory ======================
localparam TICK_SCALE = $clog2(CLOCK_RATE/(14*BIT_RATE));

// Annoyingly, i2c_chunk needs to see a rising edge on run_cmd to actually
// start.  Not compatible with a constant 1'b1
// This gives 3 clk cycles of 0 at startup followed by 1 clk cycle of 1
`ifndef SIMULERP
wire [3:0] i2c_hw_config;
reg [1:0] i2c_starter;
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
  .rst(1'b0), // input
  .intp(1'b0) // input
);
`else
reg [7:0] ram [0:'h1000];
initial begin
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+0]  = "q";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+1]  = "s";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+2]  = "f";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+3]  = "p";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+4]  = ".";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+5]  = "c";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+6]  = "o";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+7]  = "m";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+8]  = " ";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+9]  = "p";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+10] = "a";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+11] = "r";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+12] = "t";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+13] = "y";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+14] = 0;
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_VENDOR_NAME+15] = 0;

  ram[I2C_CHUNK_RESULTS_OFFSET+U34_PORT_DATA]    = 8'h47;
  ram[I2C_CHUNK_RESULTS_OFFSET+U34_PORT_DATA+1]  = 8'h77;

  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+0]  = "T";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+1]  = "H";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+2]  = "A";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+3]  = "T";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+4]  = "-";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+5]  = "O";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+6]  = "L";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+7]  = " ";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+8]  = "Q";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+9]  = "S";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+10] = "F";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+11] = "P";
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+12] = 0;
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+13] = 0;
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+14] = 0;
  ram[I2C_CHUNK_RESULTS_OFFSET+QSFP1_PART_NAME+15] = 0;
end

always @(posedge clk) begin
end
`endif

endmodule

