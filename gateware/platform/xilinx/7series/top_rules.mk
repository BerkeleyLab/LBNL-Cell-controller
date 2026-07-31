cell_controller_7series_platform_DIR = $(PLATFORM_DIR)/xilinx/7series

cell_controller_7series_platform_app_DIR = $(cell_controller_7series_platform_DIR)/$(FPGA_APPLICATION)

include $(cell_controller_7series_platform_app_DIR)/top_rules.mk
