# Mostly copied from:
# https://www.xilinx.com/htmldocs/xilinx2018_1/SDK_Doc/xsct/use_cases/xsdb_run_app_noninteractive_mode.html
# and download_bit.tcl

if { $argc < 2 } {
    puts "Not enough arguments"
    puts "Usage: xsct load_mb.tcl $(hostname) <fw.elf>"
    exit
}

set hostname [file normalize [lindex $argv 0]]
set elffile [file normalize [lindex $argv 1]]

connect -url TCP:$hostname:3121

# Select the target whose name starts with ARM and ends with #0. 
# On Zynq, this selects “ARM Cortex-A9 MPCore #0”

targets -set -filter {name =~ "ARM* #0"}
rst
# TODO - Where to get hdf file? mb_init?
#fpga ZC702_HwPlatform/design_1_wrapper.bit
#loadhw ZC702_HwPlatform/system.hdf
#source ZC702_HwPlatform/ps7_init.tcl
#ps7_init
#mb_init
#ps7_post_config
#dow dhrystone/Debug/dhrystone.elf
dow $elffile
rst

# Set a breakpoint at exit

#bpadd -addr &exit

# Resume execution and block until the core stops (due to breakpoint) 
# or a timeout of 5 sec is reached

#con -block -timeout 5
con
