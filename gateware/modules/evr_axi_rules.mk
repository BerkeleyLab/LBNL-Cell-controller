evr_axi_DIR = $(MODULES_DIR)/evr_axi
__evr_axi_SRCS = \
			   DataBufferCntrlr.v \
			   EventReceiverChannel.v \
			   EventReceiverTop.v \
			   evr_axi_S00_AXI.v \
			   evr_axi.v \
			   irq_forward.v \
			   timeofDayReceiver.v \
			   timestamp_forward.v
evr_axi_SRCS = $(addprefix $(evr_axi_DIR)/, $(__evr_axi_SRCS))
evr_axi_VERSION = 3.1
evr_axi_TARGET = _gen/evr_axi

# Mapping RAM ipcore generation for evr_axi

TARGET_PLATFORM_DIR = $(PLATFORM_DIR)/$(FPGA_VENDOR)/$(FPGA_PLATFORM)/$(FPGA_APPLICATION)
evr_axi_IP_CORES = MappingRam PacketMem timeStampFIFO

MappingRam_DIR = $(TARGET_PLATFORM_DIR)/MappingRam
MappingRam_TOP = $(MappingRam_DIR)/synth/MappingRam.vhd
MappingRam_VFLAGS_COMMAND_FILE = MappingRam_iverilog_cfile.txt
PacketMem_DIR = $(TARGET_PLATFORM_DIR)/PacketMem
PacketMem_TOP = $(PacketMem_DIR)/synth/PacketMem.vhd
PacketMem_VFLAGS_COMMAND_FILE = PacketMem_iverilog_cfile.txt
timeStampFIFO_DIR = $(TARGET_PLATFORM_DIR)/timeStampFIFO
timeStampFIFO_TOP = $(timeStampFIFO_DIR)/synth/timeStampFIFO.vhd
timeStampFIFO_VFLAGS_COMMAND_FILE = timeStampFIFO_iverilog_cfile.txt

evr_axi_IP_CORES_TOP_LVL_SRCS = $(MappingRam_TOP) $(PacketMem_TOP) $(timeStampFIFO_TOP)

# For top-level makefile
IP_CORES += $(evr_axi_IP_CORES)
IP_CORES_TOP_LVL_SRCS += $(evr_axi_IP_CORES_TOP_LVL_SRCS)
IP_CORES_DIRS += $(MappingRam_DIR) $(PacketMem_DIR) $(timeStampFIFO_DIR)
VFLAGS_COMMAND_FILE += \
					   $(MappingRam_VFLAGS_COMMAND_FILE) \
					   $(PacketMem_VFLAGS_COMMAND_FILE) \
					   $(timeStampFIFO_VFLAGS_COMMAND_FILE)
evr_axi_SRCS += \
			   $(TARGET_PLATFORM_DIR)/MappingRam/synth/MappingRam.vhd \
			   $(TARGET_PLATFORM_DIR)/PacketMem/synth/PacketMem.vhd \
			   $(TARGET_PLATFORM_DIR)/timeStampFIFO/synth/timeStampFIFO.vhd

IP_CORES_CUSTOM += evr_axi
IP_CORES_CUSTOM_TARGET_DIRS += $(evr_axi_TARGET)

evr_axi: $(evr_axi_SRCS)
	$(VIVADO_CREATE_IP) $@ $($@_TARGET) $($@_VERSION) $^
	touch $@

CLEAN_DIRS += $(evr_axi_TARGET)
