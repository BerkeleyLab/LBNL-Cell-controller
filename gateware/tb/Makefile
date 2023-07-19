# A quick Makefile

HERE=./.
VERILATOR = verilator
MODS=../modules
SW_SRC=../../software/src

SOURCES = $(MODS)/qsfpMarble.v

C_SOURCES=$(SW_SRC)/qsfp.c

SIM_DEFINES =-DSIMULATE
INCLUDES=-I$(HERE) -I$(SW_SRC) -I$(MODS)
TB_DIR = .

# ================================ Verilator ==================================
# == Note: Verilator header files are in /usr/local/share/verilator
# ==       There are useful examples there as well
# Object directory created by verilator
VERILATOR_OBJ_DIR = obj_dir
CPP_SOURCES=qsfpMarble_top_sim.cpp
# == NOTE! This Makefile assumes the first .cpp file encountered is the sim
# ==       source for verilator.  Override if that's not true.
SOURCES_NO_TB=$(filter-out %_tb.v,$(SOURCES))
VL_SIM = $(firstword $(CPP_SOURCES))
VROOT=qsfpMarble_top
VL_WRAPPER=$(TB_DIR)/$(VROOT).v

VERILATOR_SUPRESSED_WARNINGS=WIDTHEXPAND \
														 UNUSEDSIGNAL \
														 UNUSEDPARAM \
														 PINCONNECTEMPTY
VERILATOR_NOWARN=$(addprefix -Wno-,$(VERILATOR_SUPRESSED_WARNINGS))

VERILATED_TOP = $(VERILATOR_OBJ_DIR)/V$(VROOT)

$(VERILATOR_OBJ_DIR):
	mkdir -p $@

verilate: $(VL_SIM) $(VL_WRAPPER) $(C_SOURCES) $(SOURCES_NO_TB)
	mkdir -p $(VERILATOR_OBJ_DIR)
	$(VERILATOR) --cc --exe --build -Wall $(VERILATOR_NOWARN) $(SIM_DEFINES) $(INCLUDES) $^ -CFLAGS -I/home/kpenney/repos/cell-controller/gateware/tb -CFLAGS -I/home/kpenney/repos/cell-controller/software/src

ifdef VROOT
vl_run: $(VERILATED_TOP)
	$(VERILATED_TOP)
else
vl_run:
	@echo "USAGE: make vl_run VROOT=<top_module_name>"
endif

CLEANS+=$(VERILATOR_OBJ_DIR)


