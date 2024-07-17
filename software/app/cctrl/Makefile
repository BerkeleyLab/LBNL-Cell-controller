__THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(__THIS_DIR:/=)

CROSS_COMPILE ?= mb-
CC = $(CROSS_COMPILE)gcc
SIZE = $(CROSS_COMPILE)size
XSCT ?= xsct -norlwrap

include ../../../dir_list.mk

GIT_COMMIT	= $(shell git rev-parse --short=8 --verify HEAD || echo "NOCOMMIT")

APP         ?= cctrl
PLATFORM    ?= marble
TARGET      = $(APP)_$(PLATFORM)
GW_TGT_DIR  = $(GW_SYN_DIR)/$(TARGET)
BIT         ?= $(GW_TGT_DIR)/$(TARGET)_top.bit
DEPLOY_BIT  ?= $(THIS_DIR)/$(TARGET).$(GIT_COMMIT).bit
MMI         ?= $(GW_TGT_DIR)/$(TARGET)_top.mmi
ELF         ?= $(THIS_DIR)/$(TARGET).elf

SW_APP_TGT_DIR = $(SW_APP_DIR)/$(APP)
SW_TGT_SCRIPTS_DIR = $(SW_APP_DIR)/$(APP)/scripts

CPU_NAME   = microblaze_0
TARGET_DIR = $(SW_TGT_DIR)/$(TARGET)
BSP_DIR   = $(SW_APP_TGT_DIR)/$(TARGET)/platform/$(CPU_NAME)/standalone_domain/bsp/$(CPU_NAME)

all: $(TARGET) $(TARGET).elf $(TARGET).elf.size $(DEPLOY_BIT)

__SRC_FILES = \
	aurora.c \
	console.c \
	evr.c \
	eyescan.c \
	fastFeedback.c \
	fofbEthernet.c \
	main.c \
	platform.c \
	psAWG.c \
	psWaveformRecorder.c \
	util.c \
	xadc.c \
	qsfp.c \
	iicProc.c \
	iicChunk.c \
	mgtClkSwitch.c \
	epics.c \
	mmcMailbox.c \
	bootFlash.c \
	systemParameters.c \
	tftp.c
SRC_FILES = $(addprefix $(SW_SRC_DIR)/, $(__SRC_FILES))

__HDR_FILES = \
	aurora.h \
	cellControllerProtocol.h \
	console.h \
	evr.h \
	eyescan.h \
	fastFeedback.h \
	fofbEthernet.h \
	platform_config.h \
	platform.h \
	psAWG.h \
	psWaveformRecorder.h \
	util.h \
	xadc.h \
	qsfp.h \
	iicProc.h \
	iicChunk.h \
	mgtClkSwitch.h \
	epics.h \
	mmcMailbox.h \
	bootFlash.h \
	systemParameters.h \
	tftp.h
HDR_FILES = $(addprefix $(SW_SRC_DIR)/, $(__HDR_FILES))

__HDR_BWUDP_FILES = \
	bwudp_config.h \
	bwudp.h
HDR_BWUDP_FILES = $(addprefix $(BWUDP_DIR)/, $(__HDR_BWUDP_FILES))

__SRC_SPIFLASHDRIVER_FILES = \
    spiflash.c
SRC_SPIFLASHDRIVER_FILES = $(addprefix $(SW_SPIFLASHDRIVER_DIR)/, $(__SRC_SPIFLASHDRIVER_FILES))

__HDR_SPIFLASHDRIVER_FILES = \
    spiflash.h
HDR_SPIFLASHDRIVER_FILES = $(addprefix $(SW_SPIFLASHDRIVER_DIR)/, $(__HDR_SPIFLASHDRIVER_FILES))

__HDR_GEN_FILES =
HDR_GEN_FILES = $(addprefix $(SW_SRC_DIR)/, $(__HDR_GEN_FILES))

__SRC_BWUDP_FILES = \
	badger.c \
	bwudp.c
SRC_BWUDP_FILES = $(addprefix $(BWUDP_DIR)/, $(__SRC_BWUDP_FILES))

SRC_FILES += $(SRC_BWUDP_FILES)
HDR_FILES += $(HDR_BWUDP_FILES)
SRC_FILES += $(SRC_SPIFLASHDRIVER_FILES)
HDR_FILES += $(HDR_SPIFLASHDRIVER_FILES)

include $(TARGET_DIR)/$(TARGET).mk

OBJ_FILES = $(SRC_FILES:.c=.o)
LINKER_FILES = $(SW_SRC_DIR)/lscript.ld

CFLAGS = -Wall -O2 -mlittle-endian -mxl-barrel-shift -mno-xl-soft-div -mcpu=v11.0 -mno-xl-soft-mul -ffunction-sections -fdata-sections
LD_FLAGS = -Wl,-T -Wl,$(LINKER_FILES) -Wl,--no-relax
USER_FLAGS = -D__BAREMETAL__
LIB_DIRS = $(BSP_DIR)/lib
LIB_FLAGS = $(addprefix -L, $(LIB_DIRS))
LIBS = -Wl,--start-group,-lxil,-lgcc,-lc,--end-group

INCLUDE_DIRS = \
	$(SW_SRC_DIR) \
	$(TARGET_DIR) \
	$(BSP_DIR)/include

ifeq ($(TARGET),cctrl_marble)
USER_FLAGS += -D__TARGET_CCTRL_MARBLE__
USER_FLAGS += -DMARBLE
USER_FLAGS += -DBWUDP_USE_REAL_GPIO_H
INCLUDE_DIRS += $(BWUDP_DIR)
INCLUDE_DIRS += $(SW_SPIFLASHDRIVER_DIR)
else
USER_FLAGS += -D__TARGET_NOT_RECOGNIZED__
endif

INCLUDE_FLAGS = $(addprefix -I, $(INCLUDE_DIRS))

.PHONY: all clean bsp

vpath *.c $(SW_SRC_DIR) $(TARGET_DIR)
vpath *.h $(SW_SRC_DIR) $(TARGET_DIR)
vpath *.o $(SW_SRC_DIR)
vpath *.mmi $(GW_TGT_DIR)

# FIXME: We are considering BSP done if the directory exists. This
# could lead to mismatches!
XSA_FILE=$(GW_TGT_DIR)/system.xsa

$(TARGET):
	$(XSCT) $(SW_SCRIPTS_DIR)/gen_vitis_platform.tcl $@ $(XSA_FILE) $(CPU_NAME)

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
	$(RM) -rf $(TARGET).elf $(TARGET).elf.size $(DEPLOY_BIT) $(HDR_GEN_FILES) \
		$(OBJ_FILES) $(OBJ_FILES:.o=.d) $(TARGET)
