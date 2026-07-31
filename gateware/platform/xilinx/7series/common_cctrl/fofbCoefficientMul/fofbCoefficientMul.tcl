##################################################################
# CREATE IP fofbCoefficientMul
##################################################################

set fofbCoefficientMul [create_ip -name mult_gen -vendor xilinx.com -library ip -version 12.0 -module_name fofbCoefficientMul]

set_property -dict {
  CONFIG.MultType {Parallel_Multiplier}
  CONFIG.PortAWidth {25}
  CONFIG.PortBWidth {32}
  CONFIG.Multiplier_Construction {Use_Mults}
  CONFIG.Use_Custom_Output_Width {true}
  CONFIG.OutputWidthHigh {57}
  CONFIG.OutputWidthLow {16}
  CONFIG.PipeStages {4}
} [get_ips fofbCoefficientMul]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $fofbCoefficientMul

##################################################################

