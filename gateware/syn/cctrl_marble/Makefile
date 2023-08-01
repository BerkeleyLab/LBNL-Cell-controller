HARDWARE = marble
PROJECT_PART = xc7k160tffg676-2
PROJECT_BOARD = none
XILINX_TOOL := VIVADO
FPGA_VENDOR := xilinx
FPGA_PLATFORM := 7series
FPGA_APPLICATION := cctrl

CMD_SEP = ;

include ../../../dir_list.mk

# Top level design name
TARGET ?= $(FPGA_APPLICATION)_$(HARDWARE)

GW_CCTRL_TGT_DIR = $(GW_SYN_DIR)/$(TARGET)
XPR              = $(GW_CCTRL_TGT_DIR)/_xilinx/$(TARGET)_top/$(TARGET)_top.xpr

# Top level bitstream name
all: $(TARGET)_top.bit $(TARGET)_top.mmi

# Search for .v files here
vpath %.v $(DSP_DIR)
vpath %.v $(MODULES_DIR)

TOP_LVL_DIR = ../../top/$(TARGET)

# top-level files go here
vpath %.v $(TOP_LVL_DIR)
vpath %.xdc $(TOP_LVL_DIR)

VIVADO_SYNTH_EXTRA_TCL = prop.tcl ipcores_repos.tcl prio_xci_files.tcl

GPIOIDX_V = gpioIDX.vh

I2C_VH=$(MODULES_DIR)/marble_i2c.vh
VERILOG_AUTOGEN = $(I2C_VH)
include $(BUILD_DIR)/top_rules.mk

# ignore xilinx primitives
UNISIM_CRAP += -e 'FDP|OBUFT|GTXE2_CHANNEL|GTXE2_COMMON|MMCME2_ADV'

# Top level files for depedency tracking
SYSTEM_TOP_PINS_XDC = $(TARGET)_top_pins.xdc
SYSTEM_TOP_TIM_XDC = $(TARGET)_top_tim.xdc

# ip_cores generation scripts/names

# custom ip_cores that requires packaging
include $(MODULES_DIR)/evr_axi_rules.mk
include $(MODULES_DIR)/axi_lite_generic_reg_rules.mk
include $(MODULES_DIR)/badger_rules.mk
include $(MODULES_DIR)/drp_bridge_rules.mk

