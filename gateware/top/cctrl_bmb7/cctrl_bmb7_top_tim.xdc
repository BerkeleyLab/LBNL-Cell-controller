# Don't check timing across clock domain boundaries
set_false_path -from [get_clocks GTX_REF_312_3_P] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_aurora_8b10b_0_0_multi_gt_i/gt0_system_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK]
set_false_path -from [get_clocks evr_mgt_top_i/evr_mgt_gtx_i/inst/evr_mgt_gtx_i/gt0_evr_mgt_gtx_i/gtxe2_i/RXOUTCLK] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks GTX_REF_125_P] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0]]

create_clock -period 16.000 system_i/Aurora/aurora_8b10b_0/inst/system_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_aurora_8b10b_0_0_multi_gt_i/gt0_system_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK
set_clock_groups -asynchronous -group [get_clocks system_i/Aurora/aurora_8b10b_0/inst/system_aurora_8b10b_0_0_core_i/gt_wrapper_i/system_aurora_8b10b_0_0_multi_gt_i/gt0_system_aurora_8b10b_0_0_i/gtxe2_i/TXOUTCLK] -group [get_clocks -of_objects [get_pins system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0]]