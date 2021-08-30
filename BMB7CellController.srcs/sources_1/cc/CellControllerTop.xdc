set_property PACKAGE_PIN E10 [get_ports S6_TO_K7_CLK_1]
set_property IOSTANDARD LVCMOS33 [get_ports S6_TO_K7_CLK_1]

set_property PACKAGE_PIN D8 [get_ports consoleRxD]
set_property PACKAGE_PIN J10 [get_ports consoleTxD]
set_property IOSTANDARD LVCMOS33 [get_ports consoleRxD]
set_property IOSTANDARD LVCMOS33 [get_ports consoleTxD]

set_property PACKAGE_PIN M17 [get_ports {kintexLEDs[0]}]
set_property PACKAGE_PIN L17 [get_ports {kintexLEDs[1]}]
set_property PACKAGE_PIN M16 [get_ports {kintexLEDs[2]}]
set_property PACKAGE_PIN L19 [get_ports {kintexLEDs[3]}]
set_property PACKAGE_PIN L18 [get_ports {kintexLEDs[4]}]
set_property PACKAGE_PIN L20 [get_ports {kintexLEDs[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {kintexLEDs[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {kintexLEDs[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {kintexLEDs[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {kintexLEDs[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {kintexLEDs[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {kintexLEDs[0]}]

set_property PACKAGE_PIN A15 [get_ports QSFP1_LPMODE]
set_property PACKAGE_PIN A14 [get_ports QSFP1_MODSEL_N]
set_property PACKAGE_PIN B15 [get_ports QSFP1_PRESENT_N]
set_property PACKAGE_PIN A12 [get_ports QSFP1_RESET_N]
set_property PACKAGE_PIN A10 [get_ports QSFP2_LPMODE]
set_property PACKAGE_PIN A8 [get_ports QSFP2_MODSEL_N]
set_property PACKAGE_PIN B10 [get_ports QSFP2_PRESENT_N]
set_property PACKAGE_PIN A9 [get_ports QSFP2_RESET_N]
set_property PACKAGE_PIN B14 [get_ports QSFP_SCL]
set_property PACKAGE_PIN B12 [get_ports QSFP_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP1_LPMODE]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP1_MODSEL_N]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP1_PRESENT_N]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP1_RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP2_LPMODE]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP2_MODSEL_N]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP2_PRESENT_N]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP2_RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports QSFP_SDA]
set_property PULLUP true [get_ports QSFP1_MODSEL_N]
set_property PULLUP true [get_ports QSFP1_PRESENT_N]
set_property PULLUP true [get_ports QSFP1_RESET_N]
set_property PULLUP true [get_ports QSFP2_MODSEL_N]
set_property PULLUP true [get_ports QSFP2_PRESENT_N]
set_property PULLUP true [get_ports QSFP2_RESET_N]
set_property PULLUP true [get_ports QSFP_SCL]

set_property PULLUP true [get_ports QSFP_SDA]

# MGT REF0 (SIT9122)
# Bank 116 (GTXE2_COMMON_X0Y1), MGTREFCLK0
set_property PACKAGE_PIN D6 [get_ports GTX_REF_312_3_P]
set_property PACKAGE_PIN D5 [get_ports GTX_REF_312_3_N]
create_clock -period 3.200 -waveform {0.000 1.600} [get_ports GTX_REF_312_3_P]

# MGT REF2 (J4/J28)
# Bank 115 (GTXE2_COMMON_X0Y0), MGTREFCLK0
#set_property PACKAGE_PIN H6 [get_ports GTX_REF_XXX_P]
#set_property PACKAGE_PIN H5 [get_ports GTX_REF_XXX_N]
#create_clock -period 8.000 -waveform {0.000 4.000} [get_ports GTX_REF_XXX_P]

# MGT REF3 (Jitter cleaner)
# Bank 115 (GTXE2_COMMON_X0Y0, MGTREFCLK1
set_property PACKAGE_PIN K6 [get_ports GTX_REF_125_P]
set_property PACKAGE_PIN K5 [get_ports GTX_REF_125_N]
create_clock -period 8.000 -waveform {0.000 4.000} [get_ports GTX_REF_125_P]

set_property PACKAGE_PIN C3 [get_ports {QSFP1_RX_N[0]}]
set_property PACKAGE_PIN C4 [get_ports {QSFP1_RX_P[0]}]
#set_property PACKAGE_PIN B1 [get_ports {QSFP1_TX_N[0]}]
#set_property PACKAGE_PIN B2 [get_ports {QSFP1_TX_P[0]}]

set_property PACKAGE_PIN B5 [get_ports {QSFP1_RX_N[1]}]
set_property PACKAGE_PIN B6 [get_ports {QSFP1_RX_P[1]}]
set_property PACKAGE_PIN A3 [get_ports {QSFP1_TX_N[1]}]
set_property PACKAGE_PIN A4 [get_ports {QSFP1_TX_P[1]}]

set_property PACKAGE_PIN E3 [get_ports {QSFP1_RX_N[2]}]
set_property PACKAGE_PIN E4 [get_ports {QSFP1_RX_P[2]}]
set_property PACKAGE_PIN D1 [get_ports {QSFP1_TX_N[2]}]
set_property PACKAGE_PIN D2 [get_ports {QSFP1_TX_P[2]}]

#set_property PACKAGE_PIN G3 [get_ports {QSFP1_RX_N[3]}]
#set_property PACKAGE_PIN G4 [get_ports {QSFP1_RX_P[3]}]
#set_property PACKAGE_PIN F1 [get_ports {QSFP1_TX_N[3]}]
#set_property PACKAGE_PIN F2 [get_ports {QSFP1_TX_P[3]}]

set_property PACKAGE_PIN L3 [get_ports {QSFP2_RX_N[0]}]
set_property PACKAGE_PIN L4 [get_ports {QSFP2_RX_P[0]}]
set_property PACKAGE_PIN K1 [get_ports {QSFP2_TX_N[0]}]
set_property PACKAGE_PIN K2 [get_ports {QSFP2_TX_P[0]}]

set_property PACKAGE_PIN J3 [get_ports {QSFP2_RX_N[1]}]
set_property PACKAGE_PIN J4 [get_ports {QSFP2_RX_P[1]}]
set_property PACKAGE_PIN H1 [get_ports {QSFP2_TX_N[1]}]
set_property PACKAGE_PIN H2 [get_ports {QSFP2_TX_P[1]}]

set_property PACKAGE_PIN N3 [get_ports {QSFP2_RX_N[2]}]
set_property PACKAGE_PIN N4 [get_ports {QSFP2_RX_P[2]}]
set_property PACKAGE_PIN M1 [get_ports {QSFP2_TX_N[2]}]
set_property PACKAGE_PIN M2 [get_ports {QSFP2_TX_P[2]}]

set_property PACKAGE_PIN R3 [get_ports {QSFP2_RX_N[3]}]
set_property PACKAGE_PIN R4 [get_ports {QSFP2_RX_P[3]}]
set_property PACKAGE_PIN P1 [get_ports {QSFP2_TX_N[3]}]
set_property PACKAGE_PIN P2 [get_ports {QSFP2_TX_P[3]}]

set_property PACKAGE_PIN H9 [get_ports epicsUDPrxData]
set_property PACKAGE_PIN J8 [get_ports epicsUDPtxData]
set_property IOSTANDARD LVCMOS33 [get_ports epicsUDPrxData]
set_property IOSTANDARD LVCMOS33 [get_ports epicsUDPtxData]

set_property PACKAGE_PIN G10 [get_ports spareUDPrxData]
set_property PACKAGE_PIN H8 [get_ports spareUDPtxData]
set_property IOSTANDARD LVCMOS33 [get_ports spareUDPrxData]
set_property IOSTANDARD LVCMOS33 [get_ports spareUDPtxData]

set_property PACKAGE_PIN H11 [get_ports ffbUDPrxData]
set_property PACKAGE_PIN G9 [get_ports ffbUDPtxData]
set_property IOSTANDARD LVCMOS33 [get_ports ffbUDPrxData]
set_property IOSTANDARD LVCMOS33 [get_ports ffbUDPtxData]

set_property PACKAGE_PIN C9 [get_ports SIT9122_ENABLE]
set_property IOSTANDARD LVCMOS33 [get_ports SIT9122_ENABLE]

set_property IOSTANDARD LVCMOS25 [get_ports PILOT_TONE_I2C_SCL]
set_property IOSTANDARD LVCMOS25 [get_ports PILOT_TONE_I2C_SDA]
set_property PACKAGE_PIN C21 [get_ports PILOT_TONE_I2C_SCL]
set_property PACKAGE_PIN B21 [get_ports PILOT_TONE_I2C_SDA]
set_property PULLUP true [get_ports PILOT_TONE_I2C_SCL]
set_property PULLUP true [get_ports PILOT_TONE_I2C_SDA]

set_property IOSTANDARD LVCMOS25 [get_ports INTLK_RELAY_CTL]
set_property IOSTANDARD LVCMOS25 [get_ports INTLK_RELAY_NO]
set_property IOSTANDARD LVCMOS25 [get_ports INTLK_RESET_BUTTON_N]
set_property PACKAGE_PIN C22 [get_ports INTLK_RELAY_CTL]
set_property PACKAGE_PIN D21 [get_ports INTLK_RELAY_NO]
set_property PACKAGE_PIN H23 [get_ports INTLK_RESET_BUTTON_N]
set_property PULLUP true [get_ports INTLK_RESET_BUTTON_N]

set_property IOSTANDARD LVDS_25 [get_ports PILOT_TONE_REFCLK_P]
set_property PACKAGE_PIN R21 [get_ports PILOT_TONE_REFCLK_P]

set_property IOSTANDARD LVCMOS25 [get_ports FP_LED0_RED]
set_property IOSTANDARD LVCMOS25 [get_ports FP_LED0_GRN]
set_property IOSTANDARD LVCMOS25 [get_ports FP_LED1_RED]
set_property IOSTANDARD LVCMOS25 [get_ports FP_LED1_GRN]
set_property IOSTANDARD LVCMOS25 [get_ports FP_LED2_RED]
set_property IOSTANDARD LVCMOS25 [get_ports FP_LED2_GRN]
set_property IOSTANDARD LVCMOS25 [get_ports FP_TEST_POINT]
set_property PACKAGE_PIN A25 [get_ports FP_LED0_RED]
set_property PACKAGE_PIN B24 [get_ports FP_LED0_GRN]
set_property PACKAGE_PIN C26 [get_ports FP_LED1_RED]
set_property PACKAGE_PIN D26 [get_ports FP_LED1_GRN]
set_property PACKAGE_PIN J26 [get_ports FP_LED2_RED]
set_property PACKAGE_PIN H26 [get_ports FP_LED2_GRN]
set_property PACKAGE_PIN H24 [get_ports FP_TEST_POINT]


############################################################################
# Don't check timing across clock domain boundaries
set_false_path -from [get_clocks GTX_REF_312_3_P] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_aurora_8b10b_0_0_multi_gt_i/gt0_system_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks GTX_REF_125_P] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]]







