IP_CORES += evr_mgt_gtx fixToFloat floatMultiply floatResultFIFO floatToDouble fofbCoefficientMul fofbFIRplusIntegral fofbFixToFloat fofbGainMultiplier fofbIntegralFixToFloat fofbIntegralMultiplier fofbPCS_PMA_with_shared_logic fofbPCS_PMA_without_shared_logic fofbReadLinksMux fofbSupplyFilter forwardCellLinkMux linkStatisticsMux psSetpointCalcConvertToAmps psSetpointCalcFixToFloat readBPMlinksMux readOldBPMs_DoubleToFloat readOldBPMs_FIFO readOldBPMs_Fix readOldBPMs_Multiply ila_td256_s4096_cap
evr_mgt_gtx_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/evr_mgt_gtx
evr_mgt_gtx_TOP = $(evr_mgt_gtx_DIR)/evr_mgt_gtx.v
fixToFloat_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fixToFloat
fixToFloat_TOP = $(fixToFloat_DIR)/synth/fixToFloat.v
floatMultiply_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/floatMultiply
floatMultiply_TOP = $(floatMultiply_DIR)/synth/floatMultiply.v
floatResultFIFO_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/floatResultFIFO
floatResultFIFO_TOP = $(floatResultFIFO_DIR)/synth/floatResultFIFO.vhd
floatToDouble_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/floatToDouble
floatToDouble_TOP = $(floatToDouble_DIR)/synth/floatToDouble.v
fofbCoefficientMul_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbCoefficientMul
fofbCoefficientMul_TOP = $(fofbCoefficientMul_DIR)/synth/fofbCoefficientMul.vhd
fofbFIRplusIntegral_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbFIRplusIntegral
fofbFIRplusIntegral_TOP = $(fofbFIRplusIntegral_DIR)/synth/fofbFIRplusIntegral.v
fofbFixToFloat_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbFixToFloat
fofbFixToFloat_TOP = $(fofbFixToFloat_DIR)/synth/fofbFixToFloat.v
fofbGainMultiplier_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbGainMultiplier
fofbGainMultiplier_TOP = $(fofbGainMultiplier_DIR)/synth/fofbGainMultiplier.v
fofbIntegralFixToFloat_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbIntegralFixToFloat
fofbIntegralFixToFloat_TOP = $(fofbIntegralFixToFloat_DIR)/synth/fofbIntegralFixToFloat.v
fofbIntegralMultiplier_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbIntegralMultiplier
fofbIntegralMultiplier_TOP = $(fofbIntegralMultiplier_DIR)/synth/fofbIntegralMultiplier.v
fofbPCS_PMA_with_shared_logic_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbPCS_PMA_with_shared_logic
fofbPCS_PMA_with_shared_logic_TOP = $(fofbPCS_PMA_with_shared_logic_DIR)/synth/fofbPCS_PMA_with_shared_logic.v
fofbPCS_PMA_without_shared_logic_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbPCS_PMA_without_shared_logic
fofbPCS_PMA_without_shared_logic_TOP = $(fofbPCS_PMA_without_shared_logic_DIR)/synth/fofbPCS_PMA_without_shared_logic.v
fofbReadLinksMux_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbReadLinksMux
fofbReadLinksMux_TOP = $(fofbReadLinksMux_DIR)/synth/fofbReadLinksMux.v
fofbSupplyFilter_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/fofbSupplyFilter
fofbSupplyFilter_TOP = $(fofbSupplyFilter_DIR)/synth/fofbSupplyFilter.vhd
forwardCellLinkMux_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/forwardCellLinkMux
forwardCellLinkMux_TOP = $(forwardCellLinkMux_DIR)/synth/forwardCellLinkMux.v
linkStatisticsMux_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/linkStatisticsMux
linkStatisticsMux_TOP = $(linkStatisticsMux_DIR)/synth/linkStatisticsMux.v
psSetpointCalcConvertToAmps_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/psSetpointCalcConvertToAmps
psSetpointCalcConvertToAmps_TOP = $(psSetpointCalcConvertToAmps_DIR)/synth/psSetpointCalcConvertToAmps.v
psSetpointCalcFixToFloat_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/psSetpointCalcFixToFloat
psSetpointCalcFixToFloat_TOP = $(psSetpointCalcFixToFloat_DIR)/synth/psSetpointCalcFixToFloat.v
readBPMlinksMux_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/readBPMlinksMux
readBPMlinksMux_TOP = $(readBPMlinksMux_DIR)/synth/readBPMlinksMux.v
readOldBPMs_DoubleToFloat_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/readOldBPMs_DoubleToFloat
readOldBPMs_DoubleToFloat_TOP = $(readOldBPMs_DoubleToFloat_DIR)/synth/readOldBPMs_DoubleToFloat.v
readOldBPMs_FIFO_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/readOldBPMs_FIFO
readOldBPMs_FIFO_TOP = $(readOldBPMs_FIFO_DIR)/synth/readOldBPMs_FIFO.v
readOldBPMs_Fix_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/readOldBPMs_Fix
readOldBPMs_Fix_TOP = $(readOldBPMs_Fix_DIR)/synth/readOldBPMs_Fix.v
readOldBPMs_Multiply_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/readOldBPMs_Multiply
readOldBPMs_Multiply_TOP = $(readOldBPMs_Multiply_DIR)/synth/readOldBPMs_Multiply.v
ila_td256_s4096_cap_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/ila_td256_s4096_cap
ila_td256_s4096_cap_TOP = $(ila_td256_s4096_cap_DIR)/synth/ila_td256_s4096_cap.v

