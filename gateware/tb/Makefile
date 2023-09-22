# A quick Makefile

THIS_MAKEF_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MAKEF_DIR := $(dir $(THIS_MAKEF_PATH))
include $(THIS_MAKEF_DIR)/../../dir_list.mk
VERILATOR = verilator

I2CBRIDGE=$(BEDROCK_DIR)/peripheral_drivers/i2cbridge
DSP=$(BEDROCK_DIR)/dsp

include $(I2CBRIDGE)/i2cbridge_rules.mk
SOURCES = $(MODULES_DIR)/qsfpMarble.v
SOURCES+= $(addprefix $(I2CBRIDGE)/,$(filter-out dpram.v, $(I2CBRIDGE_V)))
SOURCES+= $(DSP)/dpram.v


INCLUDES=-I$(THIS_MAKEF_DIR) -I$(SW_SRC_DIR) -I$(MODULES_DIR) -I$(GATEWARE_DIR)/top/cctrl_marble
TB_DIR = $(THIS_MAKEF_DIR)

# Copied from bedrock/build-tools/top_rules.mk
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-macro-redefinition
VG_ALL = -DTESTBENCH
V_TB = -Wno-timescale
INC_DIR=../top/cctrl_marble
VFLAGS = ${VFLAGS_$@} -I$(INC_DIR)
VERILOG_TB = $(VERILOG) $(VG_ALL) $(V_TB) ${VFLAGS} -o $@ $(filter %v, $^)

FOFB_LOOPBACK_SOURCES=axi_stream_loopback.v \
											bpm_traffic_generator.v \
											cell_traffic_generator.v \
											stream_mux.v \
											forwardCellLinkMux.v \
											fofbReadLinksMux.v \
											readBPMlinksMux.v
MODULES=../modules
SYNTH_SOURCES=readBPMlinks.v forwardCellLink.v fofbReadLinks.v fofbDSP.v
SYNTH_SOURCES+=forwardData.v readBPMlink.v fofbReadLink.v fofbCalc.v psSetpointCalc.v
#SYNTH_SOURCES+=forwardData.v readBPMlink.v fofbReadLink.v
SYNTH_SOURCES+=reduceWidth.v fofbDataDPRAM.v
FOFB_LOOPBACK_SOURCES+=$(addprefix $(MODULES)/,$(SYNTH_SOURCES))

vpath %.v ../modules

fofb_loopback_tb: fofb_loopback_tb.v $(FOFB_LOOPBACK_SOURCES)
	$(VERILOG_TB)

cell_loop_check.vcd: fofb_loopback_tb
	vvp $< +df=$@

bpm_loop_check.vcd: fofb_loopback_tb
	vvp $< +df=$@

fifo_tb: fifo_tb.v forwardCellLinkMux.v stream_mux.v
	$(VERILOG_TB)

fifo_tb.vcd: fifo_tb
	vvp $< +df=$@


# ================================ Verilator ==================================
BUILD_DIR=$(TB_DIR)bin
$(BUILD_DIR):
	mkdir -p $^

CDEFINES=-I$(abspath $(GATEWARE_DIR)/tb) \
			 -I$(abspath $(SW_SRC_DIR)) \
			 -I$(abspath $(SW_TGT_DIR))/cctrl_marble \
			 -I$(abspath $(SW_TGT_DIR))/sim \
			 -I$(abspath $(SW_SRC_DIR))/bwudp \
			 -DMARBLE \
			 -DVERILATOR \
			 -DBWUDP_USE_REAL_GPIO_H

#CDEFINES+=-DDEBUG_PRINT

# Translation mapping of paths from source to object
CPU_SW_SRC=$(abspath $(SW_SRC_DIR))
CPU_SW_BIN=$(BUILD_DIR)/src
TB_SRC=$(abspath $(TB_DIR))
TB_BIN=$(BUILD_DIR)/tb

