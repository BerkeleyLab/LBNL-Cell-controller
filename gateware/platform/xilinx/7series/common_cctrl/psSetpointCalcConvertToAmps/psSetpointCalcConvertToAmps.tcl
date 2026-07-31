##################################################################
# CREATE IP psSetpointCalcConvertToAmps
##################################################################

set psSetpointCalcConvertToAmps [create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name psSetpointCalcConvertToAmps]

set_property -dict {
  CONFIG.Operation_Type {Multiply}
  CONFIG.A_Precision_Type {Single}
  CONFIG.C_A_Exponent_Width {8}
  CONFIG.C_A_Fraction_Width {24}
  CONFIG.Result_Precision_Type {Single}
  CONFIG.C_Result_Exponent_Width {8}
  CONFIG.C_Result_Fraction_Width {24}
  CONFIG.C_Mult_Usage {Full_Usage}
  CONFIG.Flow_Control {NonBlocking}
  CONFIG.Has_RESULT_TREADY {false}
  CONFIG.C_Latency {8}
  CONFIG.C_Rate {1}
  CONFIG.Has_A_TLAST {true}
  CONFIG.RESULT_TLAST_Behv {Pass_A_TLAST}
} [get_ips psSetpointCalcConvertToAmps]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $psSetpointCalcConvertToAmps

##################################################################