IP_CORES_TOP_LVL_SRCS += $(evr_mgt_gtx_TOP) $(fixToFloat_TOP) $(floatMultiply_TOP) $(floatResultFIFO_TOP) $(floatToDouble_TOP) $(fofbCoefficientMul_TOP) $(fofbFIRplusIntegral_TOP) $(fofbFixToFloat_TOP) $(fofbGainMultiplier_TOP) $(fofbIntegralFixToFloat_TOP) $(fofbIntegralMultiplier_TOP) $(fofbPCS_PMA_with_shared_logic_TOP) $(fofbPCS_PMA_without_shared_logic_TOP) $(fofbReadLinksMux_TOP) $(fofbSupplyFilter_TOP) $(forwardCellLinkMux_TOP) $(linkStatisticsMux_TOP) $(psSetpointCalcConvertToAmps_TOP) $(psSetpointCalcFixToFloat_TOP) $(readBPMlinksMux_TOP) $(readOldBPMs_DoubleToFloat_TOP) $(readOldBPMs_FIFO_TOP) $(readOldBPMs_Fix_TOP) $(readOldBPMs_Multiply_TOP) $(ila_td256_s4096_cap_TOP)
IP_CORES_DIRS += $(evr_mgt_gtx_DIR) $(evr_mgt_gtx_DIR)/evr_mgt_gtx/example_design $(fixToFloat_DIR) $(floatMultiply_DIR) $(floatResultFIFO_DIR) $(floatToDouble_DIR) $(fofbCoefficientMul_DIR) $(fofbFIRplusIntegral_DIR) $(fofbFixToFloat_DIR) $(fofbGainMultiplier_DIR) $(fofbIntegralFixToFloat_DIR) $(fofbIntegralMultiplier_DIR) $(fofbPCS_PMA_with_shared_logic_DIR) $(fofbPCS_PMA_without_shared_logic_DIR) $(fofbReadLinksMux_DIR) $(fofbSupplyFilter_DIR) $(forwardCellLinkMux_DIR) $(linkStatisticsMux_DIR) $(psSetpointCalcConvertToAmps_DIR) $(psSetpointCalcFixToFloat_DIR) $(readBPMlinksMux_DIR) $(readOldBPMs_DoubleToFloat_DIR) $(readOldBPMs_FIFO_DIR) $(readOldBPMs_Fix_DIR) $(readOldBPMs_Multiply_DIR) $(ila_td256_s4096_cap_DIR)
IP_CORES_XDCS += $(evr_mgt_gtx_TOP:%.v=%.xdc)
# Include only the ones that cannot be included as purely Verilog sources
IP_CORES_XCIS += fixToFloat.xci floatToDouble.xci floatMultiply.xci floatResultFIFO.xci fofbPCS_PMA_with_shared_logic.xci fofbPCS_PMA_without_shared_logic.xci fofbCoefficientMul.xci fofbSupplyFilter.xci fofbReadLinksMux.xci forwardCellLinkMux.xci linkStatisticsMux.xci readBPMlinksMux.xci psSetpointCalcFixToFloat.xci psSetpointCalcConvertToAmps.xci ila_td256_s4096_cap.xci
IP_CORES_SRCS_DIRS = $(IP_CORES_DIRS)
IP_CORES_SRCS_DIRS += $(addsuffix /example_design, $(IP_CORES_DIRS))
IP_CORES_SRCS_DIRS += $(addsuffix /synth, $(IP_CORES_DIRS))
IP_CORES_SRCS_DIRS += $(addsuffix /hdl, $(IP_CORES_DIRS))

BD += system_marble
system_marble_DIR = $(PLATFORM_7SERIES_CCTRL_DIR)/system_marble
system_marble_TOP = $(system_marble_DIR)/synth/system_marble.v

BD_TOP_LVL_SRCS += $(system_marble_TOP)
BD_DIRS += $(system_marble_DIR)

BD_SRCS_DIRS = $(BD_DIRS)
BD_SRCS_DIRS += $(addsuffix /synth, $(BD_DIRS))
BD_SRCS_DIRS += $(addsuffix /hdl, $(BD_DIRS))

BD_bds = $(addsuffix .bd, $(BD))

# Add ethernet-core rules, paths
include $(MODULES_DIR)/aggregate_rules.mk
vpath %.v $(CORE_DIR) $(CRC_DIR)

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
VFLAGS_DEP += -y$(PLATFORM_7SERIES_DIR)
VFLAGS_DEP += $(addprefix -y, $(IP_CORES_SRCS_DIRS))
VFLAGS_DEP += $(addprefix -y, $(BD_SRCS_DIRS))

