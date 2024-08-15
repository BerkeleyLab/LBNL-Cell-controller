__THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
THIS_DIR := $(__THIS_DIR:/=)

include ../../../dir_list.mk

GIT_COMMIT	   := $(shell git rev-parse --short=8 --verify HEAD || echo "NOCOMMIT")

PLATFORM       := marble
APP            := cctrl_aurora_64b66b
SYSTEM_BD_NAME := system_aurora_64b66b

TARGET         := $(APP)_$(PLATFORM)
GW_TGT_DIR     := $(GW_SYN_DIR)/$(TARGET)
ELF            := $(THIS_DIR)/$(TARGET).elf

BIT            := $(GW_TGT_DIR)/$(TARGET)_top.bit
DEPLOY_BIT     := $(THIS_DIR)/$(TARGET).$(GIT_COMMIT).bit
MMI            := $(GW_TGT_DIR)/$(TARGET)_top.mmi

clean::
	rm -f *.log *.jou

include ../common_cctrl/Makefile
