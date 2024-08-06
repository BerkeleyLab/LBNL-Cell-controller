# Aurora user clock
create_clock -name clkAuroraUser -period 12.800	[get_pins -filter {REF_PIN_NAME=~*TXOUTCLK} -of_objects [get_cells -hierarchical -filter {NAME =~ *gt_wrapper_i*system_aurora_8b10b_aurora_8b10b_0_0_multi_gt_i*gt0_system_aurora_8b10b_aurora_8b10b_0_0_i*gtxe2_i*}]]
set clkAuroraUser_clk                   [get_clocks clkAuroraUser]
set clkAuroraUser_period                [get_property PERIOD $clkAuroraUser_clk]