# Local directories for include searching
VFLAGS_DEP += -I.
VFLAGS_DEP += -I$(TOP_LVL_DIR)
VFLAGS_DEP += -I$(MODULES_DIR)
VFLAGS_DEP += $(addprefix -I, $(IP_CORES_SRCS_DIRS))
VFLAGS_DEP += $(addprefix -I, $(BD_SRCS_DIRS))

# Make sure everyone uses the same macro definitions too
VFLAGS_DEP += $(SYNTH_OPT)

# Files to be treated as library files. This is needed if the filename
# does not match the module name, which is the case for Xilinx ip cores.
# As we don't exactly know the names of the sources, create a file with
# the switches that will be consumed by iverilog later
evr_mgt_gtx_VFLAGS_COMMAND_FILE = evr_mgt_gtx_iverilog_cfile.txt
fixToFloat_VFLAGS_COMMAND_FILE = fixToFloat_iverilog_cfile.txt
floatMultiply_VFLAGS_COMMAND_FILE = floatMultiply_iverilog_cfile.txt
floatResultFIFO_VFLAGS_COMMAND_FILE = floatResultFIFO_iverilog_cfile.txt
floatToDouble_VFLAGS_COMMAND_FILE = floatToDouble_iverilog_cfile.txt
fofbCoefficientMul_VFLAGS_COMMAND_FILE = fofbCoefficientMul_iverilog_cfile.txt
fofbFIRplusIntegral_VFLAGS_COMMAND_FILE = fofbFIRplusIntegral_iverilog_cfile.txt
fofbFixToFloat_VFLAGS_COMMAND_FILE = fofbFixToFloat_iverilog_cfile.txt
fofbGainMultiplier_VFLAGS_COMMAND_FILE = fofbGainMultiplier_iverilog_cfile.txt
fofbIntegralFixToFloat_VFLAGS_COMMAND_FILE = fofbIntegralFixToFloat_iverilog_cfile.txt
fofbIntegralMultiplier_VFLAGS_COMMAND_FILE = fofbIntegralMultiplier_iverilog_cfile.txt
fofbPCS_PMA_with_shared_logic_VFLAGS_COMMAND_FILE = fofbPCS_PMA_with_shared_logic_iverilog_cfile.txt
fofbPCS_PMA_without_shared_logic_VFLAGS_COMMAND_FILE = fofbPCS_PMA_without_shared_logic_iverilog_cfile.txt
fofbReadLinksMux_VFLAGS_COMMAND_FILE = fofbReadLinksMux_iverilog_cfile.txt
fofbSupplyFilter_VFLAGS_COMMAND_FILE = fofbSupplyFilter_iverilog_cfile.txt
forwardCellLinkMux_VFLAGS_COMMAND_FILE = forwardCellLinkMux_iverilog_cfile.txt
linkStatisticsMux_VFLAGS_COMMAND_FILE = linkStatisticsMux_iverilog_cfile.txt
psSetpointCalcConvertToAmps_VFLAGS_COMMAND_FILE = psSetpointCalcConvertToAmps_iverilog_cfile.txt
psSetpointCalcFixToFloat_VFLAGS_COMMAND_FILE = psSetpointCalcFixToFloat_iverilog_cfile.txt
readBPMlinksMux_VFLAGS_COMMAND_FILE = readBPMlinksMux_iverilog_cfile.txt
readOldBPMs_DoubleToFloat_VFLAGS_COMMAND_FILE = readOldBPMs_DoubleToFloat_iverilog_cfile.txt
readOldBPMs_FIFO_VFLAGS_COMMAND_FILE = readOldBPMs_FIFO_iverilog_cfile.txt
readOldBPMs_Fix_VFLAGS_COMMAND_FILE = readOldBPMs_Fix_iverilog_cfile.txt
readOldBPMs_Multiply_VFLAGS_COMMAND_FILE = readOldBPMs_Multiply_iverilog_cfile.txt
ila_td256_s4096_cap_VFLAGS_COMMAND_FILE = ila_td256_s4096_cap_iverilog_cfile.txt

VFLAGS_COMMAND_FILE += \
	$(evr_mgt_gtx_VFLAGS_COMMAND_FILE) \
	$(fofbFIRplusIntegral_VFLAGS_COMMAND_FILE) \
	$(fofbFixToFloat_VFLAGS_COMMAND_FILE) \
	$(fofbGainMultiplier_VFLAGS_COMMAND_FILE) \
	$(fofbIntegralFixToFloat_VFLAGS_COMMAND_FILE) \
	$(fofbIntegralMultiplier_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_DoubleToFloat_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_FIFO_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_Fix_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_Multiply_VFLAGS_COMMAND_FILE)
