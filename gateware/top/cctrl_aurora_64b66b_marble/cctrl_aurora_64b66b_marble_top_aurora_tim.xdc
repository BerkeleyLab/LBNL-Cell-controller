# Aurora user clock. Comes from the PLL, using user_clk from the first Aurora instantiation
set clkAuroraUser_clk                   [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/Aurora/clk_wiz_0/inst/plle2_adv_inst/CLKOUT0}]]
set clkAuroraUser_period                [get_property PERIOD $clkAuroraUser_clk]
