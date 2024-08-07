# Aurora user clock. Comes from the PLL, using user_clk from the first Aurora instantiation
set clkAuroraUser_clk                   [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/Aurora/clk_wiz_0/inst/plle2_adv_inst/CLKOUT0}]]
set clkAuroraUser_period                [get_property PERIOD $clkAuroraUser_clk]

set clkAuroraUserDiv2_clk               [get_clocks user_clk_i]
set clkAuroraUserDiv2_period            [get_property PERIOD $clkAuroraUserDiv2_clk]

# Aurora 64b clock to 32b clock. Used for Core Status. FIXME
set_max_delay -datapath_only -from $clkAuroraUserDiv2_clk -to $clkAuroraUser_clk $clkAuroraUser_period
set_max_delay -datapath_only -from $clkAuroraUser_clk -to $clkAuroraUserDiv2_clk $clkAuroraUserDiv2_period