# $(fixToFloat_VFLAGS_COMMAND_FILE) \
# $(floatMultiply_VFLAGS_COMMAND_FILE) \
# $(floatToDouble_VFLAGS_COMMAND_FILE) \
# $(floatResultFIFO_VFLAGS_COMMAND_FILE) \
# $(fofbCoefficientMul_VFLAGS_COMMAND_FILE) \
# $(fofbSupplyFilter_VFLAGS_COMMAND_FILE) \
# $(fofbReadLinksMux_VFLAGS_COMMAND_FILE) \
# $(forwardCellLinkMux_VFLAGS_COMMAND_FILE) \
# $(linkStatisticsMux_VFLAGS_COMMAND_FILE) \
# $(readBPMlinksMux_VFLAGS_COMMAND_FILE) \
# $(fofbPCS_PMA_with_shared_logic_VFLAGS_COMMAND_FILE) \
# $(fofbPCS_PMA_without_shared_logic_VFLAGS_COMMAND_FILE) \
# $(psSetpointCalcFixToFloat_VFLAGS_COMMAND_FILE) \
# $(psSetpointCalcConvertToAmps_VFLAGS_COMMAND_FILE) \
# using ILA with verilog gives an error:
# input buffer overflow, can't enlarge buffer because scanner uses REJECT,
# but we don't need it for iverilog as we only use it when not simulating
# $(ila_td256_s4096_cap_VFLAGS_COMMAND_FILE)

VFLAGS_DEP += $(addprefix -c, $(VFLAGS_COMMAND_FILE))

#VFLAGS_DEP += -DSIMULATE

# Search prerequisites for generated .v/.vh/.vhd/.xdc here
vpath %.v $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.v $(BWUDP_DIR)
vpath %.vh $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.vhd $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.xdc $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.tcl $(GW_SCRIPTS_DIR)
vpath %.sh $(GW_SCRIPTS_DIR)

# ================= I2C Bridge ==================
I2C_PATH=$(PROJECTS_DIR)/test_marble_family/i2c:$(PERIPH_DRIVERS_DIR)
I2C_SCRIPT=$(GW_SCRIPTS_DIR)/marble_i2c_prog.py
I2C_DAT=$(MODULES_DIR)/marble_i2c.dat
$(I2C_VH):$(I2C_SCRIPT)
	PYTHONPATH=$(I2C_PATH) python3 $< v > $@

$(I2C_DAT):$(I2C_SCRIPT)
	PYTHONPATH=$(I2C_PATH) python3 $< > $@

# TODO - Do I need to explicitly add this to bit dependency list?
$(MODULES_DIR)/qsfpMarble.v: $(I2C_VH) $(I2C_DAT)

# ================ SCRAP =======================
SYNTH_OPT ?=
ifneq (,$(SCRAP))
SCRAP_DIR=/home/kpenney/repos/scrap
include $(SCRAP_DIR)/scrap_rules.mk
VFLAGS_DEP += -y$(SCRAP_DIR)/src
SYNTH_OPT+=-DQSFP_DEBUG_BUS
SYNTH_OPT+=-DSCRAPE
SYNTH_OPT+=-DSCRAP_SHARED_BUS
else
SCRAP_DIR=
endif

# List top level depedencies here. Eveything named .bit will be used as
# a top-level target in top_rules.mk. .v and .sv files will be used as
# prerequisites as well as a system_top.xdc file
$(TARGET)_top.bit: system_top.xdc $(VIVADO_SYNTH_EXTRA_TCL) $(TOP_LVL_DIR)/$(TARGET)_top.v $(BD_bds) $(IP_CORES_XCIS) $(MODULES_DIR)/badgerMerged.v $(BWUDP_DIR)/badger.v $(SERIAL_IO_DIR)/gmii_to_rgmii.v $(MODULES_DIR)/qsfpMarble.v $(I2C_VH) $(I2C_DAT) $(SCRAP_FILES)
$(TOP_LVL_DIR)/$(TARGET)_top.v: $(TOP_LVL_DIR)/gitHash.vh $(TOP_LVL_DIR)/$(GPIOIDX_V) $(TOP_LVL_DIR)/aggregate.v $(IP_CORES_CUSTOM) $(IP_CORES_TOP_LVL_SRCS) $(BD_TOP_LVL_SRCS)

