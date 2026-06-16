##################################################################
# CREATE IP floatToDouble
##################################################################

set floatToDouble [create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name floatToDouble]

set_property -dict {
  CONFIG.Operation_Type {Float_to_float}
  CONFIG.A_Precision_Type {Single}
  CONFIG.C_A_Exponent_Width {8}
  CONFIG.C_A_Fraction_Width {24}
  CONFIG.Result_Precision_Type {Double}
  CONFIG.C_Result_Exponent_Width {11}
  CONFIG.C_Result_Fraction_Width {53}
  CONFIG.C_Mult_Usage {No_Usage}
  CONFIG.Flow_Control {NonBlocking}
  CONFIG.Has_RESULT_TREADY {false}
  CONFIG.C_Latency {2}
  CONFIG.C_Rate {1}
} [get_ips floatToDouble]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $floatToDouble

##################################################################

