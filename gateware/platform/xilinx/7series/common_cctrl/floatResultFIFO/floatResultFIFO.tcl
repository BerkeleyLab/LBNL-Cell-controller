##################################################################
# CREATE IP floatResultFIFO
##################################################################

set floatResultFIFO [create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name floatResultFIFO]

set_property -dict {
  CONFIG.INTERFACE_TYPE {Native}
  CONFIG.Input_Data_Width {64}
  CONFIG.Input_Depth {512}
  CONFIG.Output_Data_Width {64}
  CONFIG.Output_Depth {512}
  CONFIG.Reset_Pin {true}
  CONFIG.Reset_Type {Synchronous_Reset}
  CONFIG.Full_Flags_Reset_Value {0}
  CONFIG.Use_Dout_Reset {true}
  CONFIG.Data_Count_Width {9}
  CONFIG.Write_Data_Count_Width {9}
  CONFIG.Read_Data_Count_Width {9}
  CONFIG.Full_Threshold_Assert_Value {510}
  CONFIG.Full_Threshold_Negate_Value {509}
  CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM}
  CONFIG.Full_Threshold_Assert_Value_wach {1023}
  CONFIG.Empty_Threshold_Assert_Value_wach {1022}
  CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM}
  CONFIG.Full_Threshold_Assert_Value_wrch {1023}
  CONFIG.Empty_Threshold_Assert_Value_wrch {1022}
  CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM}
  CONFIG.Full_Threshold_Assert_Value_rach {1023}
  CONFIG.Empty_Threshold_Assert_Value_rach {1022}
} [get_ips floatResultFIFO]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $floatResultFIFO

##################################################################

