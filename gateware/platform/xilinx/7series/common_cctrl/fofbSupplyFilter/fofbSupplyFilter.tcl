##################################################################
# CREATE IP fofbSupplyFilter
##################################################################

set fofbSupplyFilter [create_ip -name fir_compiler -vendor xilinx.com -library ip -version 7.2 -module_name fofbSupplyFilter]

set current_script [info script]
set script_dir [file dirname [file normalize $current_script]]
set coe_file_path [file join $script_dir "UnitySupplyFilter.coe"]

set_property -dict [list \
  CONFIG.CoefficientSource {COE_File} \
  CONFIG.Coefficient_File $coe_file_path \
  CONFIG.Coefficient_Sets {1} \
  CONFIG.Coefficient_Reload {true} \
  CONFIG.Number_Channels {1} \
  CONFIG.Select_Pattern {All} \
  CONFIG.Number_Paths {1} \
  CONFIG.Sample_Frequency {0.2} \
  CONFIG.Clock_Frequency {100} \
  CONFIG.Coefficient_Sign {Signed} \
  CONFIG.Quantization {Quantize_Only} \
  CONFIG.Coefficient_Width {27} \
  CONFIG.Coefficient_Fractional_Bits {26} \
  CONFIG.Coefficient_Structure {Non_Symmetric} \
  CONFIG.Data_Width {32} \
  CONFIG.Data_Fractional_Bits {0} \
  CONFIG.Output_Rounding_Mode {Truncate_LSBs} \
  CONFIG.Output_Width {48} \
  CONFIG.Filter_Architecture {Systolic_Multiply_Accumulate} \
  CONFIG.Optimization_Goal {Area} \
  CONFIG.Optimization_Selection {None} \
  CONFIG.Optimization_List {None} \
  CONFIG.Data_Buffer_Type {Automatic} \
  CONFIG.Coefficient_Buffer_Type {Automatic} \
  CONFIG.Input_Buffer_Type {Automatic} \
  CONFIG.Output_Buffer_Type {Automatic} \
  CONFIG.Preference_For_Other_Storage {Automatic} \
  CONFIG.ColumnConfig {2} \
  CONFIG.DATA_Has_TLAST {Not_Required} \
  CONFIG.S_DATA_Has_FIFO {false} \
  CONFIG.S_DATA_Has_TUSER {Not_Required} \
  CONFIG.M_DATA_Has_TUSER {Not_Required} \
  CONFIG.Num_Reload_Slots {1} \
] [get_ips fofbSupplyFilter]

set_property -dict {
  GENERATE_SYNTH_CHECKPOINT {1}
} $fofbSupplyFilter

##################################################################