# ======= C Compilation =========
CC=gcc
# Temporary hack because the compiler complains about a few tiny issues
# with the code in the submodule. Need to push those changes.
BWUDP_DIR_HACK=$(SW_SRC_DIR)/bwudp
SW_SIM_DIR=$(SW_TGT_DIR)/sim
# Microblaze (CPU) C Sources
CPU_SOURCES=$(SW_SRC_DIR)/aurora.c \
						$(SW_SRC_DIR)/console.c \
						$(SW_SRC_DIR)/eebi.c \
						$(SW_SRC_DIR)/epics.c \
						$(SW_SRC_DIR)/evr.c \
						$(SW_SRC_DIR)/eyescan.c \
						$(SW_SRC_DIR)/fastFeedback.c \
						$(SW_SRC_DIR)/fofbEthernet.c \
						$(SW_SRC_DIR)/frontPanel.c \
						$(SW_SRC_DIR)/main.c \
						$(SW_SRC_DIR)/pilotTones.c \
						$(SW_SRC_DIR)/psAWG.c \
						$(SW_SRC_DIR)/psWaveformRecorder.c \
						$(SW_SRC_DIR)/qsfp.c \
						$(SW_SRC_DIR)/util.c \
						$(SW_SRC_DIR)/xadc.c \
						$(SW_SIM_DIR)/simplatform.c \
						$(SW_SIM_DIR)/uart_fifo.c \
						$(SW_SIM_DIR)/queue_ref.c \
						$(SW_SIM_DIR)/udp_io.c \
						$(BWUDP_DIR_HACK)/badger.c \
						$(BWUDP_DIR_HACK)/bwudp.c

#CPU_SRC_DIRS=$(SW_SRC_DIR) $(SW_SRC_DIR)/bwudp
#CPU_SOURCES=$(wildcard $(foreach var,$(CPU_SRC_DIRS),$(var)/*.c))
#C_SOURCES+=$(CPU_SOURCES)
#C_OBJECTS = $(addprefix $(BUILD_DIR)/,$(c_objects))
C_OBJECTS = $(subst $(CPU_SW_SRC),$(CPU_SW_BIN),$(patsubst %.c,%.o,$(CPU_SOURCES)))
#C_OBJECTS+= $(subst $(TB_SRC),$(TB_BIN),$(patsubst %.c,%.o,$(TB_C_SOURCES)))

define bldobj
$(1):$(2)
	mkdir -p $(dir $(1))
	$(CC) -c -MMD -MT"$(patsubst %.c,%.d,$<)" $(CFLAGS) $(CDEFINES) $(INCLUDES) -o $(1) $(2)
endef
$(foreach sf,$(CPU_SOURCES),$(eval $(call bldobj,$(subst $(CPU_SW_SRC),$(CPU_SW_BIN),$(patsubst %.c,%.o,$(sf))),$(sf))))
#$(foreach sf,$(TB_C_SOURCES),$(eval $(call bldobj,$(subst $(TB_SRC),$(TB_BIN),$(patsubst %.c,%.o,$(sf))),$(sf))))

#$(BUILD_DIR)/%.o: %.c
#	@$(ECHO) 'Compiling $<...'
#	$(MKDIR) $(dir $@)
#	$(CC) -c -MMD -MT"$(patsubst %.c,%.d,$<)" $(CFLAGS) $(CDEFINES) $(INCLUDES) -o $@ $<

# ====== C++ Compilation ========
# Empty right now

# Object directory created by verilator
VERILATOR_OBJ_DIR = obj_dir
# == NOTE! This Makefile assumes the first .cpp file encountered is the sim
# ==       source for verilator.  Override if that's not true.
SOURCES_NO_TB=stream_mux.v \
							forwardCellLinkMux.v \
							fofbReadLinksMux.v \
							readBPMlinksMux.v

VL_SIM=cctrl_top.cpp
VROOT=cctrl_verilator_top
VL_WRAPPER=$(TB_DIR)$(VROOT).v
VERILATOR_DEFINES = -DMARBLE -DTESTBENCH
VERILATOR_SUPRESSED_WARNINGS=WIDTHEXPAND \
														 UNUSEDSIGNAL \
														 UNUSEDPARAM \
														 PINCONNECTEMPTY \
														 VARHIDDEN \
														 WIDTHTRUNC
VERILATOR_NOWARN=$(addprefix -Wno-,$(VERILATOR_SUPRESSED_WARNINGS))

VERILATED_TOP = $(VERILATOR_OBJ_DIR)/V$(VROOT)

$(VERILATOR_OBJ_DIR):
	mkdir -p $@

VL_CFLAGS=$(addprefix -CFLAGS ,$(CDEFINES))
.PHONY: verilate
verilate: $(VERILATED_TOP)

$(VERILATED_TOP): $(VL_SIM) $(VL_WRAPPER) $(C_OBJECTS) $(CPP_OBJECTS)
	mkdir -p $(VERILATOR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build -Wall $(VERILATOR_NOWARN) $(VERILATOR_DEFINES) $(INCLUDES) $(VL_CFLAGS) $^

ifdef VROOT
vl_run: $(VERILATED_TOP)
	$(VERILATED_TOP)
else
vl_run:
	@echo "USAGE: make vl_run VROOT=<top_module_name>"
endif

CLEANS+=$(VERILATOR_OBJ_DIR)
CLEANS+=$(BUILD_DIR)

clean:
	rm -rf $(CLEANS)

