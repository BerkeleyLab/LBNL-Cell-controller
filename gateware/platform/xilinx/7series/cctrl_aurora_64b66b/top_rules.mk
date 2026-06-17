cell_controller_IP_CORES = \
	psSetpointCalcFixToFloat \
	evrmgt \
	psSetpointCalcConvertToAmps \
	fofbPCS_PMA_with_shared_logic \
	fixToFloat \
	fofbSupplyFilter \
	fofbPCS_PMA_without_shared_logic \
	floatResultFIFO \
	linkStatisticsMux \
	fofbCoefficientMul \
	floatToDouble \
	floatMultiply \
	ila_td256_s4096_cap

cell_controller_IP_CORES_DIRS = $(addprefix $(cell_controller_7series_platform_app_DIR)/, $(cell_controller_IP_CORES))

# For top-level makefile
IP_CORES_TCLS += $(addsuffix .tcl, $(cell_controller_IP_CORES))
IP_CORES_DIRS += $(cell_controller_IP_CORES_DIRS)

cell_controller_BD_CORE = \
	system_aurora_64b66b

cell_controller_BD_CORE_DIR = $(addprefix $(cell_controller_7series_platform_app_DIR)/, $(cell_controller_BD_CORE))

# For top-level makefile
BD_CORE_BDS += $(addprefix $(cell_controller_BD_CORE_DIR)/, $(addsuffix .bd, $(cell_controller_BD_CORE)))
BD_CORE_DIRS += \
	$(cell_controller_BD_CORE_DIR) \
	$(addsuffix /synth, $(cell_controller_BD_CORE_DIR)) \
	$(addsuffix /hdl, $(cell_controller_BD_CORE_DIR))

vpath %.tcl $(IP_CORES_DIRS) $(BD_CORE_DIRS)
vpath %.bd $(BD_CORE_DIRS)

%.bd: %.tcl axi_lite_generic_reg evr_axi drp_bridge
	$(VIVADO_CMD) -source $(GW_SCRIPTS_DIR)/bd_tcl_proc.tcl $(GW_SCRIPTS_DIR)/gen_bd_tcl.tcl  -tclargs $< $(PROJECT_PART) $(PROJECT_BOARD) $(IP_CORES_CUSTOM_TARGET_DIRS)
