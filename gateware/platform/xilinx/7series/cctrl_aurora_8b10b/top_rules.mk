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
	system_aurora_8b10b

cell_controller_BD_CORE_DIRS = $(addprefix $(cell_controller_7series_platform_app_DIR)/, $(cell_controller_BD_CORE))

# For top-level makefile
BD_CORE_TCLS += $(addsuffix .tcl, $(cell_controller_BD_CORE))
BD_CORE_DIRS += \
	$(cell_controller_BD_CORE_DIRS) \
	$(addsuffix /synth, $(cell_controller_BD_CORE_DIRS)) \
	$(addsuffix /hdl, $(cell_controller_BD_CORE_DIRS))

vpath %.tcl $(IP_CORES_DIRS) $(BD_CORE_DIRS)
vpath %.bd $(BD_CORE_DIRS)