$(TARGET)_top.mmi: $(XPR) $(TARGET)_top.bit
	vivado -mode batch -nojou -nolog -source $(GW_SCRIPTS_DIR)/gen_mem_info.tcl -tclargs $< $@

# Generate bundled .xdc from other .xdc. Don't change the order of the
# prerequisites as we need constraints in the order specified
system_top.xdc: $(SYSTEM_TOP_PINS_XDC) $(IP_CORES_XDCS) $(SYSTEM_TOP_TIM_XDC)
	cat $^ > $@

# Generate firmware date and parameters
%firmwareBuildDate.v: set_firmware_build_date.tcl
	$(VIVADO_CMD) -source $< -tclargs $@

# This PHONY is causing problems
#.PHONY: $(TOP_LVL_DIR)/gitHash.vh
$(TOP_LVL_DIR)/gitHash.vh:
	sh $(GW_SCRIPTS_DIR)/gitHashVerilog.sh > $@

%/$(GPIOIDX_V): $(SW_TGT_DIR)/$(FPGA_APPLICATION)_$(HARDWARE)/gpio.h
	sh $(GW_SCRIPTS_DIR)/createVerilogIDX.sh $^ > $@

ipcores_repos.tcl:
	sed -e 's|$$DIRS|$(IP_CORES_CUSTOM_TARGET_DIRS)|g' \
		ipcores_repos.tcl.in > $@

prio_xci_files.tcl: ila_td256_s4096_cap.xci
	sed -e 's|$$XCI_FILES|$<|g' \
		prio_xci_files.tcl.in > $@

# ip_cores commands. Keep track only of the top-level. If this changed or doesn't
# exist regenerate eveything. Otherwise, consider this up to date
vpath %.xci $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.bd $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)

# Use second expansion here so we can get the matched target name in the prerequisite
# and use the defined variable to find the .xci one level below.
# FIXME: Is there an easier way to do this?
.SECONDEXPANSION:
$(IP_CORES_TOP_LVL_SRCS): % : $$(basename $$(notdir %)).xci
	$(VIVADO_CMD) -source $(GW_SCRIPTS_DIR)/ip_core_proc.tcl $(GW_SCRIPTS_DIR)/gen_ip_core.tcl -tclargs $< $(PROJECT_PART) $(PROJECT_BOARD)
	# fix line-continuation between (* *) attribute that iverilog doesn't understand
	# from: https://catonmat.net/sed-one-liners-explained-part-one,
	# 39. Append a line to the next if it ends with a backslash "\".
	TOP_LVL="$*"; if [ "$${TOP_LVL##*.}" = "v" ] || [ "$${TOP_LVL##*.}" = "sv" ]; then sed -i -e :a -e '/\\$$/N; s/\\\n//; ta' $${TOP_LVL}; fi
	# convert modules instance names to lowercase so iverilog can match and generate
	# the depedency file for it
	(find $($(basename $(notdir $@))_DIR) -not \( -name \*rfs.v \) -name "*.v" -exec sed -i -e 's/\($(basename $(notdir $@))_[A-Za-z0-9_]\+\)/\L\1/' '{}' \; || true)
	# generate iverilog switches
	rm -f $($(basename $(notdir $@))_VFLAGS_COMMAND_FILE)
	(find $($(basename $(notdir $@))_DIR)/hdl $($(basename $(notdir $@))_DIR)/synth -mindepth 1 -not \( -name \*rfs.v \) -name "*.v" -exec echo "-l"'{}' \; || true) >> $($(basename $(notdir $@))_VFLAGS_COMMAND_FILE)
	(find $($(basename $(notdir $@))_DIR) -mindepth 1 -maxdepth 1 -not \( -name \*rfs.v \) -name "*.v" -exec echo "-l"'{}' \; || true) >> $($(basename $(notdir $@))_VFLAGS_COMMAND_FILE)

