HARDWARE = bmb7
PROJECT_PART = xc7k160tffg676-2
PROJECT_BOARD = none
XILINX_TOOL := VIVADO
FPGA_VENDOR := xilinx
FPGA_APPLICATION := cctrl

CMD_SEP = ;

include ../../../dir_list.mk

# Top level design name
TARGET ?= $(FPGA_APPLICATION)_$(HARDWARE)

# Top level bitstream name
all: $(TARGET)_top.bit

# Search for .v files here
vpath %.v $(DSP_DIR)
vpath %.v $(MODULES_DIR)

TOP_LVL_DIR = ../../top/$(TARGET)

# top-level files go here
vpath %.v $(TOP_LVL_DIR)
vpath %.xdc $(TOP_LVL_DIR)

VIVADO_SYNTH_EXTRA_TCL = prop.tcl ipcores_repos.tcl prio_xci_files.tcl
# TO-DO review
# VIVADO_SYNTH_EXTRA_TCL = prop.tcl

include $(BUILD_DIR)/top_rules.mk

# ignore xilinx primitives
# TO-DO review
# UNISIM_CRAP += '-e GTYE4_CHANNEL|MMCME4_ADV'

# Top level files for depedency tracking
SYSTEM_TOP_PINS_XDC = $(TARGET)_top_pins.xdc
SYSTEM_TOP_TIM_XDC = $(TARGET)_top_tim.xdc

# ip_cores generation scripts/names

# custom ip_cores that requires packaging
# TO-DO review
# include $(MODULES_DIR)/evr_axi_rules.mk
# include $(MODULES_DIR)/axi_lite_generic_reg_rules.mk

