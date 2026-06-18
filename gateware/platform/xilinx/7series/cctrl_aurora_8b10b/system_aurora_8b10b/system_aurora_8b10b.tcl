
################################################################
# This is a generated script based on design: system_aurora_8b10b
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2022.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source system_aurora_8b10b_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7k160tffg676-2
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name system_aurora_8b10b

# This script was generated for a remote BD. To create a non-remote design,
# change the variable <run_remote_bd_flow> to <0>.

set run_remote_bd_flow 1
if { $run_remote_bd_flow == 1 } {
  # Set the reference directory for source file relative paths (by default
  # the value is script directory path)
  set origin_dir .

  # Use origin directory path location variable, if specified in the tcl shell
  if { [info exists ::origin_dir_loc] } {
     set origin_dir $::origin_dir_loc
  }

  set str_bd_folder [file normalize ${origin_dir}]
  set str_bd_filepath ${str_bd_folder}/${design_name}/${design_name}.bd

  # Check if remote design exists on disk
  if { [file exists $str_bd_filepath ] == 1 } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2030 -severity "ERROR" "The remote BD file path <$str_bd_filepath> already exists!"}
     common::send_gid_msg -ssname BD::TCL -id 2031 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0>."
     common::send_gid_msg -ssname BD::TCL -id 2032 -severity "INFO" "Also make sure there is no design <$design_name> existing in your current project."

     return 1
  }

  # Check if design exists in memory
  set list_existing_designs [get_bd_designs -quiet $design_name]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2033 -severity "ERROR" "The design <$design_name> already exists in this project! Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2034 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Check if design exists on disk within project
  set list_existing_designs [get_files -quiet */${design_name}.bd]
  if { $list_existing_designs ne "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2035 -severity "ERROR" "The design <$design_name> already exists in this project at location:
    $list_existing_designs"}
     catch {common::send_gid_msg -ssname BD::TCL -id 2036 -severity "ERROR" "Will not create the remote BD <$design_name> at the folder <$str_bd_folder>."}

     common::send_gid_msg -ssname BD::TCL -id 2037 -severity "INFO" "To create a non-remote BD, change the variable <run_remote_bd_flow> to <0> or please set a different value to variable <design_name>."

     return 1
  }

  # Now can create the remote BD
  # NOTE - usage of <-dir> will create <$str_bd_folder/$design_name/$design_name.bd>
  create_bd_design -dir $str_bd_folder $design_name
} else {

  # Create regular design
  if { [catch {create_bd_design $design_name} errmsg] } {
     common::send_gid_msg -ssname BD::TCL -id 2038 -severity "INFO" "Please set a different value to variable <design_name>."

     return 1
  }
}

current_bd_design $design_name

  # Add USER_COMMENTS on $design_name
  set_property USER_COMMENTS.comment_0 "Dummy UART is needed to force
console stdin/stdout instantiation." [get_bd_designs $design_name]
set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\
xilinx.com:ip:axi_bram_ctrl:4.1\
xilinx.com:ip:axi_uartlite:2.0\
xilinx.com:ip:xlconstant:1.1\
lbl.gov:user:axi_lite_generic_reg:2.0\
xilinx.com:ip:clk_wiz:6.0\
lbl.gov:user:evr_axi:3.1\
xilinx.com:ip:axi_hwicap:3.0\
xilinx.com:ip:axi_gpio:2.0\
xilinx.com:ip:mdm:3.2\
xilinx.com:ip:microblaze:11.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xadc_wiz:3.3\
xilinx.com:ip:aurora_8b10b:11.1\
xilinx.com:ip:axis_data_fifo:2.0\
xilinx.com:user:drp_bridge:1.0\
xilinx.com:ip:util_vector_logic:2.0\
xilinx.com:ip:lmb_bram_if_cntlr:4.0\
xilinx.com:ip:blk_mem_gen:8.4\
xilinx.com:ip:lmb_v10:3.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################


# Hierarchical cell: microblaze_0_local_memory
proc create_hier_cell_microblaze_0_local_memory { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_microblaze_0_local_memory() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 DLMB

  create_bd_intf_pin -mode MirroredMaster -vlnv xilinx.com:interface:lmb_rtl:1.0 ILMB


  # Create pins
  create_bd_pin -dir I -type clk LMB_Clk
  create_bd_pin -dir I -from 0 -to 0 -type rst LMB_Rst

  # Create instance: dlmb_bram_if_cntlr, and set properties
  set dlmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 dlmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $dlmb_bram_if_cntlr

  # Create instance: dlmb_bram_if_cntlr_bram, and set properties
  set dlmb_bram_if_cntlr_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 dlmb_bram_if_cntlr_bram ]
  set_property -dict [ list \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $dlmb_bram_if_cntlr_bram

  # Create instance: dlmb_v10, and set properties
  set dlmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 dlmb_v10 ]

  # Create instance: ilmb_bram_if_cntlr, and set properties
  set ilmb_bram_if_cntlr [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_bram_if_cntlr:4.0 ilmb_bram_if_cntlr ]
  set_property -dict [ list \
   CONFIG.C_ECC {0} \
 ] $ilmb_bram_if_cntlr

  # Create instance: ilmb_v10, and set properties
  set ilmb_v10 [ create_bd_cell -type ip -vlnv xilinx.com:ip:lmb_v10:3.0 ilmb_v10 ]

  # Create interface connections
  connect_bd_intf_net -intf_net dlmb_bram_if_cntlr_BRAM_PORT [get_bd_intf_pins dlmb_bram_if_cntlr/BRAM_PORT] [get_bd_intf_pins dlmb_bram_if_cntlr_bram/BRAM_PORTA]
  connect_bd_intf_net -intf_net ilmb_bram_if_cntlr_BRAM_PORT [get_bd_intf_pins dlmb_bram_if_cntlr_bram/BRAM_PORTB] [get_bd_intf_pins ilmb_bram_if_cntlr/BRAM_PORT]
  connect_bd_intf_net -intf_net microblaze_0_dlmb [get_bd_intf_pins DLMB] [get_bd_intf_pins dlmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_bus [get_bd_intf_pins dlmb_bram_if_cntlr/SLMB] [get_bd_intf_pins dlmb_v10/LMB_Sl_0]
  connect_bd_intf_net -intf_net microblaze_0_ilmb [get_bd_intf_pins ILMB] [get_bd_intf_pins ilmb_v10/LMB_M]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_bus [get_bd_intf_pins ilmb_bram_if_cntlr/SLMB] [get_bd_intf_pins ilmb_v10/LMB_Sl_0]

  # Create port connections
  connect_bd_net -net microblaze_0_Clk [get_bd_pins LMB_Clk] [get_bd_pins dlmb_bram_if_cntlr/LMB_Clk] [get_bd_pins dlmb_v10/LMB_Clk] [get_bd_pins ilmb_bram_if_cntlr/LMB_Clk] [get_bd_pins ilmb_v10/LMB_Clk]
  connect_bd_net -net microblaze_0_LMB_Rst [get_bd_pins LMB_Rst] [get_bd_pins dlmb_bram_if_cntlr/LMB_Rst] [get_bd_pins dlmb_v10/SYS_Rst] [get_bd_pins ilmb_bram_if_cntlr/LMB_Rst] [get_bd_pins ilmb_v10/SYS_Rst]

  # Restore current instance
  current_bd_instance $oldCurInst
}

