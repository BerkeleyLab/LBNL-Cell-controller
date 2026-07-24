HARDWARE = marble
PROJECT_PART = xc7k160tffg676-2
PROJECT_BOARD = none
XILINX_TOOL := VIVADO
FPGA_VENDOR := xilinx
FPGA_PLATFORM := 7series
FPGA_APPLICATION ?= cctrl

CMD_SEP = ;
__THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(__THIS_DIR:/=)

include ../../../dir_list.mk

# Top level design name
TARGET ?= $(FPGA_APPLICATION)_$(HARDWARE)

VENDOR_PLATFORM_DIR = $(PLATFORM_DIR)/$(FPGA_VENDOR)
FPGA_FAMILY_PLATFORM_DIR = $(VENDOR_PLATFORM_DIR)/$(FPGA_PLATFORM)
TARGET_PLATFORM_DIR = $(FPGA_FAMILY_PLATFORM_DIR)/$(FPGA_APPLICATION)

GW_CCTRL_TGT_DIR = $(GW_SYN_DIR)/$(TARGET)
XPR              = $(GW_CCTRL_TGT_DIR)/_xilinx/$(TARGET)_top/$(TARGET)_top.xpr

# Top level bitstream name
all: $(TARGET)_top.bit $(TARGET)_top.mmi

# Search for .v files here
vpath %.v $(DSP_DIR)
vpath %.v $(MODULES_DIR)
vpath %.v $(VENDOR_PLATFORM_DIR)
vpath %.v $(FPGA_FAMILY_PLATFORM_DIR)
vpath %.v $(GW_TOP_COMMON_DIR)
vpath %.v $(BADGER_DIR)
vpath %.v $(PERIPH_DRIVERS_DIR)
vpath %.v $(PERIPH_DRIVERS_DIR)/i2cbridge

TOP_LVL_DIR = ../../top/$(TARGET)

# top-level files go here
vpath %.v $(TOP_LVL_DIR)
vpath %.xdc $(TOP_LVL_DIR)

#.tcl.in and .tcl files can be here too
vpath %.tcl.in $(THIS_DIR)
vpath %.txt.in $(THIS_DIR)
vpath %.tcl $(THIS_DIR)

VIVADO_SYNTH_EXTRA_TCL = prop.tcl ipcores_repos.tcl prio_xci_files.tcl

include $(BUILD_DIR)/top_rules.mk
include $(CELL_COMM_DIR)/top_rules.mk
include $(PLATFORM_DIR)/top_rules.mk

# ignore xilinx primitives
UNISIM_CRAP += -e 'FDP|OBUFT|GTXE2_CHANNEL|GTXE2_COMMON|MMCME2_ADV'

# Top level files for depedency tracking
SYSTEM_TOP_PINS_XDC = $(TARGET)_top_pins.xdc
SYSTEM_TOP_TIM_XDC = $(TARGET)_top_clock_defs.xdc $(TARGET)_top_aurora_tim.xdc $(TARGET)_top_tim.xdc

# ip_cores generation scripts/names

# custom ip_cores that requires packaging
include $(MODULES_DIR)/evr_axi_rules.mk
include $(MODULES_DIR)/axi_lite_generic_reg_rules.mk
include $(MODULES_DIR)/bantamweightUDP_rules.mk
include $(MODULES_DIR)/aggregate_rules.mk
include $(MODULES_DIR)/drp_bridge_rules.mk

# Badger build
RTEFI_CLIENT_LIST = hello.v
include $(BADGER_DIR)/rules.mk

# For iverilog to search for dependencies

# Bedrock directories for searching
VFLAGS_DEP += -y$(DSP_DIR)
VFLAGS_DEP += -y$(FPGA_FAMILY_DIR)
VFLAGS_DEP += -y$(FPGA_FAMILY_DIR)/xilinx
VFLAGS_DEP += -y$(FPGA_FAMILY_DIR)/iserdes
VFLAGS_DEP += -y$(ISERDES_DIR)
VFLAGS_DEP += -y$(XILINX_DIR)
VFLAGS_DEP += -y$(SERIAL_IO_DIR)
VFLAGS_DEP += -y$(PERIPH_DRIVERS_DIR)
VFLAGS_DEP += -y$(PERIPH_DRIVERS_DIR)/i2cbridge
VFLAGS_DEP += -y$(HOMELESS_DIR)
VFLAGS_DEP += -y$(BADGER_DIR)
VFLAGS_DEP += -y$(BADGER_DIR)/tests

# Ethernet core directories for searching
VFLAGS_DEP += -y$(CORE_DIR)
VFLAGS_DEP += -y$(CRC_DIR)