IP_CORES += evr_mgt_gtx fixToFloat floatMultiply floatResultFIFO floatToDouble fofbCoefficientMul fofbFIRplusIntegral fofbFixToFloat fofbGainMultiplier fofbIntegralFixToFloat fofbIntegralMultiplier fofbPCS_PMA_with_shared_logic fofbPCS_PMA_without_shared_logic fofbReadLinksMux fofbSupplyFilter forwardCellLinkMux linkStatisticsMux psSetpointCalcConvertToAmps psSetpointCalcFixToFloat readBPMlinksMux readOldBPMs_DoubleToFloat readOldBPMs_FIFO readOldBPMs_Fix readOldBPMs_Multiply
evr_mgt_gtx_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/evr_mgt_gtx
evr_mgt_gtx_TOP = $(evr_mgt_gtx_DIR)/evr_mgt_gtx.v
fixToFloat_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fixToFloat
fixToFloat_TOP = $(fixToFloat_DIR)/synth/fixToFloat.v
floatMultiply_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/floatMultiply
floatMultiply_TOP = $(floatMultiply_DIR)/synth/floatMultiply.v
floatResultFIFO_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/floatResultFIFO
floatResultFIFO_TOP = $(floatResultFIFO_DIR)/synth/floatResultFIFO.vhd
floatToDouble_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/floatToDouble
floatToDouble_TOP = $(floatToDouble_DIR)/synth/floatToDouble.v
fofbCoefficientMul_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbCoefficientMul
fofbCoefficientMul_TOP = $(fofbCoefficientMul_DIR)/synth/fofbCoefficientMul.vhd
fofbFIRplusIntegral_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbFIRplusIntegral
fofbFIRplusIntegral_TOP = $(fofbFIRplusIntegral_DIR)/synth/fofbFIRplusIntegral.v
fofbFixToFloat_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbFixToFloat
fofbFixToFloat_TOP = $(fofbFixToFloat_DIR)/synth/fofbFixToFloat.v
fofbGainMultiplier_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbGainMultiplier
fofbGainMultiplier_TOP = $(fofbGainMultiplier_DIR)/synth/fofbGainMultiplier.v
fofbIntegralFixToFloat_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbIntegralFixToFloat
fofbIntegralFixToFloat_TOP = $(fofbIntegralFixToFloat_DIR)/synth/fofbIntegralFixToFloat.v
fofbIntegralMultiplier_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbIntegralMultiplier
fofbIntegralMultiplier_TOP = $(fofbIntegralMultiplier_DIR)/synth/fofbIntegralMultiplier.v
fofbPCS_PMA_with_shared_logic_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbPCS_PMA_with_shared_logic
fofbPCS_PMA_with_shared_logic_TOP = $(fofbPCS_PMA_with_shared_logic_DIR)/synth/fofbPCS_PMA_with_shared_logic.v
fofbPCS_PMA_without_shared_logic_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbPCS_PMA_without_shared_logic
fofbPCS_PMA_without_shared_logic_TOP = $(fofbPCS_PMA_without_shared_logic_DIR)/synth/fofbPCS_PMA_without_shared_logic.v
fofbReadLinksMux_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbReadLinksMux
fofbReadLinksMux_TOP = $(fofbReadLinksMux_DIR)/synth/fofbReadLinksMux.v
fofbSupplyFilter_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/fofbSupplyFilter
fofbSupplyFilter_TOP = $(fofbSupplyFilter_DIR)/synth/fofbSupplyFilter.vhd
forwardCellLinkMux_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/forwardCellLinkMux
forwardCellLinkMux_TOP = $(forwardCellLinkMux_DIR)/synth/forwardCellLinkMux.v
linkStatisticsMux_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/linkStatisticsMux
linkStatisticsMux_TOP = $(linkStatisticsMux_DIR)/synth/linkStatisticsMux.v
psSetpointCalcConvertToAmps_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/psSetpointCalcConvertToAmps
psSetpointCalcConvertToAmps_TOP = $(psSetpointCalcConvertToAmps_DIR)/synth/psSetpointCalcConvertToAmps.v
psSetpointCalcFixToFloat_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/psSetpointCalcFixToFloat
psSetpointCalcFixToFloat_TOP = $(psSetpointCalcFixToFloat_DIR)/synth/psSetpointCalcFixToFloat.v
readBPMlinksMux_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/readBPMlinksMux
readBPMlinksMux_TOP = $(readBPMlinksMux_DIR)/synth/readBPMlinksMux.v
readOldBPMs_DoubleToFloat_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/readOldBPMs_DoubleToFloat
readOldBPMs_DoubleToFloat_TOP = $(readOldBPMs_DoubleToFloat_DIR)/synth/readOldBPMs_DoubleToFloat.v
readOldBPMs_FIFO_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/readOldBPMs_FIFO
readOldBPMs_FIFO_TOP = $(readOldBPMs_FIFO_DIR)/synth/readOldBPMs_FIFO.v
readOldBPMs_Fix_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/readOldBPMs_Fix
readOldBPMs_Fix_TOP = $(readOldBPMs_Fix_DIR)/synth/readOldBPMs_Fix.v
readOldBPMs_Multiply_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/readOldBPMs_Multiply
readOldBPMs_Multiply_TOP = $(readOldBPMs_Multiply_DIR)/synth/readOldBPMs_Multiply.v