# Hierarchical cell: Aurora
proc create_hier_cell_Aurora { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2092 -severity "ERROR" "create_hier_cell_Aurora() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CORE_STATUS

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CORE_STATUS1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CORE_STATUS2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CORE_STATUS3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CORE_TEST_STATUS

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 GT_DIFF_REFCLK_125

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 GT_SERIAL_RX

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 GT_SERIAL_RX1

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 GT_SERIAL_RX2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 GT_SERIAL_RX3

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 GT_SERIAL_TX

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 GT_SERIAL_TX1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 GT_SERIAL_TX2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 GT_SERIAL_TX3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 GT_TEST_SERIAL_RX

  create_bd_intf_pin -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 GT_TEST_SERIAL_TX

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 S_AXI

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 TEST_DATA_S_AXI_TX

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 USER_DATA_M_AXI_RX

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 USER_DATA_M_AXI_RX1

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 USER_DATA_M_AXI_RX2

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 USER_DATA_M_AXI_RX3

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 USER_DATA_S_AXI_TX2

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 USER_DATA_S_AXI_TX3


  # Create pins
  create_bd_pin -dir I -type clk AXI_aclk
  create_bd_pin -dir I -from 0 -to 0 -type rst AXI_aresetn
  create_bd_pin -dir O -type clk auroraRefClk
  create_bd_pin -dir I -type rst auroraReset
  create_bd_pin -dir O gt0_qplllock_out
  create_bd_pin -dir O gt0_qpllrefclklost_out
  create_bd_pin -dir I -type rst gtxReset
  create_bd_pin -dir O -type rst gtxResetOut
  create_bd_pin -dir I -type clk init_clk_in
  create_bd_pin -dir O pll_not_locked_out
  create_bd_pin -dir O -type clk user_clk_out

  # Create instance: aurora_8b10b_0, and set properties
  set aurora_8b10b_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_8b10b:11.1 aurora_8b10b_0 ]
  set_property -dict [ list \
   CONFIG.C_DRP_IF {true} \
   CONFIG.C_GT_CLOCK_1 {GTXQ1} \
   CONFIG.C_GT_LOC_1 {X} \
   CONFIG.C_GT_LOC_4 {X} \
   CONFIG.C_GT_LOC_5 {X} \
   CONFIG.C_GT_LOC_7 {X} \
   CONFIG.C_GT_LOC_8 {1} \
   CONFIG.C_LANE_WIDTH {4} \
   CONFIG.C_LINE_RATE {3.125} \
   CONFIG.C_REFCLK_FREQUENCY {125.000} \
   CONFIG.C_USE_BYTESWAP {false} \
   CONFIG.C_USE_CRC {true} \
   CONFIG.Dataflow_Config {Duplex} \
   CONFIG.SINGLEEND_INITCLK {true} \
   CONFIG.SupportLevel {1} \
 ] $aurora_8b10b_0

  # Create instance: aurora_8b10b_1, and set properties
  set aurora_8b10b_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_8b10b:11.1 aurora_8b10b_1 ]
  set_property -dict [ list \
   CONFIG.C_DRP_IF {true} \
   CONFIG.C_GT_CLOCK_1 {GTXQ1} \
   CONFIG.C_GT_LOC_1 {X} \
   CONFIG.C_GT_LOC_2 {X} \
   CONFIG.C_GT_LOC_3 {X} \
   CONFIG.C_GT_LOC_4 {X} \
   CONFIG.C_GT_LOC_6 {1} \
   CONFIG.C_GT_LOC_7 {X} \
   CONFIG.C_GT_LOC_8 {X} \
   CONFIG.C_LANE_WIDTH {4} \
   CONFIG.C_LINE_RATE {3.125} \
   CONFIG.C_REFCLK_FREQUENCY {125.000} \
   CONFIG.C_USE_BYTESWAP {false} \
   CONFIG.C_USE_CRC {true} \
   CONFIG.Dataflow_Config {Duplex} \
 ] $aurora_8b10b_1

  # Create instance: aurora_8b10b_2, and set properties
  set aurora_8b10b_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_8b10b:11.1 aurora_8b10b_2 ]
  set_property -dict [ list \
   CONFIG.C_DRP_IF {true} \
   CONFIG.C_GT_CLOCK_1 {GTXQ0} \
   CONFIG.C_GT_LOC_1 {X} \
   CONFIG.C_GT_LOC_2 {X} \
   CONFIG.C_GT_LOC_3 {1} \
   CONFIG.C_GT_LOC_4 {X} \
   CONFIG.C_GT_LOC_7 {X} \
   CONFIG.C_GT_LOC_8 {X} \
   CONFIG.C_LANE_WIDTH {4} \
   CONFIG.C_LINE_RATE {3.125} \
   CONFIG.C_REFCLK_FREQUENCY {125.000} \
   CONFIG.C_USE_BYTESWAP {false} \
   CONFIG.C_USE_CRC {true} \
 ] $aurora_8b10b_2

  # Create instance: aurora_8b10b_3, and set properties
  set aurora_8b10b_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_8b10b:11.1 aurora_8b10b_3 ]
  set_property -dict [ list \
   CONFIG.C_DRP_IF {true} \
   CONFIG.C_GT_CLOCK_1 {GTXQ0} \
   CONFIG.C_GT_LOC_1 {X} \
   CONFIG.C_GT_LOC_2 {X} \
   CONFIG.C_GT_LOC_3 {X} \
   CONFIG.C_GT_LOC_4 {1} \
   CONFIG.C_GT_LOC_7 {X} \
   CONFIG.C_GT_LOC_8 {X} \
   CONFIG.C_LANE_WIDTH {4} \
   CONFIG.C_LINE_RATE {3.125} \
   CONFIG.C_REFCLK_FREQUENCY {125.000} \
   CONFIG.C_USE_BYTESWAP {false} \
   CONFIG.C_USE_CRC {true} \
 ] $aurora_8b10b_3

  # Create instance: aurora_8b10b_4, and set properties
  set aurora_8b10b_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_8b10b:11.1 aurora_8b10b_4 ]
  set_property -dict [ list \
   CONFIG.C_DRP_IF {true} \
   CONFIG.C_GT_CLOCK_1 {GTXQ0} \
   CONFIG.C_GT_LOC_1 {X} \
   CONFIG.C_GT_LOC_2 {X} \
   CONFIG.C_GT_LOC_3 {X} \
   CONFIG.C_GT_LOC_4 {1} \
   CONFIG.C_GT_LOC_7 {X} \
   CONFIG.C_GT_LOC_8 {X} \
   CONFIG.C_LANE_WIDTH {4} \
   CONFIG.C_LINE_RATE {3.125} \
   CONFIG.C_REFCLK_FREQUENCY {125.000} \
   CONFIG.C_USE_BYTESWAP {false} \
   CONFIG.C_USE_CRC {true} \
 ] $aurora_8b10b_4

  # Create instance: axis_data_fifo_2, and set properties
  set axis_data_fifo_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_2 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {256} \
   CONFIG.FIFO_MODE {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.IS_ACLK_ASYNC {0} \
 ] $axis_data_fifo_2

  # Create instance: axis_data_fifo_3, and set properties
  set axis_data_fifo_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_3 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {256} \
   CONFIG.FIFO_MODE {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.IS_ACLK_ASYNC {0} \
 ] $axis_data_fifo_3

  # Create instance: axis_data_fifo_4, and set properties
  set axis_data_fifo_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_4 ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {256} \
   CONFIG.FIFO_MODE {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.IS_ACLK_ASYNC {0} \
 ] $axis_data_fifo_4

  # Create instance: drp_bridge_0, and set properties
  set drp_bridge_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:drp_bridge:1.0 drp_bridge_0 ]
  set_property -dict [ list \
   CONFIG.DRP_COUNT {5} \
 ] $drp_bridge_0

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {not} \
   CONFIG.C_SIZE {1} \
 ] $util_vector_logic_0

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins USER_DATA_M_AXI_RX] [get_bd_intf_pins aurora_8b10b_0/USER_DATA_M_AXI_RX]
  connect_bd_intf_net -intf_net Conn2 [get_bd_intf_pins USER_DATA_M_AXI_RX1] [get_bd_intf_pins aurora_8b10b_1/USER_DATA_M_AXI_RX]
  connect_bd_intf_net -intf_net Conn3 [get_bd_intf_pins USER_DATA_M_AXI_RX2] [get_bd_intf_pins aurora_8b10b_2/USER_DATA_M_AXI_RX]
  connect_bd_intf_net -intf_net Conn4 [get_bd_intf_pins USER_DATA_M_AXI_RX3] [get_bd_intf_pins aurora_8b10b_3/USER_DATA_M_AXI_RX]
  connect_bd_intf_net -intf_net Conn5 [get_bd_intf_pins GT_SERIAL_TX] [get_bd_intf_pins aurora_8b10b_0/GT_SERIAL_TX]
  connect_bd_intf_net -intf_net Conn6 [get_bd_intf_pins GT_SERIAL_TX1] [get_bd_intf_pins aurora_8b10b_1/GT_SERIAL_TX]
  connect_bd_intf_net -intf_net Conn7 [get_bd_intf_pins GT_SERIAL_TX2] [get_bd_intf_pins aurora_8b10b_2/GT_SERIAL_TX]
  connect_bd_intf_net -intf_net Conn8 [get_bd_intf_pins GT_SERIAL_TX3] [get_bd_intf_pins aurora_8b10b_3/GT_SERIAL_TX]
  connect_bd_intf_net -intf_net Conn9 [get_bd_intf_pins S_AXI] [get_bd_intf_pins drp_bridge_0/S_AXI]
  connect_bd_intf_net -intf_net GT_REFCLK1_1 [get_bd_intf_pins GT_DIFF_REFCLK_125] [get_bd_intf_pins aurora_8b10b_0/GT_DIFF_REFCLK1]
  connect_bd_intf_net -intf_net GT_SERIAL_RX1_1 [get_bd_intf_pins GT_SERIAL_RX1] [get_bd_intf_pins aurora_8b10b_1/GT_SERIAL_RX]
  connect_bd_intf_net -intf_net GT_SERIAL_RX2_1 [get_bd_intf_pins GT_SERIAL_RX2] [get_bd_intf_pins aurora_8b10b_2/GT_SERIAL_RX]
  connect_bd_intf_net -intf_net GT_SERIAL_RX3_1 [get_bd_intf_pins GT_SERIAL_RX3] [get_bd_intf_pins aurora_8b10b_3/GT_SERIAL_RX]
  connect_bd_intf_net -intf_net GT_SERIAL_RX_1 [get_bd_intf_pins GT_SERIAL_RX] [get_bd_intf_pins aurora_8b10b_0/GT_SERIAL_RX]
  connect_bd_intf_net -intf_net GT_SERIAL_TEST_DATA_RX_1 [get_bd_intf_pins GT_TEST_SERIAL_RX] [get_bd_intf_pins aurora_8b10b_4/GT_SERIAL_RX]
  connect_bd_intf_net -intf_net TEST_DATA_S_AXI_TX_1 [get_bd_intf_pins TEST_DATA_S_AXI_TX] [get_bd_intf_pins axis_data_fifo_4/S_AXIS]
  connect_bd_intf_net -intf_net USER_DATA_S_AXI_TX2_1 [get_bd_intf_pins USER_DATA_S_AXI_TX2] [get_bd_intf_pins axis_data_fifo_2/S_AXIS]
  connect_bd_intf_net -intf_net USER_DATA_S_AXI_TX3_1 [get_bd_intf_pins USER_DATA_S_AXI_TX3] [get_bd_intf_pins axis_data_fifo_3/S_AXIS]
  connect_bd_intf_net -intf_net aurora_8b10b_0_CORE_STATUS [get_bd_intf_pins CORE_STATUS] [get_bd_intf_pins aurora_8b10b_0/CORE_STATUS]
  connect_bd_intf_net -intf_net aurora_8b10b_1_CORE_STATUS [get_bd_intf_pins CORE_STATUS1] [get_bd_intf_pins aurora_8b10b_1/CORE_STATUS]
  connect_bd_intf_net -intf_net aurora_8b10b_2_CORE_STATUS [get_bd_intf_pins CORE_STATUS2] [get_bd_intf_pins aurora_8b10b_2/CORE_STATUS]
  connect_bd_intf_net -intf_net aurora_8b10b_3_CORE_STATUS [get_bd_intf_pins CORE_STATUS3] [get_bd_intf_pins aurora_8b10b_3/CORE_STATUS]
  connect_bd_intf_net -intf_net aurora_8b10b_4_CORE_STATUS [get_bd_intf_pins CORE_TEST_STATUS] [get_bd_intf_pins aurora_8b10b_4/CORE_STATUS]
  connect_bd_intf_net -intf_net aurora_8b10b_4_GT_SERIAL_TX [get_bd_intf_pins GT_TEST_SERIAL_TX] [get_bd_intf_pins aurora_8b10b_4/GT_SERIAL_TX]
  connect_bd_intf_net -intf_net axis_data_fifo_2_M_AXIS [get_bd_intf_pins aurora_8b10b_2/USER_DATA_S_AXI_TX] [get_bd_intf_pins axis_data_fifo_2/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_3_M_AXIS [get_bd_intf_pins aurora_8b10b_3/USER_DATA_S_AXI_TX] [get_bd_intf_pins axis_data_fifo_3/M_AXIS]
  connect_bd_intf_net -intf_net axis_data_fifo_4_M_AXIS [get_bd_intf_pins aurora_8b10b_4/USER_DATA_S_AXI_TX] [get_bd_intf_pins axis_data_fifo_4/M_AXIS]
  connect_bd_intf_net -intf_net drp_bridge_0_DRP0 [get_bd_intf_pins aurora_8b10b_0/GT0_DRP_IF] [get_bd_intf_pins drp_bridge_0/DRP0]
  connect_bd_intf_net -intf_net drp_bridge_0_DRP1 [get_bd_intf_pins aurora_8b10b_1/GT0_DRP_IF] [get_bd_intf_pins drp_bridge_0/DRP1]
  connect_bd_intf_net -intf_net drp_bridge_0_DRP2 [get_bd_intf_pins aurora_8b10b_2/GT0_DRP_IF] [get_bd_intf_pins drp_bridge_0/DRP2]
  connect_bd_intf_net -intf_net drp_bridge_0_DRP3 [get_bd_intf_pins aurora_8b10b_3/GT0_DRP_IF] [get_bd_intf_pins drp_bridge_0/DRP3]
  connect_bd_intf_net -intf_net drp_bridge_0_DRP4 [get_bd_intf_pins aurora_8b10b_4/GT0_DRP_IF] [get_bd_intf_pins drp_bridge_0/DRP4]

  # Create port connections
  connect_bd_net -net AXI_aclk_1 [get_bd_pins AXI_aclk] [get_bd_pins aurora_8b10b_0/drpclk_in] [get_bd_pins aurora_8b10b_1/drpclk_in] [get_bd_pins aurora_8b10b_2/drpclk_in] [get_bd_pins aurora_8b10b_3/drpclk_in] [get_bd_pins aurora_8b10b_4/drpclk_in] [get_bd_pins drp_bridge_0/AXI_aclk]
  connect_bd_net -net AXI_aresetn_1 [get_bd_pins AXI_aresetn] [get_bd_pins drp_bridge_0/AXI_aresetn]
  connect_bd_net -net aurora_8b10b_0_gt0_qplllock_out [get_bd_pins gt0_qplllock_out] [get_bd_pins aurora_8b10b_0/gt0_qplllock_out] [get_bd_pins aurora_8b10b_1/gt0_qplllock_in] [get_bd_pins aurora_8b10b_2/gt0_qplllock_in] [get_bd_pins aurora_8b10b_3/gt0_qplllock_in]
  connect_bd_net -net aurora_8b10b_0_gt0_qpllrefclklost_out [get_bd_pins gt0_qpllrefclklost_out] [get_bd_pins aurora_8b10b_0/gt0_qpllrefclklost_out] [get_bd_pins aurora_8b10b_1/gt0_qpllrefclklost_in] [get_bd_pins aurora_8b10b_2/gt0_qpllrefclklost_in] [get_bd_pins aurora_8b10b_3/gt0_qpllrefclklost_in]
  connect_bd_net -net aurora_8b10b_0_gt_refclk1_out [get_bd_pins auroraRefClk] [get_bd_pins aurora_8b10b_0/gt_refclk1_out] [get_bd_pins aurora_8b10b_1/gt_refclk1] [get_bd_pins aurora_8b10b_2/gt_refclk1] [get_bd_pins aurora_8b10b_3/gt_refclk1] [get_bd_pins aurora_8b10b_4/gt_refclk1]
  connect_bd_net -net aurora_8b10b_0_gt_reset_out [get_bd_pins gtxResetOut] [get_bd_pins aurora_8b10b_0/gt_reset_out] [get_bd_pins aurora_8b10b_1/gt_reset] [get_bd_pins aurora_8b10b_2/gt_reset] [get_bd_pins aurora_8b10b_3/gt_reset] [get_bd_pins aurora_8b10b_4/gt_reset]
  connect_bd_net -net aurora_8b10b_0_pll_not_locked_out [get_bd_pins pll_not_locked_out] [get_bd_pins aurora_8b10b_0/pll_not_locked_out] [get_bd_pins aurora_8b10b_1/pll_not_locked] [get_bd_pins aurora_8b10b_2/pll_not_locked] [get_bd_pins aurora_8b10b_3/pll_not_locked]
  connect_bd_net -net aurora_8b10b_0_sync_clk_out [get_bd_pins aurora_8b10b_0/sync_clk_out] [get_bd_pins aurora_8b10b_1/sync_clk] [get_bd_pins aurora_8b10b_2/sync_clk] [get_bd_pins aurora_8b10b_3/sync_clk] [get_bd_pins aurora_8b10b_4/sync_clk]
  connect_bd_net -net aurora_8b10b_0_user_clk_out [get_bd_pins user_clk_out] [get_bd_pins aurora_8b10b_0/user_clk_out] [get_bd_pins aurora_8b10b_1/user_clk] [get_bd_pins aurora_8b10b_2/user_clk] [get_bd_pins aurora_8b10b_3/user_clk] [get_bd_pins aurora_8b10b_4/user_clk] [get_bd_pins axis_data_fifo_2/s_axis_aclk] [get_bd_pins axis_data_fifo_3/s_axis_aclk] [get_bd_pins axis_data_fifo_4/s_axis_aclk]
  connect_bd_net -net gt_reset_1 [get_bd_pins gtxReset] [get_bd_pins aurora_8b10b_0/gt_reset]
  connect_bd_net -net init_clk_in_1 [get_bd_pins init_clk_in] [get_bd_pins aurora_8b10b_0/init_clk_in] [get_bd_pins aurora_8b10b_1/init_clk_in] [get_bd_pins aurora_8b10b_2/init_clk_in] [get_bd_pins aurora_8b10b_3/init_clk_in] [get_bd_pins aurora_8b10b_4/init_clk_in]
  connect_bd_net -net reset_1 [get_bd_pins auroraReset] [get_bd_pins aurora_8b10b_0/reset] [get_bd_pins aurora_8b10b_1/reset] [get_bd_pins aurora_8b10b_2/reset] [get_bd_pins aurora_8b10b_3/reset] [get_bd_pins aurora_8b10b_4/reset] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins axis_data_fifo_2/s_axis_aresetn] [get_bd_pins axis_data_fifo_3/s_axis_aresetn] [get_bd_pins axis_data_fifo_4/s_axis_aresetn] [get_bd_pins util_vector_logic_0/Res]

  # Restore current instance
  current_bd_instance $oldCurInst
}


# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set BPM_CCW_AXI_STREAM_RX [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 BPM_CCW_AXI_STREAM_RX ]

  set BPM_CCW_AuroraCoreStatus [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 BPM_CCW_AuroraCoreStatus ]

  set BPM_CCW_GT_RX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 BPM_CCW_GT_RX ]

  set BPM_CCW_GT_TX [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 BPM_CCW_GT_TX ]

  set BPM_CW_AXI_STREAM_RX [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 BPM_CW_AXI_STREAM_RX ]

  set BPM_CW_AuroraCoreStatus [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 BPM_CW_AuroraCoreStatus ]

  set BPM_CW_GT_RX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 BPM_CW_GT_RX ]

  set BPM_CW_GT_TX [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 BPM_CW_GT_TX ]

  set BPM_TEST_AXI_STREAM_TX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 BPM_TEST_AXI_STREAM_TX ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $BPM_TEST_AXI_STREAM_TX

  set BPM_TEST_AuroraCoreStatus [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 BPM_TEST_AuroraCoreStatus ]

  set BPM_TEST_GT_RX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 BPM_TEST_GT_RX ]

  set BPM_TEST_GT_TX [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 BPM_TEST_GT_TX ]

  set CELL_CCW_AXI_STREAM_RX [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 CELL_CCW_AXI_STREAM_RX ]

  set CELL_CCW_AXI_STREAM_TX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 CELL_CCW_AXI_STREAM_TX ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $CELL_CCW_AXI_STREAM_TX

  set CELL_CCW_AuroraCoreStatus [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CELL_CCW_AuroraCoreStatus ]

  set CELL_CCW_GT_RX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 CELL_CCW_GT_RX ]

  set CELL_CCW_GT_TX [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 CELL_CCW_GT_TX ]

  set CELL_CW_AXI_STREAM_RX [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 CELL_CW_AXI_STREAM_RX ]

  set CELL_CW_AXI_STREAM_TX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 CELL_CW_AXI_STREAM_TX ]
  set_property -dict [ list \
   CONFIG.HAS_TKEEP {0} \
   CONFIG.HAS_TLAST {0} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {4} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $CELL_CW_AXI_STREAM_TX

  set CELL_CW_AuroraCoreStatus [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:core_status_out_rtl:1.0 CELL_CW_AuroraCoreStatus ]

  set CELL_CW_GT_RX [ create_bd_intf_port -mode Slave -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_RX_rtl:1.0 CELL_CW_GT_RX ]

  set CELL_CW_GT_TX [ create_bd_intf_port -mode Master -vlnv xilinx.com:display_aurora:GT_Serial_Transceiver_Pins_TX_rtl:1.0 CELL_CW_GT_TX ]

  set GT_DIFF_REFCLK_125 [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 GT_DIFF_REFCLK_125 ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {125000000} \
   ] $GT_DIFF_REFCLK_125

  set iic_proc_gpio [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 iic_proc_gpio ]

  set uart_rtl [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart_rtl ]


  # Create ports
  set BRAM_BPM_SETPOINTS_ADDR [ create_bd_port -dir O -from 12 -to 0 BRAM_BPM_SETPOINTS_ADDR ]
  set BRAM_BPM_SETPOINTS_RDATA [ create_bd_port -dir I -from 31 -to 0 BRAM_BPM_SETPOINTS_RDATA ]
  set BRAM_BPM_SETPOINTS_WDATA [ create_bd_port -dir O -from 31 -to 0 BRAM_BPM_SETPOINTS_WDATA ]
  set BRAM_BPM_SETPOINTS_WENABLE [ create_bd_port -dir O -from 3 -to 0 BRAM_BPM_SETPOINTS_WENABLE ]
  set GPIO_IN [ create_bd_port -dir I -from 4095 -to 0 GPIO_IN ]
  set GPIO_OUT [ create_bd_port -dir O -from 31 -to 0 GPIO_OUT ]
  set GPIO_STROBES [ create_bd_port -dir O -from 127 -to 0 GPIO_STROBES ]
  set auroraRefClk [ create_bd_port -dir O -type clk auroraRefClk ]
  set auroraReset [ create_bd_port -dir I -type rst auroraReset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $auroraReset
  set auroraUserClk [ create_bd_port -dir O -type clk auroraUserClk ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {BPM_CCW_AXI_STREAM_RX:BPM_CW_AXI_STREAM_RX:CELL_CCW_AXI_STREAM_RX:CELL_CW_AXI_STREAM_RX:CELL_CCW_AXI_STREAM_TX:CELL_CW_AXI_STREAM_TX} \
   CONFIG.ASSOCIATED_RESET {auroraReset_CELL_CCW:auroraReset_BPM_CW:gtxReset_BPM_CW:auroraReset_CELL_CW:gtxReset_CELL_CW:auroraReset:auroraReset_AXI:gtxReset:gtxReset_CELL_CCW} \
 ] $auroraUserClk
  set badgerClk125 [ create_bd_port -dir O -type clk badgerClk125 ]
  set badgerClk125d90 [ create_bd_port -dir O -type clk badgerClk125d90 ]
  set clk200 [ create_bd_port -dir O clk200 ]
  set clkIn125 [ create_bd_port -dir I -type clk -freq_hz 125000000 clkIn125 ]
  set_property -dict [ list \
   CONFIG.PHASE {0.000} \
 ] $clkIn125
  set evrCharIsComma [ create_bd_port -dir I -from 1 -to 0 evrCharIsComma ]
  set evrCharIsK [ create_bd_port -dir I -from 1 -to 0 evrCharIsK ]
  set evrChars [ create_bd_port -dir I -from 15 -to 0 evrChars ]
  set evrClk [ create_bd_port -dir I evrClk ]
  set evrDataBus [ create_bd_port -dir O -from 7 -to 0 evrDataBus ]
  set evrMgtResetDone [ create_bd_port -dir I evrMgtResetDone ]
  set evrTimestamp [ create_bd_port -dir O -from 63 -to 0 evrTimestamp ]
  set evrTriggerBus [ create_bd_port -dir O -from 7 -to 0 evrTriggerBus ]
  set gt0_qplllock_out [ create_bd_port -dir O gt0_qplllock_out ]
  set gt0_qpllrefclklost_out [ create_bd_port -dir O gt0_qpllrefclklost_out ]
  set gtxReset [ create_bd_port -dir I -type rst gtxReset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $gtxReset
  set gtxResetOut [ create_bd_port -dir O -type rst gtxResetOut ]
  set pll_not_locked_out [ create_bd_port -dir O pll_not_locked_out ]
  set sysClk [ create_bd_port -dir O -type clk sysClk ]
  set sysReset_n [ create_bd_port -dir O -from 0 -to 0 sysReset_n ]

  # Create instance: Aurora
  create_hier_cell_Aurora [current_bd_instance .] Aurora

  # Create instance: BRAM_BPM_SETPOINTS, and set properties
  set BRAM_BPM_SETPOINTS [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 BRAM_BPM_SETPOINTS ]
  set_property -dict [ list \
   CONFIG.PROTOCOL {AXI4LITE} \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $BRAM_BPM_SETPOINTS

  # Create instance: DummyUART, and set properties
  set DummyUART [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 DummyUART ]

  # Create instance: One, and set properties
  set One [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 One ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {1} \
 ] $One

  # Create instance: Zero, and set properties
  set Zero [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 Zero ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
 ] $Zero

  # Create instance: axi_lite_generic_reg, and set properties
  set axi_lite_generic_reg [ create_bd_cell -type ip -vlnv lbl.gov:user:axi_lite_generic_reg:2.0 axi_lite_generic_reg ]
  set_property -dict [ list \
   CONFIG.C_S00_AXI_ADDR_WIDTH {9} \
 ] $axi_lite_generic_reg

  # Create instance: clk_wiz_1, and set properties
  set clk_wiz_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {80.0} \
   CONFIG.CLKOUT1_JITTER {124.615} \
   CONFIG.CLKOUT1_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT2_JITTER {143.688} \
   CONFIG.CLKOUT2_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {50} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLKOUT3_JITTER {109.241} \
   CONFIG.CLKOUT3_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {200} \
   CONFIG.CLKOUT3_USED {true} \
   CONFIG.CLKOUT4_JITTER {119.348} \
   CONFIG.CLKOUT4_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT4_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.CLKOUT4_USED {true} \
   CONFIG.CLKOUT5_JITTER {119.348} \
   CONFIG.CLKOUT5_PHASE_ERROR {96.948} \
   CONFIG.CLKOUT5_REQUESTED_OUT_FREQ {125.000} \
   CONFIG.CLKOUT5_REQUESTED_PHASE {90.000} \
   CONFIG.CLKOUT5_USED {true} \
   CONFIG.CLKOUT6_JITTER {154.207} \
   CONFIG.CLKOUT6_PHASE_ERROR {164.985} \
   CONFIG.CLKOUT6_REQUESTED_OUT_FREQ {100.000} \
   CONFIG.CLKOUT6_USED {false} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {8.000} \
   CONFIG.MMCM_CLKIN1_PERIOD {8.000} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {10.000} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {20} \
   CONFIG.MMCM_CLKOUT2_DIVIDE {5} \
   CONFIG.MMCM_CLKOUT3_DIVIDE {8} \
   CONFIG.MMCM_CLKOUT4_DIVIDE {8} \
   CONFIG.MMCM_CLKOUT4_PHASE {90.000} \
   CONFIG.MMCM_CLKOUT5_DIVIDE {1} \
   CONFIG.MMCM_DIVCLK_DIVIDE {1} \
   CONFIG.NUM_OUT_CLKS {5} \
   CONFIG.PRIM_IN_FREQ {125.000} \
   CONFIG.PRIM_SOURCE {Global_buffer} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_1

  # Create instance: evr_axi_0, and set properties
  set evr_axi_0 [ create_bd_cell -type ip -vlnv lbl.gov:user:evr_axi:3.1 evr_axi_0 ]
  set_property -dict [ list \
   CONFIG.C_S00_AXI_ADDR_WIDTH {15} \
   CONFIG.C_S00_AXI_ID_WIDTH {12} \
 ] $evr_axi_0

  # Create instance: hwicap, and set properties
  set hwicap [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_hwicap:3.0 hwicap ]

  # Create instance: iic_proc_gpio, and set properties
  set iic_proc_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 iic_proc_gpio ]
  set_property -dict [ list \
   CONFIG.C_GPIO_WIDTH {4} \
 ] $iic_proc_gpio

  # Create instance: mdm_1, and set properties
  set mdm_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm:3.2 mdm_1 ]

  # Create instance: microblaze_0, and set properties
  set microblaze_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0 ]
  set_property -dict [ list \
   CONFIG.C_DEBUG_ENABLED {1} \
   CONFIG.C_D_AXI {1} \
   CONFIG.C_D_LMB {1} \
   CONFIG.C_I_LMB {1} \
   CONFIG.C_USE_BARREL {1} \
   CONFIG.C_USE_BRANCH_TARGET_CACHE {1} \
   CONFIG.C_USE_DCACHE {0} \
   CONFIG.C_USE_DIV {1} \
   CONFIG.C_USE_FPU {0} \
   CONFIG.C_USE_HW_MUL {1} \
   CONFIG.C_USE_ICACHE {0} \
 ] $microblaze_0

  # Create instance: microblaze_0_axi_periph_1, and set properties
  set microblaze_0_axi_periph_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 microblaze_0_axi_periph_1 ]
  set_property -dict [ list \
   CONFIG.NUM_MI {8} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
 ] $microblaze_0_axi_periph_1

  # Create instance: microblaze_0_local_memory
  create_hier_cell_microblaze_0_local_memory [current_bd_instance .] microblaze_0_local_memory

  # Create instance: rst_clk_wiz_1_100M, and set properties
  set rst_clk_wiz_1_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_clk_wiz_1_100M ]

  # Create instance: xadc_wiz_0, and set properties
  set xadc_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz:3.3 xadc_wiz_0 ]
  set_property -dict [ list \
   CONFIG.ADC_CONVERSION_RATE {500} \
   CONFIG.ADC_OFFSET_AND_GAIN_CALIBRATION {true} \
   CONFIG.ADC_OFFSET_CALIBRATION {true} \
   CONFIG.AVERAGE_ENABLE_TEMPERATURE {true} \
   CONFIG.AVERAGE_ENABLE_VBRAM {true} \
   CONFIG.AVERAGE_ENABLE_VCCAUX {true} \
   CONFIG.AVERAGE_ENABLE_VCCINT {true} \
   CONFIG.CHANNEL_AVERAGING {16} \
   CONFIG.CHANNEL_ENABLE_CALIBRATION {true} \
   CONFIG.CHANNEL_ENABLE_TEMPERATURE {true} \
   CONFIG.CHANNEL_ENABLE_VBRAM {true} \
   CONFIG.CHANNEL_ENABLE_VCCAUX {true} \
   CONFIG.CHANNEL_ENABLE_VCCINT {true} \
   CONFIG.CHANNEL_ENABLE_VP_VN {false} \
   CONFIG.ENABLE_RESET {false} \
   CONFIG.ENABLE_TEMP_BUS {false} \
   CONFIG.INTERFACE_SELECTION {Enable_AXI} \
   CONFIG.OT_ALARM {false} \
   CONFIG.POWER_DOWN_ADCB {true} \
   CONFIG.SEQUENCER_MODE {Continuous} \
   CONFIG.USER_TEMP_ALARM {false} \
   CONFIG.VCCAUX_ALARM {false} \
   CONFIG.VCCINT_ALARM {false} \
   CONFIG.XADC_STARUP_SELECTION {channel_sequencer} \
 ] $xadc_wiz_0

  # Create interface connections
  connect_bd_intf_net -intf_net Aurora_CORE_STATUS2 [get_bd_intf_ports CELL_CCW_AuroraCoreStatus] [get_bd_intf_pins Aurora/CORE_STATUS2]
  connect_bd_intf_net -intf_net Aurora_CORE_STATUS3 [get_bd_intf_ports CELL_CW_AuroraCoreStatus] [get_bd_intf_pins Aurora/CORE_STATUS3]
  connect_bd_intf_net -intf_net Aurora_CORE_STATUS_TEST_DATA [get_bd_intf_ports BPM_TEST_AuroraCoreStatus] [get_bd_intf_pins Aurora/CORE_TEST_STATUS]
  connect_bd_intf_net -intf_net Aurora_GT_SERIAL_TEST_DATA_TX [get_bd_intf_ports BPM_TEST_GT_TX] [get_bd_intf_pins Aurora/GT_TEST_SERIAL_TX]
  connect_bd_intf_net -intf_net Aurora_GT_SERIAL_TX2 [get_bd_intf_ports CELL_CCW_GT_TX] [get_bd_intf_pins Aurora/GT_SERIAL_TX2]
  connect_bd_intf_net -intf_net Aurora_GT_SERIAL_TX3 [get_bd_intf_ports CELL_CW_GT_TX] [get_bd_intf_pins Aurora/GT_SERIAL_TX3]
  connect_bd_intf_net -intf_net Aurora_USER_DATA_M_AXI_RX [get_bd_intf_ports BPM_CCW_AXI_STREAM_RX] [get_bd_intf_pins Aurora/USER_DATA_M_AXI_RX]
  connect_bd_intf_net -intf_net Aurora_USER_DATA_M_AXI_RX1 [get_bd_intf_ports BPM_CW_AXI_STREAM_RX] [get_bd_intf_pins Aurora/USER_DATA_M_AXI_RX1]
  connect_bd_intf_net -intf_net Aurora_USER_DATA_M_AXI_RX2 [get_bd_intf_ports CELL_CCW_AXI_STREAM_RX] [get_bd_intf_pins Aurora/USER_DATA_M_AXI_RX2]
  connect_bd_intf_net -intf_net Aurora_USER_DATA_M_AXI_RX3 [get_bd_intf_ports CELL_CW_AXI_STREAM_RX] [get_bd_intf_pins Aurora/USER_DATA_M_AXI_RX3]
  connect_bd_intf_net -intf_net BPM_CCW_GT_RX_1 [get_bd_intf_ports BPM_CCW_GT_RX] [get_bd_intf_pins Aurora/GT_SERIAL_RX]
  connect_bd_intf_net -intf_net BPM_CW_RX_1 [get_bd_intf_ports BPM_CW_GT_RX] [get_bd_intf_pins Aurora/GT_SERIAL_RX1]
  connect_bd_intf_net -intf_net BPM_GT_TEST_DATA_RX_1 [get_bd_intf_ports BPM_TEST_GT_RX] [get_bd_intf_pins Aurora/GT_TEST_SERIAL_RX]
  connect_bd_intf_net -intf_net BPM_TEST_AXI_STREAM_TX_1 [get_bd_intf_ports BPM_TEST_AXI_STREAM_TX] [get_bd_intf_pins Aurora/TEST_DATA_S_AXI_TX]
  connect_bd_intf_net -intf_net CELL_CCW_AXI_STREAM_SLAVE_1 [get_bd_intf_ports CELL_CCW_AXI_STREAM_TX] [get_bd_intf_pins Aurora/USER_DATA_S_AXI_TX2]
  connect_bd_intf_net -intf_net CELL_CCW_GT_RX_1 [get_bd_intf_ports CELL_CCW_GT_RX] [get_bd_intf_pins Aurora/GT_SERIAL_RX2]
  connect_bd_intf_net -intf_net CELL_CW_AXI_STREAM_SLAVE_1 [get_bd_intf_ports CELL_CW_AXI_STREAM_TX] [get_bd_intf_pins Aurora/USER_DATA_S_AXI_TX3]
  connect_bd_intf_net -intf_net CELL_CW_GT_RX_1 [get_bd_intf_ports CELL_CW_GT_RX] [get_bd_intf_pins Aurora/GT_SERIAL_RX3]
  connect_bd_intf_net -intf_net GT_DIFF_REFCLK_125_0_1 [get_bd_intf_ports GT_DIFF_REFCLK_125] [get_bd_intf_pins Aurora/GT_DIFF_REFCLK_125]
  connect_bd_intf_net -intf_net aurora_8b10b_0_CORE_STATUS [get_bd_intf_ports BPM_CW_AuroraCoreStatus] [get_bd_intf_pins Aurora/CORE_STATUS1]
  connect_bd_intf_net -intf_net aurora_8b10b_0_GT_SERIAL_TX [get_bd_intf_ports BPM_CW_GT_TX] [get_bd_intf_pins Aurora/GT_SERIAL_TX1]
  connect_bd_intf_net -intf_net aurora_8b10b_1_CORE_STATUS [get_bd_intf_ports BPM_CCW_AuroraCoreStatus] [get_bd_intf_pins Aurora/CORE_STATUS]
  connect_bd_intf_net -intf_net aurora_8b10b_1_GT_SERIAL_TX [get_bd_intf_ports BPM_CCW_GT_TX] [get_bd_intf_pins Aurora/GT_SERIAL_TX]
  connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports iic_proc_gpio] [get_bd_intf_pins iic_proc_gpio/GPIO]
  connect_bd_intf_net -intf_net axi_uartlite_0_UART [get_bd_intf_ports uart_rtl] [get_bd_intf_pins DummyUART/UART]
  connect_bd_intf_net -intf_net microblaze_0_M_AXI_DP [get_bd_intf_pins microblaze_0/M_AXI_DP] [get_bd_intf_pins microblaze_0_axi_periph_1/S00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M00_AXI [get_bd_intf_pins iic_proc_gpio/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph_1/M00_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M01_AXI [get_bd_intf_pins evr_axi_0/s00_axi] [get_bd_intf_pins microblaze_0_axi_periph_1/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M02_AXI [get_bd_intf_pins microblaze_0_axi_periph_1/M02_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M03_AXI [get_bd_intf_pins axi_lite_generic_reg/s00_axi] [get_bd_intf_pins microblaze_0_axi_periph_1/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M04_AXI [get_bd_intf_pins DummyUART/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph_1/M04_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M05_AXI [get_bd_intf_pins BRAM_BPM_SETPOINTS/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph_1/M05_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M06_AXI [get_bd_intf_pins Aurora/S_AXI] [get_bd_intf_pins microblaze_0_axi_periph_1/M06_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_1_M07_AXI [get_bd_intf_pins hwicap/S_AXI_LITE] [get_bd_intf_pins microblaze_0_axi_periph_1/M07_AXI]
  connect_bd_intf_net -intf_net microblaze_0_debug [get_bd_intf_pins mdm_1/MBDEBUG_0] [get_bd_intf_pins microblaze_0/DEBUG]
  connect_bd_intf_net -intf_net microblaze_0_dlmb_1 [get_bd_intf_pins microblaze_0/DLMB] [get_bd_intf_pins microblaze_0_local_memory/DLMB]
  connect_bd_intf_net -intf_net microblaze_0_ilmb_1 [get_bd_intf_pins microblaze_0/ILMB] [get_bd_intf_pins microblaze_0_local_memory/ILMB]

  # Create port connections
  connect_bd_net -net Aurora_gt0_qplllock_out [get_bd_ports gt0_qplllock_out] [get_bd_pins Aurora/gt0_qplllock_out]
  connect_bd_net -net Aurora_gt0_qpllrefclklost_out [get_bd_ports gt0_qpllrefclklost_out] [get_bd_pins Aurora/gt0_qpllrefclklost_out]
  connect_bd_net -net Aurora_gt_refclk1_out_0 [get_bd_ports auroraRefClk] [get_bd_pins Aurora/auroraRefClk]
  connect_bd_net -net Aurora_gt_reset_out [get_bd_ports gtxResetOut] [get_bd_pins Aurora/gtxResetOut]
  connect_bd_net -net Aurora_pll_not_locked_out [get_bd_ports pll_not_locked_out] [get_bd_pins Aurora/pll_not_locked_out]
  connect_bd_net -net BRAM_BPM_SETPOINTS_RDATA_1 [get_bd_ports BRAM_BPM_SETPOINTS_RDATA] [get_bd_pins BRAM_BPM_SETPOINTS/bram_rddata_a]
  connect_bd_net -net BRAM_BPM_SETPOINTS_bram_addr_a [get_bd_ports BRAM_BPM_SETPOINTS_ADDR] [get_bd_pins BRAM_BPM_SETPOINTS/bram_addr_a]
  connect_bd_net -net BRAM_BPM_SETPOINTS_bram_we_a [get_bd_ports BRAM_BPM_SETPOINTS_WENABLE] [get_bd_pins BRAM_BPM_SETPOINTS/bram_we_a]
  connect_bd_net -net BRAM_BPM_SETPOINTS_bram_wrdata_a [get_bd_ports BRAM_BPM_SETPOINTS_WDATA] [get_bd_pins BRAM_BPM_SETPOINTS/bram_wrdata_a]
  connect_bd_net -net GPIO_IN_1 [get_bd_ports GPIO_IN] [get_bd_pins axi_lite_generic_reg/GPIO_IN]
  connect_bd_net -net Gnd_dout [get_bd_pins One/dout] [get_bd_pins rst_clk_wiz_1_100M/aux_reset_in] [get_bd_pins rst_clk_wiz_1_100M/ext_reset_in]
  connect_bd_net -net Zero_dout [get_bd_pins Zero/dout] [get_bd_pins evr_axi_0/TsRequest]
  connect_bd_net -net aurora_8b10b_0_user_clk_out [get_bd_ports auroraUserClk] [get_bd_pins Aurora/user_clk_out]
  connect_bd_net -net axi_lite_generic_reg_0_GPIO_OUT [get_bd_ports GPIO_OUT] [get_bd_pins axi_lite_generic_reg/GPIO_OUT]
  connect_bd_net -net axi_lite_generic_reg_0_GPIO_STROBES [get_bd_ports GPIO_STROBES] [get_bd_pins axi_lite_generic_reg/GPIO_STROBES]
  connect_bd_net -net clk_wiz_1_clk_out2 [get_bd_pins Aurora/init_clk_in] [get_bd_pins clk_wiz_1/clk_out2]
  connect_bd_net -net clk_wiz_1_clk_out3 [get_bd_ports clk200] [get_bd_pins clk_wiz_1/clk_out3]
  connect_bd_net -net clk_wiz_1_clk_out4 [get_bd_ports badgerClk125] [get_bd_pins clk_wiz_1/clk_out4]
  connect_bd_net -net clk_wiz_1_clk_out5 [get_bd_ports badgerClk125d90] [get_bd_pins clk_wiz_1/clk_out5]
  connect_bd_net -net clk_wiz_1_locked [get_bd_pins clk_wiz_1/locked] [get_bd_pins rst_clk_wiz_1_100M/dcm_locked]
  connect_bd_net -net clock_rtl_1 [get_bd_ports clkIn125] [get_bd_pins clk_wiz_1/clk_in1]
  connect_bd_net -net evr_axi_0_DistributedDataBus [get_bd_ports evrDataBus] [get_bd_pins evr_axi_0/DistributedDataBus]
  connect_bd_net -net evr_axi_0_TimeStamp [get_bd_ports evrTimestamp] [get_bd_pins evr_axi_0/TimeStamp]
  connect_bd_net -net evr_axi_0_TriggerBus [get_bd_ports evrTriggerBus] [get_bd_pins evr_axi_0/TriggerBus]
  connect_bd_net -net gt_reset_1 [get_bd_ports gtxReset] [get_bd_pins Aurora/gtxReset]
  connect_bd_net -net mdm_1_debug_sys_rst [get_bd_pins mdm_1/Debug_SYS_Rst] [get_bd_pins rst_clk_wiz_1_100M/mb_debug_sys_rst]
  connect_bd_net -net mgt_chariscomma_1 [get_bd_ports evrCharIsComma] [get_bd_pins evr_axi_0/mgt_chariscomma]
  connect_bd_net -net mgt_charisk_1 [get_bd_ports evrCharIsK] [get_bd_pins evr_axi_0/mgt_charisk]
  connect_bd_net -net mgt_par_data_1 [get_bd_ports evrChars] [get_bd_pins evr_axi_0/mgt_par_data]
  connect_bd_net -net mgt_rec_clk_1 [get_bd_ports evrClk] [get_bd_pins evr_axi_0/mgt_rec_clk]
  connect_bd_net -net mgt_reset_done_1 [get_bd_ports evrMgtResetDone] [get_bd_pins evr_axi_0/mgt_reset_done]
  connect_bd_net -net microblaze_0_Clk [get_bd_ports sysClk] [get_bd_pins Aurora/AXI_aclk] [get_bd_pins BRAM_BPM_SETPOINTS/s_axi_aclk] [get_bd_pins DummyUART/s_axi_aclk] [get_bd_pins axi_lite_generic_reg/s00_axi_aclk] [get_bd_pins clk_wiz_1/clk_out1] [get_bd_pins evr_axi_0/s00_axi_aclk] [get_bd_pins hwicap/icap_clk] [get_bd_pins hwicap/s_axi_aclk] [get_bd_pins iic_proc_gpio/s_axi_aclk] [get_bd_pins microblaze_0/Clk] [get_bd_pins microblaze_0_axi_periph_1/ACLK] [get_bd_pins microblaze_0_axi_periph_1/M00_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M01_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M02_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M03_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M04_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M05_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M06_ACLK] [get_bd_pins microblaze_0_axi_periph_1/M07_ACLK] [get_bd_pins microblaze_0_axi_periph_1/S00_ACLK] [get_bd_pins microblaze_0_local_memory/LMB_Clk] [get_bd_pins rst_clk_wiz_1_100M/slowest_sync_clk] [get_bd_pins xadc_wiz_0/s_axi_aclk]
  connect_bd_net -net reset_1 [get_bd_ports auroraReset] [get_bd_pins Aurora/auroraReset]
  connect_bd_net -net rst_clk_wiz_1_100M_bus_struct_reset [get_bd_pins microblaze_0_local_memory/LMB_Rst] [get_bd_pins rst_clk_wiz_1_100M/bus_struct_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins microblaze_0_axi_periph_1/ARESETN] [get_bd_pins rst_clk_wiz_1_100M/interconnect_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_mb_reset [get_bd_pins microblaze_0/Reset] [get_bd_pins rst_clk_wiz_1_100M/mb_reset]
  connect_bd_net -net rst_clk_wiz_1_100M_peripheral_aresetn [get_bd_ports sysReset_n] [get_bd_pins Aurora/AXI_aresetn] [get_bd_pins BRAM_BPM_SETPOINTS/s_axi_aresetn] [get_bd_pins DummyUART/s_axi_aresetn] [get_bd_pins axi_lite_generic_reg/s00_axi_aresetn] [get_bd_pins evr_axi_0/s00_axi_aresetn] [get_bd_pins hwicap/s_axi_aresetn] [get_bd_pins iic_proc_gpio/s_axi_aresetn] [get_bd_pins microblaze_0_axi_periph_1/M00_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M01_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M02_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M03_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M04_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M05_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M06_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/M07_ARESETN] [get_bd_pins microblaze_0_axi_periph_1/S00_ARESETN] [get_bd_pins rst_clk_wiz_1_100M/peripheral_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]

  # Create address segments
  assign_bd_address -offset 0xC0000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs BRAM_BPM_SETPOINTS/S_AXI/Mem0] -force
  assign_bd_address -offset 0x40600000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs DummyUART/S_AXI/Reg] -force
  assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs iic_proc_gpio/S_AXI/Reg] -force
  assign_bd_address -offset 0x44A30000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs axi_lite_generic_reg/s00_axi/reg0] -force
  assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs microblaze_0_local_memory/dlmb_bram_if_cntlr/SLMB/Mem] -force
  assign_bd_address -offset 0x44A10000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs Aurora/drp_bridge_0/S_AXI/reg0] -force
  assign_bd_address -offset 0x44A40000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs evr_axi_0/s00_axi/reg0] -force
  assign_bd_address -offset 0x40200000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs hwicap/S_AXI_LITE/Reg] -force
  assign_bd_address -offset 0x44A50000 -range 0x00010000 -target_address_space [get_bd_addr_spaces microblaze_0/Data] [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] -force
  assign_bd_address -offset 0x00000000 -range 0x00020000 -target_address_space [get_bd_addr_spaces microblaze_0/Instruction] [get_bd_addr_segs microblaze_0_local_memory/ilmb_bram_if_cntlr/SLMB/Mem] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


