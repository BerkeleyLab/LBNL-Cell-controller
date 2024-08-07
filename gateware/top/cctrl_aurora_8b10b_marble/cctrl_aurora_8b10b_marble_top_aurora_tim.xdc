# Aurora user clock. Comes from the first Aurora instantiation
set clkAuroraUser_clk                   [get_clocks -of_objects [get_pins -hier -filter {NAME =~ *system_i/Aurora/aurora_8b10b_0/user_clk_out}]]
set clkAuroraUser_period                [get_property PERIOD $clkAuroraUser_clk]
