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

# udpFIFO ipcore generation for bmb7_udp

TARGET_PLATFORM_DIR = $(PLATFORM_DIR)/$(FPGA_VENDOR)/$(FPGA_PLATFORM)/$(FPGA_APPLICATION)
bmb7_udp_IP_CORES = udpFIFO

udpFIFO_DIR = $(TARGET_PLATFORM_DIR)/udpFIFO
udpFIFO_TOP = $(udpFIFO_DIR)/synth/udpFIFO.vhd
udpFIFO_VFLAGS_COMMAND_FILE = udpFIFO_iverilog_cfile.txt

bmb7_udp_IP_CORES_TOP_LVL_SRCS = $(udpFIFO_TOP)

# For top-level makefile
IP_CORES += $(bmb7_udp_IP_CORES)
IP_CORES_TOP_LVL_SRCS += $(bmb7_udp_IP_CORES_TOP_LVL_SRCS)
IP_CORES_DIRS += $(udpFIFO_DIR)
VFLAGS_COMMAND_FILE += \
					   $(udpFIFO_VFLAGS_COMMAND_FILE)
bmb7_udp_SRCS += \
			   $(TARGET_PLATFORM_DIR)/udpFIFO/synth/udpFIFO.vhd

IP_CORES_CUSTOM += bmb7_udp
IP_CORES_CUSTOM_TARGET_DIRS += $(bmb7_udp_TARGET)

bmb7_udp: $(bmb7_udp_SRCS)
	$(VIVADO_CREATE_IP) $@ $($@_TARGET) $($@_VERSION) $^
	touch $@

CLEAN += bmb7_udp
CLEAN_DIRS += $(bmb7_udp_TARGET)