IP_CORES_TOP_LVL_SRCS += $(evr_mgt_gtx_TOP) $(fixToFloat_TOP) $(floatMultiply_TOP) $(floatResultFIFO_TOP) $(floatToDouble_TOP) $(fofbCoefficientMul_TOP) $(fofbFIRplusIntegral_TOP) $(fofbFixToFloat_TOP) $(fofbGainMultiplier_TOP) $(fofbIntegralFixToFloat_TOP) $(fofbIntegralMultiplier_TOP) $(fofbPCS_PMA_with_shared_logic_TOP) $(fofbPCS_PMA_without_shared_logic_TOP) $(fofbReadLinksMux_TOP) $(fofbSupplyFilter_TOP) $(forwardCellLinkMux_TOP) $(linkStatisticsMux_TOP) $(psSetpointCalcConvertToAmps_TOP) $(psSetpointCalcFixToFloat_TOP) $(readBPMlinksMux_TOP) $(readOldBPMs_DoubleToFloat_TOP) $(readOldBPMs_FIFO_TOP) $(readOldBPMs_Fix_TOP) $(readOldBPMs_Multiply_TOP)
IP_CORES_DIRS += $(evr_mgt_gtx_DIR) $(fixToFloat_DIR) $(floatMultiply_DIR) $(floatResultFIFO_DIR) $(floatToDouble_DIR) $(fofbCoefficientMul_DIR) $(fofbFIRplusIntegral_DIR) $(fofbFixToFloat_DIR) $(fofbGainMultiplier_DIR) $(fofbIntegralFixToFloat_DIR) $(fofbIntegralMultiplier_DIR) $(fofbPCS_PMA_with_shared_logic_DIR) $(fofbPCS_PMA_without_shared_logic_DIR) $(fofbReadLinksMux_DIR) $(fofbSupplyFilter_DIR) $(forwardCellLinkMux_DIR) $(linkStatisticsMux_DIR) $(psSetpointCalcConvertToAmps_DIR) $(psSetpointCalcFixToFloat_DIR) $(readBPMlinksMux_DIR) $(readOldBPMs_DoubleToFloat_DIR) $(readOldBPMs_FIFO_DIR) $(readOldBPMs_Fix_DIR) $(readOldBPMs_Multiply_DIR)
IP_CORES_XDCS += $(evr_mgt_gtx_TOP:%.v=%.xdc) $(floatResultFIFO_TOP:%.v=%.xdc) $(fofbPCS_PMA_with_shared_logic_TOP:%.v=%.xdc) $(fofbPCS_PMA_without_shared_logic_TOP:%.v=%.xdc) $(linkStatisticsMux_DIR/linkStatisticsMux_clocks.xdc)
IP_CORES_XCIS += $(evr_mgt_gtx_DIR)/evr_mgt_gtx.xci $(fixToFloat_DIR)/fixToFloat.xci $(floatMultiply_DIR)/floatMultiply.xci $(floatResultFIFO_DIR)/floatResultFIFO.xci $(floatToDouble_DIR)/floatToDouble.xci $(fofbCoefficientMul_DIR)/fofbCoefficientMul.xci $(fofbFIRplusIntegral_DIR)/fofbFIRplusIntegral.xci $(fofbFixToFloat_DIR)/fofbFixToFloat.xci $(fofbGainMultiplier_DIR)/fofbGainMultiplier.xci $(fofbIntegralFixToFloat_DIR)/fofbIntegralFixToFloat.xci $(fofbIntegralMultiplier_DIR)/fofbIntegralMultiplier.xci $(fofbPCS_PMA_with_shared_logic_DIR)/fofbPCS_PMA_with_shared_logic.xci $(fofbPCS_PMA_without_shared_logic_DIR)/fofbPCS_PMA_without_shared_logic.xci $(fofbReadLinksMux_DIR)/fofbReadLinksMux.xci $(fofbSupplyFilter_DIR)/fofbSupplyFilter.xci $(forwardCellLinkMux_DIR)/forwardCellLinkMux.xci $(linkStatisticsMux_DIR)/linkStatisticsMux.xci $(psSetpointCalcConvertToAmps_DIR)/psSetpointCalcConvertToAmps.xci $(psSetpointCalcFixToFloat_DIR)/psSetpointCalcFixToFloat.xci $(readBPMlinksMux_DIR)/readBPMlinksMux.xci $(readOldBPMs_DoubleToFloat_DIR)/readOldBPMs_DoubleToFloat.xci $(readOldBPMs_FIFO_DIR)/readOldBPMs_FIFO.xci $(readOldBPMs_Fix_DIR)/readOldBPMs_Fix.xci $(readOldBPMs_Multiply_DIR)/readOldBPMs_Multiply.xci
IP_CORES_SRCS_DIRS = $(IP_CORES_DIRS)
IP_CORES_SRCS_DIRS += $(addsuffix /example_design, $(IP_CORES_DIRS))
IP_CORES_SRCS_DIRS += $(addsuffix /synth, $(IP_CORES_DIRS))
IP_CORES_SRCS_DIRS += $(addsuffix /hdl, $(IP_CORES_DIRS))

