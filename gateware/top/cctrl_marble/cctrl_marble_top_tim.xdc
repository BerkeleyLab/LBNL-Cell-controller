# Create this clock first
# Note: other clocks are created in cctrl_marble_top_pins.xdc
#create_clock -name clk62 -period 16.000 system_i/Aurora/aurora_8b10b_0/inst/system_marble_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_marble_aurora_8b10b_0_0_multi_gt_i/gt0_system_marble_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK

# Don't check timing across clock domain boundaries
#set_false_path -from [get_clocks MGT_CLK_1_P] -to [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT3]]
#set_false_path -from [get_clocks clk312] -to [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT3]]
#set_false_path -from [get_clocks DDR_REF_CLK_P] -to [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]]
#set_false_path -from [get_clocks clkSys] -to [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]]
#set_false_path -from [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]] -to [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK]
#set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_marble_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_marble_aurora_8b10b_0_0_multi_gt_i/gt0_system_marble_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK]
#set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks clk62]
#set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]]
#set_false_path -from [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]]
#set_false_path -from [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]]

#set_clock_groups -asynchronous -group [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_marble_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_marble_aurora_8b10b_0_0_multi_gt_i/gt0_system_marble_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK] -group [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]]
#set_clock_groups -asynchronous -group [get_clocks clk62] -group [get_clocks -of_objects [get_pins MMCME2_BASE_inst/CLKOUT0]]

# ======================= Try again
create_clock -name clk62 -period 16.000 system_i/Aurora/aurora_8b10b_0/inst/system_marble_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_marble_aurora_8b10b_0_0_multi_gt_i/gt0_system_marble_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK
set_false_path -from [get_clocks clk312] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_aurora_8b10b_0_0_multi_gt_i/gt0_system_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks clkSys] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]]

# Badger clocks (both directions)
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT3]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT3]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT4]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT4]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]

#create_clock -period 16.000 system_i/Aurora/aurora_8b10b_0/inst/system_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_aurora_8b10b_0_0_multi_gt_i/gt0_system_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK
set_clock_groups -asynchronous -group [get_clocks clk62] -group [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
