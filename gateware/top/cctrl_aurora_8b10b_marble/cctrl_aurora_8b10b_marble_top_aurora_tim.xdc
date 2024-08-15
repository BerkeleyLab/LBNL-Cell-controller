# Aurora user clock. Comes from the first Aurora instantiation
set clkAuroraUser_clk                   [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/Aurora/aurora_8b10b_0/user_clk_out}]]
set clkAuroraUser_period                [get_property PERIOD $clkAuroraUser_clk]

# Init clock to Aurora user clock. Aurora core status signals
set_max_delay -datapath_only -from $CLKOUT1_clk -to $clkAuroraUser_clk $clkAuroraUser_period