# TO-DO: review. is the inclusion of just the system.bd enough? will everything else get generated?
BD += system
system_DIR = $(PLATFORM_BMB7_CCTRL_DIR)/system
system_TOP = $(system_DIR)/synth/system.v

BD_TOP_LVL_SRCS += $(system_TOP)
BD_DIRS += $(system_DIR)

BD_SRCS_DIRS = $(BD_DIRS)
BD_SRCS_DIRS += $(addsuffix /synth, $(BD_DIRS))
BD_SRCS_DIRS += $(addsuffix /hdl, $(BD_DIRS))

BD_bds = $(addsuffix .bd, $(BD))

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
VFLAGS_DEP += -y$(HOMELESS_DIR)

# Local directories for searching
VFLAGS_DEP += -y.
VFLAGS_DEP += -y$(MODULES_DIR)
VFLAGS_DEP += -y$(TOP_LVL_DIR)
VFLAGS_DEP += $(addprefix -y, $(IP_CORES_SRCS_DIRS))
VFLAGS_DEP += $(addprefix -y, $(BD_SRCS_DIRS))

# Local directories for include searching
VFLAGS_DEP += -I.
VFLAGS_DEP += -I$(MODULES_DIR)
VFLAGS_DEP += -I$(TOP_LVL_DIR)
VFLAGS_DEP += $(addprefix -I, $(IP_CORES_SRCS_DIRS))
VFLAGS_DEP += $(addprefix -I, $(BD_SRCS_DIRS))

# Files to be treated as library files. This is needed if the filename
# does not match the module name, which is the case for Xilinx ip cores.
# As we don't exactly know the names of the sources, create a file with
# the switches that will be consumed by iverilog later
evr_mgt_gtx_VFLAGS_COMMAND_FILE = evr_mgt_gtx.txt
fixToFloat_VFLAGS_COMMAND_FILE = fixToFloat.txt
floatMultiply_VFLAGS_COMMAND_FILE = floatMultiply.txt
floatResultFIFO_VFLAGS_COMMAND_FILE = floatResultFIFO.txt
floatToDouble_VFLAGS_COMMAND_FILE = floatToDouble.txt
fofbCoefficientMul_VFLAGS_COMMAND_FILE = fofbCoefficientMul.txt
fofbFIRplusIntegral_VFLAGS_COMMAND_FILE = fofbFIRplusIntegral.txt
fofbFixToFloat_VFLAGS_COMMAND_FILE = fofbFixToFloat.txt
fofbGainMultiplier_VFLAGS_COMMAND_FILE = fofbGainMultiplier.txt
fofbIntegralFixToFloat_VFLAGS_COMMAND_FILE = fofbIntegralFixToFloat.txt
fofbIntegralMultiplier_VFLAGS_COMMAND_FILE = fofbIntegralMultiplier.txt
fofbPCS_PMA_with_shared_logic_VFLAGS_COMMAND_FILE = fofbPCS_PMA_with_shared_logic.txt
fofbPCS_PMA_without_shared_logic_VFLAGS_COMMAND_FILE = fofbPCS_PMA_without_shared_logic.txt
fofbReadLinksMux_VFLAGS_COMMAND_FILE = fofbReadLinksMux.txt
fofbSupplyFilter_VFLAGS_COMMAND_FILE = fofbSupplyFilter.txt
forwardCellLinkMux_VFLAGS_COMMAND_FILE = forwardCellLinkMux.txt
linkStatisticsMux_VFLAGS_COMMAND_FILE = linkStatisticsMux.txt
psSetpointCalcConvertToAmps_VFLAGS_COMMAND_FILE = psSetpointCalcConvertToAmps.txt
psSetpointCalcFixToFloat_VFLAGS_COMMAND_FILE = psSetpointCalcFixToFloat.txt
readBPMlinksMux_VFLAGS_COMMAND_FILE = readBPMlinksMux.txt
readOldBPMs_DoubleToFloat_VFLAGS_COMMAND_FILE = readOldBPMs_DoubleToFloat.txt
readOldBPMs_FIFO_VFLAGS_COMMAND_FILE = readOldBPMs_FIFO.txt
readOldBPMs_Fix_VFLAGS_COMMAND_FILE = readOldBPMs_Fix.txt
readOldBPMs_Multiply_VFLAGS_COMMAND_FILE = readOldBPMs_Multiply.txt


