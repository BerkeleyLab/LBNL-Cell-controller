##################################################################
# CREATE IP ila_td256_s4096_cap
##################################################################

set ila_td256_s4096_cap [create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_td256_s4096_cap]

set_property -dict {
  CONFIG.C_PROBE0_WIDTH {256}
  CONFIG.C_DATA_DEPTH {4096}
  CONFIG.C_EN_STRG_QUAL {1}
  CONFIG.C_PROBE0_MU_CNT {2}
  CONFIG.ALL_PROBE_SAME_MU_CNT {2}
} [get_ips ila_td256_s4096_cap]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $ila_td256_s4096_cap

##################################################################

