# Aurora user clock
create_clock -name clkAuroraUser -period 12.800	 [get_pins -filter {REF_PIN_NAME=~*TXOUTCLK} -of_objects [get_cells -hierarchical -filter {NAME =~ *gt_wrapper_i*system_aurora_8b10b_0_0_multi_gt_i*gt0_system_aurora_8b10b_0_0_i*gtxe2_i*}]]
set clkAuroraUser_period                [get_property PERIOD [get_clocks clkAuroraUser]]

# system MMCM clocks
set CLKOUT0_clk                         [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT0}]]
set CLKOUT0_period                      [get_property PERIOD $CLKOUT0_clk]

set CLKOUT1_clk                         [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT1}]]
set CLKOUT1_period                      [get_property PERIOD $CLKOUT1_clk]

set CLKOUT2_clk                         [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT2}]]
set CLKOUT2_period                      [get_property PERIOD $CLKOUT2_clk]

set CLKOUT3_clk                         [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT3}]]
set CLKOUT3_period                      [get_property PERIOD $CLKOUT3_clk]

set CLKOUT4_clk                         [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/clk_wiz_1/inst/mmcm_adv_inst/CLKOUT4}]]
set CLKOUT4_period                      [get_property PERIOD $CLKOUT4_clk]

# EVR clocks
set EVRRXOUTCLK_clk                     [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *evrmgt_i/inst/evrmgt_i/gt0_evrmgt_i/gtxe2_i/RXOUTCLK}]]
set EVRRXOUTCLK_period                  [get_property PERIOD $EVRRXOUTCLK_clk]

set EVRTXOUTCLK_clk                     [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *evrmgt_i/inst/evrmgt_i/gt0_evrmgt_i/gtxe2_i/TXOUTCLK}]]
set EVRTXOUTCLK_period                  [get_property PERIOD $EVRTXOUTCLK_clk]

# FOFB Ethernet clocks
set FOFBETHCLK_clk                      [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *psTx/PCS_PMA/inst/core_clocking_i/mmcm_adv_inst/CLKOUT0}]]
set FOFBETHCLK_period                   [get_property PERIOD $FOFBETHCLK_clk]

#############################################################
# Inter clock exceptions
#############################################################
#
set_max_delay -datapath_only -from [get_clocks clkAuroraGTREF] -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $CLKOUT0_clk -to $EVRRXOUTCLK_clk $EVRRXOUTCLK_period

set_max_delay -datapath_only -from $EVRRXOUTCLK_clk -to $EVRTXOUTCLK_clk $EVRTXOUTCLK_period

set_max_delay -datapath_only -from $EVRRXOUTCLK_clk -to $CLKOUT0_clk $CLKOUT0_period

set_max_delay -datapath_only -from [get_clocks clkDDRRef] -to $CLKOUT0_clk $CLKOUT0_period

set_max_delay -datapath_only -from $FOFBETHCLK_clk -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $CLKOUT0_clk -to $FOFBETHCLK_clk $FOFBETHCLK_period

# System clock registers to FOFB ethernet
set_max_delay -datapath_only -from $CLKOUT0_clk -to [get_clocks clk125] $clk125_period

# Badger clocks (both directions)
set_max_delay -datapath_only -from $CLKOUT0_clk -to $CLKOUT3_clk $CLKOUT3_period
set_max_delay -datapath_only -from $CLKOUT3_clk -to $CLKOUT0_clk $CLKOUT0_period

set_max_delay -datapath_only -from $CLKOUT0_clk -to $CLKOUT4_clk $CLKOUT4_period
set_max_delay -datapath_only -from $CLKOUT4_clk -to $CLKOUT0_clk $CLKOUT0_period

# Aurora to/from System clock
set_max_delay -datapath_only -from [get_clocks clkAuroraUser] -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $CLKOUT0_clk -to [get_clocks clkAuroraUser] $clkAuroraUser_period

# Frequency counter clocks
set_max_delay -datapath_only -from [get_clocks clk125] -to $CLKOUT0_clk $CLKOUT0_period