VFLAGS_COMMAND_FILE += \
	$(evr_mgt_gtx_VFLAGS_COMMAND_FILE) \
	$(fixToFloat_VFLAGS_COMMAND_FILE) \
	$(floatMultiply_VFLAGS_COMMAND_FILE) \
	$(floatResultFIFO_VFLAGS_COMMAND_FILE) \
	$(floatToDouble_VFLAGS_COMMAND_FILE) \
	$(fofbCoefficientMul_VFLAGS_COMMAND_FILE) \
	$(fofbFIRplusIntegral_VFLAGS_COMMAND_FILE) \
	$(fofbFixToFloat_VFLAGS_COMMAND_FILE) \
	$(fofbGainMultiplier_VFLAGS_COMMAND_FILE) \
	$(fofbIntegralFixToFloat_VFLAGS_COMMAND_FILE) \
	$(fofbIntegralMultiplier_VFLAGS_COMMAND_FILE) \
	$(fofbPCS_PMA_with_shared_logic_VFLAGS_COMMAND_FILE) \
	$(fofbPCS_PMA_without_shared_logic_VFLAGS_COMMAND_FILE) \
	$(fofbReadLinksMux_VFLAGS_COMMAND_FILE) \
	$(fofbSupplyFilter_VFLAGS_COMMAND_FILE) \
	$(forwardCellLinkMux_VFLAGS_COMMAND_FILE) \
	$(linkStatisticsMux_VFLAGS_COMMAND_FILE) \
	$(psSetpointCalcConvertToAmps_VFLAGS_COMMAND_FILE) \
	$(psSetpointCalcFixToFloat_VFLAGS_COMMAND_FILE) \
	$(readBPMlinksMux_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_DoubleToFloat_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_FIFO_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_Fix_VFLAGS_COMMAND_FILE) \
	$(readOldBPMs_Multiply_VFLAGS_COMMAND_FILE)

VFLAGS_DEP += $(addprefix -c, $(VFLAGS_COMMAND_FILE))

VFLAGS_DEP += -DSIMULATE

# Search prerequisites for generated .v/.vh/.vhd/.xdc here
vpath %.v $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.vh $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.vhd $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.xdc $(IP_CORES_SRCS_DIRS) $(BD_SRCS_DIRS)
vpath %.tcl $(GW_SCRIPTS_DIR)
vpath %.sh $(GW_SCRIPTS_DIR)

# List top level depedencies here. Eveything named .bit will be used as
# a top-level target in top_rules.mk. .v and .sv files will be used as
# prerequisites as well as a system_top.xdc file'

# vivado -mode batch -nojou -nolog -source
# /home/cb/Work/LBNL/projects/gitlab/alsu-digitizers/gateware/ip_cores/bedrock//build-tools/vivado_tcl/project_proc.tcl
# prop.tcl ipcores_repos.tcl prio_xci_files.tcl
# /home/cb/Work/LBNL/projects/gitlab/alsu-digitizers/gateware/ip_cores/bedrock//build-tools/vivado_tcl/vivado_project.tcl
# -tclargs zcu208 bpm_zcu208_top "" system_top.xdc prop.tcl ipcores_repos.tcl prio_xci_files.tcl ../../top/bpm_zcu208/bpm_zcu208_top.v

$(TARGET)_top.bit: system_top.xdc $(VIVADO_SYNTH_EXTRA_TCL) $(TOP_LVL_DIR)/$(TARGET)_top.v $(BD_bds) $(IP_CORES_XCIS)
$(TOP_LVL_DIR)/$(TARGET)_top.v: $(TOP_LVL_DIR)/firmwareBuildDate.v $(IP_CORES_CUSTOM) $(IP_CORES_TOP_LVL_SRCS) $(BD_TOP_LVL_SRCS)

