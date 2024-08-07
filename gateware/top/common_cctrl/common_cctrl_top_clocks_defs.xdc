###########################
# Clock definitions
###########################

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
