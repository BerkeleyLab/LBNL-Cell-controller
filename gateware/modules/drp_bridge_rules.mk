drp_bridge_DIR = $(MODULES_DIR)/drp_bridge
__drp_bridge_SRCS = \
	drp_bridge.v
drp_bridge_SRCS = $(addprefix $(drp_bridge_DIR)/, $(__drp_bridge_SRCS))
drp_bridge_VERSION = 1.0
drp_bridge_TARGET = _gen/drp_bridge

# For top-level makefile
IP_CORES_CUSTOM += drp_bridge
IP_CORES_CUSTOM_TARGET_DIRS += $(drp_bridge_TARGET)

drp_bridge: $(drp_bridge_SRCS)
	$(VIVADO_CMD) -source $(BUILD_DIR)/vivado_tcl/lbl_ip.tcl -source $(drp_bridge_DIR)/prop.tcl $(BUILD_DIR)/vivado_tcl/create_ip.tcl -tclargs $@ $($@_TARGET) $($@_VERSION) $^
	touch $@

CLEAN += drp_bridge
CLEAN_DIRS += $(drp_bridge_TARGET)