# Generate bundled .xdc from other .xdc. Don't change the order of the
# prerequisites as we need constraints in the order specified
system_top.xdc: $(SYSTEM_TOP_PINS_XDC) $(IP_CORES_XDCS) $(SYSTEM_TOP_TIM_XDC)
	cat $^ > $@

# Generate firmware date and parameters
%firmwareBuildDate.v: set_firmware_build_date.tcl
	$(VIVADO_CMD) -source $< -tclargs $@

# Unused here
# %gpioIDX.v: $(SW_TGT_DIR)/$(FPGA_APPLICATION)_$(HARDWARE)/config.h $(SW_TGT_DIR)/$(FPGA_APPLICATION)_$(HARDWARE)/gpio.h
# 	sh $(GW_SCRIPTS_DIR)/createVerilogIDX.sh $^ > $@

# TO-DO: review
ipcores_repos.tcl:
	sed -e 's|$$DIRS|$(IP_CORES_CUSTOM_TARGET_DIRS)|g' \
		ipcores_repos.tcl.in > $@

# prio_xci_files.tcl: ila_td256_s4096_cap.xci
# 	sed -e 's|$$XCI_FILES|$<|g' \
# 		prio_xci_files.tcl.in > $@

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
	# generate iverilog switches
	rm -f $($(basename $(notdir $@))_VFLAGS_COMMAND_FILE)
	(find $($(basename $(notdir $@))_DIR)/hdl $($(basename $(notdir $@))_DIR)/synth -mindepth 1 -not \( -name \*rfs.v \) -name "*.v" -exec echo "-l"'{}' \; || true) >> $($(basename $(notdir $@))_VFLAGS_COMMAND_FILE)
	(find $($(basename $(notdir $@))_DIR) -mindepth 1 -maxdepth 1 -not \( -name \*rfs.v \) -name "*.v" -exec echo "-l"'{}' \; || true) >> $($(basename $(notdir $@))_VFLAGS_COMMAND_FILE)

$(BD_TOP_LVL_SRCS): % : $$(basename $$(notdir %)).bd
	$(VIVADO_CMD) -source $(GW_SCRIPTS_DIR)/bd_proc.tcl $(GW_SCRIPTS_DIR)/gen_bd.tcl -tclargs $< $(PROJECT_PART) $(PROJECT_BOARD) $(IP_CORES_CUSTOM_TARGET_DIRS)

# clean generate IP cores files, but the source ones (.xci or .bd)
clean::
	$(foreach ipcore, $(IP_CORES), find $($(ipcore)_DIR) -mindepth 1 -not \( -name \*$(ipcore).xci -o -name \*$(ipcore).bd \) -delete $(CMD_SEP))
	$(foreach bd, $(BD), find $($(bd)_DIR) -mindepth 1 -not \( -name \*$(bd).xci -o -name \*$(bd).bd \) -delete $(CMD_SEP))

# Cleaning rules
include $(BUILD_DIR)/bottom_rules.mk

CLEAN += *.bit
CLEAN += system_top.xdc
CLEAN += $(TOP_LVL_DIR)/firmwareBuildDate.v
CLEAN += $(TOP_LVL_DIR)/gpioIDX.v
CLEAN += $(IP_CORES_CUSTOM)
CLEAN += $(VFLAGS_COMMAND_FILE)
# Not adding it to VFLAGS_COMMAND_FILE because iverilog gives an error:
# input buffer overflow, can't enlarge buffer because scanner uses REJECT,
# but we don't need it for iverilog as we only use it when not simulating
CLEAN += $(ila_td256_s4096_cap_VFLAGS_COMMAND_FILE)
CLEAN += *.log *.jou *.str
CLEAN += *.xsa
CLEAN += psu_init*
CLEAN += ipcores_repos.tcl
CLEAN += prio_xci_files.tcl
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
