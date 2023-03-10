__THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(__THIS_DIR:/=)

CROSS_COMPILE ?= mb-
CC = $(CROSS_COMPILE)gcc
SIZE = $(CROSS_COMPILE)size
XSCT ?= xsct -norlwrap

include ../../../dir_list.mk

TARGET   ?= cctrl_bmb7
GW_CCTRL_TGT_DIR = $(GW_SYN_DIR)/$(TARGET)
BIT      ?= $(GW_CCTRL_TGT_DIR)/$(TARGET)_top.bit
DEPLOY_BIT ?= $(THIS_DIR)/download.bit
MMI      ?= $(GW_CCTRL_TGT_DIR)/$(TARGET)_top.mmi
ELF 	 ?= $(THIS_DIR)/$(TARGET).elf

CPU_NAME   = microblaze_0
TARGET_DIR = $(SW_TGT_DIR)/$(TARGET)
BSP_DIR   = $(SW_CCTRL_APP_DIR)/$(TARGET)/platform/$(CPU_NAME)/standalone_domain/bsp/$(CPU_NAME)

all: $(TARGET) $(TARGET).elf $(TARGET).elf.size

bundle: $(DEPLOY_BIT)

__SRC_FILES = \
	aurora.c \
	console.c \
	eebi.c \
	epics.c \
	evr.c \
	eyescan.c \
	fastFeedback.c \
	fofbEthernet.c \
	frontPanel.c \
	main.c \
	pilotTones.c \
	platform.c \
	psAWG.c \
	psWaveformRecorder.c \
	qsfp.c \
	util.c \
	xadc.c
SRC_FILES = $(addprefix $(SW_SRC_DIR)/, $(__SRC_FILES))

__HDR_FILES = \
	ad9520Tables.h \
	aurora.h \
	cellControllerProtocol.h \
	console.h \
	eebi.h \
	epics.h \
	evr.h \
	eyescan.h \
	fastFeedback.h \
	fofbEthernet.h \
	frontPanel.h \
	pilotTones.h \
	platform_config.h \
	platform.h \
	psAWG.h \
	psWaveformRecorder.h \
	qsfp.h \
	util.h \
	xadc.h
HDR_FILES = $(addprefix $(SW_SRC_DIR)/, $(__HDR_FILES))

__HDR_GEN_FILES = \
	softwareBuildDate.h
HDR_GEN_FILES = $(addprefix $(SW_SRC_DIR)/, $(__HDR_GEN_FILES))

__SRC_BMB7UDP_FILES = \
	bmb7_udp.c
SRC_BMB7UDP_FILES = $(addprefix $(BMB7UDP_DIR)/, $(__SRC_BMB7UDP_FILES))

SRC_FILES += $(SRC_BMB7UDP_FILES)

__HDR_BMB7UDP_FILES = \
	bmb7_udp.h
HDR_BMB7UDP_FILES = $(addprefix $(BMB7UDP_DIR)/, $(__HDR_BMB7UDP_FILES))

HDR_FILES += $(HDR_BMB7UDP_FILES)

__STP_FILES = \
	AD9520-4_IDLE.stp \
	AD9520-4_PT_HI_11_19.stp \
	AD9520-4_PT_HI_1_2.stp \
	AD9520-4_PT_LO_11_19.stp \
	AD9520-4_PT_LO_1_2.stp \
	AD9520-4_RF_11_19_compat.stp \
	AD9520-4_RF.stp
STP_FILES = $(addprefix $(SW_CCTRL_SCRIPTS_DIR)/, $(__STP_FILES))

include $(TARGET_DIR)/$(TARGET).mk

OBJ_FILES = $(SRC_FILES:.c=.o)
LINKER_FILES = $(SW_SRC_DIR)/lscript.ld

CFLAGS = -Wall -O2 -mlittle-endian -mxl-barrel-shift -mno-xl-soft-div -mcpu=v11.0 -mno-xl-soft-mul -ffunction-sections -fdata-sections
LD_FLAGS = -Wl,-T -Wl,$(LINKER_FILES) -Wl,--no-relax
USER_FLAGS = -D__BAREMETAL__
LIB_DIRS = $(BSP_DIR)/lib
LIB_FLAGS = $(addprefix -L, $(LIB_DIRS))
LIBS = -Wl,--start-group,-lxil,-lgcc,-lc,--end-group

ifeq ($(TARGET),cctrl_bmb7)
	USER_FLAGS += -D__TARGET_CCTRL_BMB7__
else
	USER_FLAGS += -D__TARGET_NOT_RECOGNIZED__
endif

INCLUDE_DIRS = \
	$(SW_SRC_DIR) \
	$(TARGET_DIR) \
	$(BMB7UDP_DIR) \
	$(BSP_DIR)/include
INCLUDE_FLAGS = $(addprefix -I, $(INCLUDE_DIRS))

.PHONY: all clean bsp

vpath *.c $(SW_SRC_DIR) $(TARGET_DIR)
vpath *.h $(SW_SRC_DIR) $(TARGET_DIR)
vpath *.o $(SW_SRC_DIR)
vpath *.mmi $(GW_CCTRL_TGT_DIR)

%softwareBuildDate.h: $(SRC_FILES) $(HDR_FILES)
	sh $(SW_CCTRL_SCRIPTS_DIR)/setSoftwareBuildDate.sh > $@

%ad9520Tables.h: $(STP_FILES)
	bash $(SW_CCTRL_SCRIPTS_DIR)/createPLLtables.sh $^ > $@

# FIXME: We are considering BSP done if the directory exists. This
# could lead to mismatches!
$(TARGET):
	$(XSCT) $(SW_SCRIPTS_DIR)/gen_vitis_platform.tcl $@ $(GW_CCTRL_TGT_DIR)/system.xsa $(CPU_NAME)

$(TARGET).elf: $(HDR_FILES) $(HDR_GEN_FILES) $(OBJ_FILES) $(LINKER_FILES)
	$(CC) $(CFLAGS) $(USER_FLAGS) $(INCLUDE_FLAGS) $(LIB_FLAGS) $(LD_FLAGS) -o $@ $(filter %.o, $^) $(LIBS)

$(TARGET).elf.size: $(TARGET).elf
	$(SIZE) $< | tee $@

$(DEPLOY_BIT): $(MMI) $(BIT) $(ELF)
	rm -f updatemem.jou updatemem.log
	updatemem -force -meminfo $< -bit $(BIT) \
		-data $(ELF) -proc system_i/$(CPU_NAME) \
		-out $@

# Pull in dependency info for *existing* .o files and don't complain if the
# corresponding .d file is not found
-include $(OBJ_FILES:.o=.d)

%.o: %.c
	$(CC) -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" $(CFLAGS) $(USER_FLAGS) $(INCLUDE_FLAGS) -c $*.c -o $@

clean::
	$(RM) -rf $(TARGET).elf $(TARGET).elf.size $(HDR_GEN_FILES) \
		$(OBJ_FILES) $(OBJ_FILES:.o=.d) $(TARGET)