# Local directories for searching
VFLAGS_DEP += -y.
VFLAGS_DEP += -y$(MODULES_DIR)
VFLAGS_DEP += -y$(TOP_LVL_DIR)
VFLAGS_DEP += -y$(GW_TOP_COMMON_DIR)
VFLAGS_DEP += -y$(VENDOR_PLATFORM_DIR)
VFLAGS_DEP += -y$(FPGA_FAMILY_PLATFORM_DIR)
VFLAGS_DEP += -y$(BWUDP_DIR)

# Local directories for include searching
VFLAGS_DEP += -I.
VFLAGS_DEP += -I$(MODULES_DIR)
VFLAGS_DEP += -I$(TOP_LVL_DIR)
VFLAGS_DEP += -I$(GW_TOP_COMMON_DIR)
VFLAGS_DEP += -I$(BWUDP_DIR)

VFLAGS_DEP += $(SYNTH_OPT)
VFLAGS_DEP += -DSIMULATE -g2012 -Y .sv

# Search prerequisites for generated .v/.vh/.vhd/.xdc here
vpath %.v $(BWUDP_DIR)
vpath %.v $(CORE_DIR) $(CRC_DIR)
vpath %.tcl $(GW_SCRIPTS_DIR)
vpath %.sh $(GW_SCRIPTS_DIR)
vpath %.dat $(MODULES_DIR)

# List top level depedencies here. Eveything named .bit will be used as
# a top-level target in top_rules.mk. .v and .sv files will be used as
# prerequisites as well as a system_top.xdc file
$(TARGET)_top.bit: system_top.xdc $(VIVADO_SYNTH_EXTRA_TCL) $(IP_CORES_TCLS) $(IP_CORES_XCIS) $(TOP_LVL_DIR)/$(TARGET)_top.v $(BD_CORE_BDS) iicCommandTable.dat
$(TOP_LVL_DIR)/$(TARGET)_top.v: $(TOP_LVL_DIR)/gitHash.vh $(TOP_LVL_DIR)/aggregate.v $(TOP_LVL_DIR)/gpioIDX.vh $(RTEFI_V) $(IP_CORES_CUSTOM)

$(TARGET)_top.mmi: $(XPR) $(TARGET)_top.bit
	vivado -mode batch -nojou -nolog -source $(GW_SCRIPTS_DIR)/gen_mem_info.tcl -tclargs $< $@

# Generate bundled .xdc from other .xdc. Don't change the order of the
# prerequisites as we need constraints in the order specified
system_top.xdc: $(SYSTEM_TOP_PINS_XDC) $(SYSTEM_TOP_TIM_XDC)
	cat $^ > $@

# Generate firmware date and parameters
%firmwareBuildDate.v: set_firmware_build_date.tcl
	$(VIVADO_CMD) -source $< -tclargs $@

%gitHash.vh: gitHashVerilog.sh
	sh $(GW_SCRIPTS_DIR)/gitHashVerilog.sh > $@

%gpioIDX.vh: $(SW_TGT_DIR)/$(FPGA_APPLICATION)_$(HARDWARE)/gpio.h
	sh $(GW_SCRIPTS_DIR)/createVerilogIDX.sh $^ > $@

ipcores_repos.tcl: ipcores_repos.tcl.in
	sed -e 's|$$DIRS|$(IP_CORES_CUSTOM_TARGET_DIRS)|g' \
		$< > $@

prio_xci_files.tcl: prio_xci_files.tcl.in
	sed -e 's|$$XCI_FILES|ila_td256_s4096_cap.xci|g' \
		$< > $@

# Cleaning rules
include $(CELL_COMM_DIR)/bottom_rules.mk
include $(PLATFORM_DIR)/bottom_rules.mk
include $(BUILD_DIR)/bottom_rules.mk

CLEAN += *.bit
CLEAN += *.bin
CLEAN += *.prm
CLEAN += system_top.xdc
CLEAN += $(TOP_LVL_DIR)/firmwareBuildDate.v
CLEAN += $(TOP_LVL_DIR)/aggregate.v
CLEAN += $(TOP_LVL_DIR)/gpioIDX.vh
CLEAN += $(IP_CORES_CUSTOM)
CLEAN += *.log *.jou *.str
CLEAN += *.xsa
CLEAN += psu_init*
CLEAN += ipcores_repos.tcl
CLEAN += prio_xci_files.tcl
CLEAN += $(TARGET)_top.mmi
CLEAN += $(RTEFI_CLEAN) $(MERGED_FILE)
CLEAN_DIRS +=  _xilinx .Xil .ip_user_files .hbs $(IP_CORES_CUSTOM_TARGET_DIRS)
CLEAN_DIRS += _gen

# Dependency rules for top level. It will include the dependencies for
# the bitstream %.bit and use the stem to list the depedencies for the
# top level named %.v or %.sv
ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
	include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
	include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
