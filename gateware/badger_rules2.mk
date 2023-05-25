# File: badger_rules.mk
# From bantamweightUDP/sup/Makefile

BEDROCK_DIR ?= ../submodules/bedrock
include $(BEDROCK_DIR)/dir_list.mk
# Include bedrock's 'top_rules' for common defines
include $(BUILD_DIR)/top_rules.mk

BADGER_MERGED = badgerMerged.v

all: $(BADGER_MERGED)

# Packet Badger synthesizable code
RTEFI_CLIENT_LIST = hello.v
include $(BADGER_DIR)/rules.mk

vpath %.v $(DSP_DIR) $(SERIAL_IO_DIR)

# Let's remove the temporary files in "RTEFI_CLEAN" right away
%/$(BADGER_MERGED): $(RTEFI_V)
	iverilog -E -o $@ $^
	rm -f $(RTEFI_CLEAN)

CLEAN += $(RTEFI_CLEAN) $(BADGER_MERGED)

include $(BUILD_DIR)/bottom_rules.mk
