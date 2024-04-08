# Aurora user clock
create_clock -name clkAuroraUser -period 12.800	 [get_pins -filter {REF_PIN_NAME=~*TXOUTCLK} -of_objects [get_cells -hierarchical -filter {NAME =~ *gt_wrapper_i*system_marble_aurora_8b10b_0_0_multi_gt_i*gt0_system_marble_aurora_8b10b_0_0_i*gtxe2_i*}]]

set_false_path -from [get_clocks clkAuroraGTREF] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_marble_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_marble_aurora_8b10b_0_0_multi_gt_i/gt0_system_marble_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks clkSys] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]]

# Badger clocks (both directions)
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT3]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT3]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT4]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT4]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]

#create_clock -period 16.000 system_i/Aurora/aurora_8b10b_0/inst/system_marble_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_marble_aurora_8b10b_0_0_multi_gt_i/gt0_system_marble_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK
set_clock_groups -asynchronous -group [get_clocks clkAuroraUser] -group [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]

# Frequency counter clocks
# auRefClk = system_i/Aurora/aurora_8b10b_0/inst/IBUFDS_GTE2_CLK1.O
# ethRefClk125
# auroraUserClk = system_i/Aurora/aurora_8b10b_0/inst/clock_module_i/user_clk_buf_i.O
#
# Violated between clk125 and clk_out1_system_marble_clk_wiz_1_0
set_false_path -from [get_clocks clk125] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks clk125]
