TOP := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

GATEWARE_DIR       = $(TOP)gateware
SOFTWARE_DIR       = $(TOP)software

# Gateware

SUBMODULES_DIR     = $(GATEWARE_DIR)/submodules
MODULES_DIR        = $(GATEWARE_DIR)/modules
PLATFORM_DIR       = $(GATEWARE_DIR)/platform
GW_SCRIPTS_DIR     = $(GATEWARE_DIR)/scripts

BEDROCK_DIR        = $(SUBMODULES_DIR)/bedrock
PLATFORM_BMB7_DIR  = $(PLATFORM_DIR)/xilinx/bmb7
PLATFORM_BMB7_CCTRL_DIR  = $(PLATFORM_BMB7_DIR)/cctrl


GW_SYN_DIR         = $(GATEWARE_DIR)/syn

# Sofware

SW_LIBS_DIR        = $(SOFTWARE_DIR)/libs
SW_TGT_DIR         = $(SOFTWARE_DIR)/target
SW_SCRIPTS_DIR     = $(SOFTWARE_DIR)/scripts
SW_SRC_DIR     	   = $(SOFTWARE_DIR)/src
SW_APP_DIR         = $(SOFTWARE_DIR)/app

# Cell Controller Sofware

SW_CCTRL_DIR         = $(SW_APP_DIR)/cctrl
SW_CCTRL_SCRIPTS_DIR = $(SW_BPM_DIR)/scripts

include $(BEDROCK_DIR)/dir_list.mk
