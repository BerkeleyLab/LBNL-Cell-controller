##################################################################
# CREATE IP MappingRam
##################################################################

set MappingRam [create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name MappingRam]

set_property -dict {
  CONFIG.Memory_Type {True_Dual_Port_RAM}
  CONFIG.Write_Depth_A {256}
  CONFIG.Enable_A {Always_Enabled}
  CONFIG.Operating_Mode_B {READ_FIRST}
  CONFIG.Enable_B {Always_Enabled}
  CONFIG.Register_PortB_Output_of_Memory_Primitives {false}
  CONFIG.Port_B_Clock {100}
  CONFIG.Port_B_Write_Rate {50}
  CONFIG.Port_B_Enable_Rate {100}
} [get_ips MappingRam]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $MappingRam

##################################################################

