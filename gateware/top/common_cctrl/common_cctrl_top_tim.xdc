#############################################################
# Inter clock exceptions
#############################################################
#
set_max_delay -datapath_only -from $clkAuroraRef_clk -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $CLKOUT0_clk -to $EVRRXOUTCLK_clk $EVRRXOUTCLK_period

set_max_delay -datapath_only -from $EVRRXOUTCLK_clk -to $EVRTXOUTCLK_clk $EVRTXOUTCLK_period

set_max_delay -datapath_only -from $EVRRXOUTCLK_clk -to $CLKOUT0_clk $CLKOUT0_period

set_max_delay -datapath_only -from $EVRRXOUTCLK_clk -to $clkAuroraUser_clk $clkAuroraUser_period

set_max_delay -datapath_only -from [get_clocks clkDDRRef] -to $CLKOUT0_clk $CLKOUT0_period

set_max_delay -datapath_only -from $FOFBETHCLK_clk -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $CLKOUT0_clk -to $FOFBETHCLK_clk $FOFBETHCLK_period

# System clock registers to FOFB ethernet
set_max_delay -datapath_only -from $CLKOUT0_clk -to $clk125_clk $clk125_period

# Badger clocks (both directions)
set_max_delay -datapath_only -from $CLKOUT0_clk -to $CLKOUT3_clk $CLKOUT3_period
set_max_delay -datapath_only -from $CLKOUT3_clk -to $CLKOUT0_clk $CLKOUT0_period

set_max_delay -datapath_only -from $CLKOUT0_clk -to $CLKOUT4_clk $CLKOUT4_period
set_max_delay -datapath_only -from $CLKOUT4_clk -to $CLKOUT0_clk $CLKOUT0_period

# Aurora to/from System clock
set_max_delay -datapath_only -from $clkAuroraUser_clk -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $CLKOUT0_clk -to $clkAuroraUser_clk $clkAuroraUser_period

# Frequency counter clocks
set_max_delay -datapath_only -from $clk125_clk -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $EVRTXOUTCLK_clk -to $CLKOUT0_clk $CLKOUT0_period
set_max_delay -datapath_only -from $clkEVRRef_clk -to $CLKOUT0_clk $CLKOUT0_period
