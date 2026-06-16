##################################################################
# CREATE IP fixToFloat
##################################################################

set fixToFloat [create_ip -name floating_point -vendor xilinx.com -library ip -version 7.1 -module_name fixToFloat]

set_property -dict {
  CONFIG.Operation_Type {Fixed_to_float}
  CONFIG.A_Precision_Type {Int32}
  CONFIG.C_A_Exponent_Width {32}
  CONFIG.C_A_Fraction_Width {0}
  CONFIG.Result_Precision_Type {Single}
  CONFIG.C_Result_Exponent_Width {8}
  CONFIG.C_Result_Fraction_Width {24}
  CONFIG.C_Accum_Msb {32}
  CONFIG.C_Accum_Lsb {-31}
  CONFIG.C_Accum_Input_Msb {32}
  CONFIG.C_Mult_Usage {No_Usage}
  CONFIG.Flow_Control {NonBlocking}
  CONFIG.Has_RESULT_TREADY {false}
  CONFIG.C_Latency {6}
  CONFIG.C_Rate {1}
} [get_ips fixToFloat]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $fixToFloat

##################################################################

