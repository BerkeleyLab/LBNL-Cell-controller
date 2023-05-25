# File: badger_rules.mk
# From bwudp/sup/Makefile

bwUDP_DIR = $(BWUDP_DIR)
__bwUDP_SRCS = \
							badger.v
bwUDP_SRCS = $(addprefix $(bwUDP_DIR)/, $(__bwUDP_SRCS))
bwUDP_TARGET = _gen/bwUDP

IP_CORES_DIRS += $(bwUDP_DIR)
IP_CORES_CUSTOM += bwUDP
IP_CORES_CUSTOM_TARGET_DIRS += $(bwUDP_TARGET)

bwUDP: $(bwUDP_SRCS)
	mkdir -p $($@_TARGET)
	cp $(bwUDP_SRCS) $($@_TARGET)/
	touch $@

# Include bagder rules from bedrock
RTEFI_CLIENT_LIST = hello.v
include $(BEDROCK_DIR)/badger/rules.mk

vpath %.v $(bwUDP_TARGET)

CLEAN += bwUDP
CLEAN_DIRS += $(bwUDP_TARGET)


