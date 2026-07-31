##################################################################
# CREATE IP fofbPCS_PMA_without_shared_logic
##################################################################

set fofbPCS_PMA_without_shared_logic [create_ip -name gig_ethernet_pcs_pma -vendor xilinx.com -library ip -version 16.2 -module_name fofbPCS_PMA_without_shared_logic]

set_property -dict {
  CONFIG.Management_Interface {false}
} [get_ips fofbPCS_PMA_without_shared_logic]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $fofbPCS_PMA_without_shared_logic

##################################################################

