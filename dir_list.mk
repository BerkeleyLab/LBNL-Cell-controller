TOP := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

GATEWARE_DIR       = $(TOP)gateware
SOFTWARE_DIR       = $(TOP)software

# Gateware
SUBMODULES_DIR     = $(GATEWARE_DIR)/submodules
MODULES_DIR        = $(GATEWARE_DIR)/modules
PLATFORM_DIR       = $(GATEWARE_DIR)/platform
GW_SCRIPTS_DIR     = $(GATEWARE_DIR)/scripts

BEDROCK_DIR        = $(SUBMODULES_DIR)/bedrock
ETHERNET_CORE_DIR  = $(SUBMODULES_DIR)/ethernet-core
BWUDP_DIR          = $(SUBMODULES_DIR)/bwudp

GW_TOP_DIR         = $(GATEWARE_DIR)/top
GW_TOP_COMMON_DIR  = $(GW_TOP_DIR)/common_cctrl
GW_SYN_DIR         = $(GATEWARE_DIR)/syn

# Software
SW_LIBS_DIR        = $(SOFTWARE_DIR)/libs
SW_TGT_DIR         = $(SOFTWARE_DIR)/target
SW_SCRIPTS_DIR     = $(SOFTWARE_DIR)/scripts
SW_SRC_DIR     	   = $(SOFTWARE_DIR)/src
SW_APP_DIR         = $(SOFTWARE_DIR)/app
SW_SUBMODULES_DIR  = $(SOFTWARE_DIR)/submodules

SW_SPIFLASHDRIVER_DIR = $(SW_SUBMODULES_DIR)/spiflash_driver/src

include $(BEDROCK_DIR)/dir_list.mk
# Don't include this as it will overwrite some previously defined variables
# include $(ETHERNET_CORE_DIR)/dir_list.mk
CORE_DIR           = $(ETHERNET_CORE_DIR)/core
CLIENTS_DIR        = $(ETHERNET_CORE_DIR)/clients
CRC_DIR            = $(ETHERNET_CORE_DIR)/crc
MODEL_DIR          = $(ETHERNET_CORE_DIR)/model
