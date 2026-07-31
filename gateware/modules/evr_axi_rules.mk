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

evr_axi_TCLS = $(foreach ip_core, $(evr_axi_IP_CORES), $(addprefix $(TARGET_PLATFORM_DIR)/$(ip_core)/,$(addsuffix .tcl, $(ip_core))))

evr_axi_SRCS += $(evr_axi_TCLS)

IP_CORES_CUSTOM += evr_axi
IP_CORES_CUSTOM_TARGET_DIRS += $(evr_axi_TARGET)

evr_axi: $(evr_axi_SRCS)
	$(VIVADO_CREATE_IP) $@ $($@_TARGET) $($@_VERSION) $^
	touch $@

CLEAN_DIRS += $(evr_axi_TARGET)
