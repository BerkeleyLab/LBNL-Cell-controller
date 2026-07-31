##################################################################
# CREATE IP timeStampFIFO
##################################################################

set timeStampFIFO [create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name timeStampFIFO]

set_property -dict {
  CONFIG.Fifo_Implementation {Independent_Clocks_Block_RAM}
  CONFIG.Input_Data_Width {72}
  CONFIG.Output_Data_Width {72}
  CONFIG.Use_Embedded_Registers {false}
  CONFIG.Reset_Type {Asynchronous_Reset}
  CONFIG.Full_Flags_Reset_Value {1}
  CONFIG.Full_Threshold_Assert_Value {1021}
  CONFIG.Full_Threshold_Negate_Value {1020}
} [get_ips timeStampFIFO]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $timeStampFIFO

##################################################################

