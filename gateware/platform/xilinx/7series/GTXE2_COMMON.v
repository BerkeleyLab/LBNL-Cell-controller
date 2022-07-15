// Stupid stub for satisfying iverilog
//
module GTXE2_COMMON #(
    parameter [63:0] BIAS_CFG = 64'h0000040000001000,
    parameter [31:0] COMMON_CFG = 32'h00000000,
    parameter [0:0] IS_DRPCLK_INVERTED = 1'b0,
    parameter [0:0] IS_GTGREFCLK_INVERTED = 1'b0,
    parameter [0:0] IS_QPLLLOCKDETCLK_INVERTED = 1'b0,
    parameter [26:0] QPLL_CFG = 27'h0680181,
    parameter [3:0] QPLL_CLKOUT_CFG = 4'b0000,
    parameter [5:0] QPLL_COARSE_FREQ_OVRD = 6'b010000,
    parameter [0:0] QPLL_COARSE_FREQ_OVRD_EN = 1'b0,
    parameter [9:0] QPLL_CP = 10'b0000011111,
    parameter [0:0] QPLL_CP_MONITOR_EN = 1'b0,
    parameter [0:0] QPLL_DMONITOR_SEL = 1'b0,
    parameter [9:0] QPLL_FBDIV = 10'b0000000000,
    parameter [0:0] QPLL_FBDIV_MONITOR_EN = 1'b0,
    parameter [0:0] QPLL_FBDIV_RATIO = 1'b0,
    parameter [23:0] QPLL_INIT_CFG = 24'h000006,
    parameter [15:0] QPLL_LOCK_CFG = 16'h21E8,
    parameter [3:0] QPLL_LPF = 4'b1111,
    parameter integer QPLL_REFCLK_DIV = 2,
    parameter [2:0] SIM_QPLLREFCLK_SEL = 3'b001,
    parameter SIM_RESET_SPEEDUP = "TRUE",
    parameter SIM_VERSION = "4.0"

) (
    output DRPRDY,
    output QPLLFBCLKLOST,
    output QPLLLOCK,
    output QPLLOUTCLK,
    output QPLLOUTREFCLK,
    output QPLLREFCLKLOST,
    output REFCLKOUTMONITOR,
    output [15:0] DRPDO,
    output [7:0] QPLLDMONITOR,

    input BGBYPASSB,
    input BGMONITORENB,
    input BGPDB,
    input DRPCLK,
    input DRPEN,
    input DRPWE,
    input GTGREFCLK,
    input GTNORTHREFCLK0,
    input GTNORTHREFCLK1,
    input GTREFCLK0,
    input GTREFCLK1,
    input GTSOUTHREFCLK0,
    input GTSOUTHREFCLK1,
    input QPLLLOCKDETCLK,
    input QPLLLOCKEN,
    input QPLLOUTRESET,
    input QPLLPD,
    input QPLLRESET,
    input RCALENB,
    input [15:0] DRPDI,
    input [15:0] QPLLRSVD1,
    input [2:0] QPLLREFCLKSEL,
    input [4:0] BGRCALOVRD,
    input [4:0] QPLLRSVD2,
    input [7:0] DRPADDR,
    input [7:0] PMARSVD
);

assign DRPRDY = 1'b0;
assign QPLLFBCLKLOST = 1'b0;
assign QPLLLOCK = 1'b0;
assign QPLLOUTCLK = 1'b0;
assign QPLLOUTREFCLK = 1'b0;
assign QPLLREFCLKLOST = 1'b0;
assign REFCLKOUTMONITOR = 1'b0;
assign DRPDO = 0;
assign QPLLDMONITOR = 0;

endmodule
