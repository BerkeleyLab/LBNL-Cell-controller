##################################################################
# CREATE IP linkStatisticsMux
##################################################################

set linkStatisticsMux [create_ip -name axis_interconnect -vendor xilinx.com -library ip -version 1.1 -module_name linkStatisticsMux]

set_property -dict {
  CONFIG.C_NUM_SI_SLOTS {4}
  CONFIG.HAS_TSTRB {false}
  CONFIG.HAS_TKEEP {false}
  CONFIG.HAS_TLAST {false}
  CONFIG.HAS_TID {false}
  CONFIG.HAS_TDEST {false}
  CONFIG.ARBITER_TYPE {Round-Robin}
  CONFIG.SWITCH_PACKET_MODE {false}
  CONFIG.C_SWITCH_MAX_XFERS_PER_ARB {1}
  CONFIG.C_SWITCH_NUM_CYCLES_TIMEOUT {0}
  CONFIG.C_M00_AXIS_IS_ACLK_ASYNC {1}
  CONFIG.M00_AXIS_FIFO_MODE {0_(Disabled)}
  CONFIG.C_S00_AXIS_IS_ACLK_ASYNC {0}
  CONFIG.S00_AXIS_FIFO_MODE {1_(Normal)}
  CONFIG.C_S01_AXIS_IS_ACLK_ASYNC {0}
  CONFIG.S01_AXIS_FIFO_MODE {1_(Normal)}
  CONFIG.C_S02_AXIS_IS_ACLK_ASYNC {1}
  CONFIG.S02_AXIS_FIFO_MODE {1_(Normal)}
  CONFIG.C_S02_AXIS_FIFO_DEPTH {32}
  CONFIG.C_S03_AXIS_IS_ACLK_ASYNC {1}
  CONFIG.S03_AXIS_FIFO_MODE {1_(Normal)}
  CONFIG.C_S04_AXIS_IS_ACLK_ASYNC {1}
  CONFIG.S04_AXIS_FIFO_MODE {1_(Normal)}
  CONFIG.M00_S01_CONNECTIVITY {true}
  CONFIG.M00_S02_CONNECTIVITY {true}
  CONFIG.M00_S03_CONNECTIVITY {true}
  CONFIG.M00_S04_CONNECTIVITY {false}
} [get_ips linkStatisticsMux]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $linkStatisticsMux

##################################################################