$(BD_TOP_LVL_SRCS): % : $$(basename $$(notdir %)).bd
	$(VIVADO_CMD) -source $(GW_SCRIPTS_DIR)/bd_proc.tcl $(GW_SCRIPTS_DIR)/gen_bd.tcl -tclargs $< $(PROJECT_PART) $(PROJECT_BOARD) $(IP_CORES_CUSTOM_TARGET_DIRS)

# In case you need to manually generate the Vivado project file
VIVADO_CREATE_PROJ = $(VIVADO_CMD) -source $(BUILD_DIR)/vivado_tcl/project_proc.tcl $(BUILD_DIR)/vivado_tcl/vivado_project.tcl -tclargs
# Create $(XPR)

#.PHONY: vproj
#vproj: system_top.xdc $(VIVADO_SYNTH_EXTRA_TCL) $(TOP_LVL_DIR)/$(TARGET)_top.v $(BD_bds) $(IP_CORES_XCIS) $(MODULES_DIR)/badgerMerged.v $(BWUDP_DIR)/badger.v $(SERIAL_IO_DIR)/gmii_to_rgmii.v
#	$(VIVADO_CREATE_PROJ) $(HARDWARE) $* "$(SYNTH_OPT)" $^

# clean generate IP cores files, but the source ones (.xci or .bd)
clean::
	$(foreach ipcore, $(IP_CORES), find $($(ipcore)_DIR)/ -mindepth 1 -not \( -name \*$(ipcore).xci -o -name \*$(ipcore).bd \) -delete $(CMD_SEP))
	$(foreach bd, $(BD), find $($(bd)_DIR)/ -mindepth 1 -not \( -name \*$(bd).xci -o -name \*$(bd).bd \) -delete $(CMD_SEP))

# Cleaning rules
include $(BUILD_DIR)/bottom_rules.mk

CLEAN += *.bit
CLEAN += *.bin
CLEAN += *.prm
CLEAN += system_top.xdc
CLEAN += $(TOP_LVL_DIR)/firmwareBuildDate.v
CLEAN += $(TOP_LVL_DIR)/aggregate.v
CLEAN += $(TOP_LVL_DIR)/$(GPIOIDX_V)
CLEAN += $(IP_CORES_CUSTOM)
CLEAN += $(VFLAGS_COMMAND_FILE)
# Not adding it to VFLAGS_COMMAND_FILE because iverilog gives an error:
# input buffer overflow, can't enlarge buffer because scanner uses REJECT,
# but we don't need it for iverilog as we only use it when not simulating
CLEAN += $(ila_td256_s4096_cap_VFLAGS_COMMAND_FILE)
CLEAN += $(fixToFloat_VFLAGS_COMMAND_FILE)
CLEAN += $(floatMultiply_VFLAGS_COMMAND_FILE)
CLEAN += $(floatToDouble_VFLAGS_COMMAND_FILE)
CLEAN += $(floatResultFIFO_VFLAGS_COMMAND_FILE)
CLEAN += $(fofbCoefficientMul_VFLAGS_COMMAND_FILE)
CLEAN += $(fofbSupplyFilter_VFLAGS_COMMAND_FILE)
CLEAN += $(fofbReadLinksMux_VFLAGS_COMMAND_FILE)
CLEAN += $(forwardCellLinkMux_VFLAGS_COMMAND_FILE)
CLEAN += $(linkStatisticsMux_VFLAGS_COMMAND_FILE)
CLEAN += $(readBPMlinksMux_VFLAGS_COMMAND_FILE)
CLEAN += $(fofbPCS_PMA_with_shared_logic_VFLAGS_COMMAND_FILE)
CLEAN += $(fofbPCS_PMA_without_shared_logic_VFLAGS_COMMAND_FILE)
CLEAN += $(psSetpointCalcFixToFloat_VFLAGS_COMMAND_FILE)
CLEAN += $(psSetpointCalcConvertToAmps_VFLAGS_COMMAND_FILE)
CLEAN += *.log *.jou *.str
CLEAN += *.xsa
CLEAN += psu_init*
CLEAN += ipcores_repos.tcl
CLEAN += prio_xci_files.tcl
CLEAN += $(TARGET)_top.mmi
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
