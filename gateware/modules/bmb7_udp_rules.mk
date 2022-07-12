bmb7_udp_DIR = $(MODULES_DIR)/bmb7_udp
__bmb7_udp_SRCS = \
	UDPport.v \
	bmb7_udp.v \
	bmb7_udp_S_AXI.v \
	rx8b9b.v \
	tx8b9b.v
bmb7_udp_SRCS = $(addprefix $(bmb7_udp_DIR)/, $(__bmb7_udp_SRCS))
bmb7_udp_VERSION = 1.1
bmb7_udp_TARGET = _gen/bmb7_udp

# For top-level makefile
IP_CORES_CUSTOM += bmb7_udp
IP_CORES_CUSTOM_TARGET_DIRS += $(bmb7_udp_TARGET)

bmb7_udp: $(bmb7_udp_SRCS)
	$(VIVADO_CREATE_IP) $@ $($@_TARGET) $($@_VERSION) $^
	touch $@

CLEAN_DIRS += $(bmb7_udp_TARGET)
