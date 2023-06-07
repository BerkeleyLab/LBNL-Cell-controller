include dir_list.mk

CROSS_COMPILE    ?=
PLATFORM         ?= marble
APP              ?= cctrl

TARGET       = $(APP)_$(PLATFORM)
GW_TGT_DIR   = $(GW_SYN_DIR)/$(TARGET)
BIT          = $(GW_TGT_DIR)/$(TARGET)_top.bit
# WRONG! Clobbers SW_TGT_DIR from dir_list.mk
#SW_TGT_DIR   = $(SW_APP_DIR)/$(APP)
# Instead, let's clobber this which is identity if APP==cctrl
SW_CCTRL_APP_DIR     = $(SW_APP_DIR)/$(APP)

.PHONY: all bit sw download

all: bit sw bundle

bit:
	make -C $(GW_TGT_DIR) TARGET=$(TARGET) $(TARGET)_top.bit

sw:
	make -C $(SW_CCTRL_APP_DIR) TARGET=$(TARGET) BIT=$(BIT) all
#	make -C $(SW_TGT_DIR) TARGET=$(TARGET) BIT=$(BIT) all

bundle:
	make -C $(SW_TGT_DIR) TARGET=$(TARGET) BIT=$(BIT) bundle

swclean:
	make -C $(SW_CCTRL_APP_DIR) TARGET=$(TARGET) clean

gwclean:
	make -C $(GW_TGT_DIR) TARGET=$(TARGET) clean

clean: swclean gwclean
	rm -f *.log *.jou

# Download bitstream to FPGA
download: $(BIT)
	openocd -f $(GW_SCRIPTS_DIR)marble_openocd.cfg -c "init; pld load 0 $<; exit;"
#	xsct $(GW_SCRIPTS_DIR)/download_bit.tcl $(BIT)

# Run microblaze software from RAM
run:
	xsct load_mb.tcl $$(hostname) <fw.elf>
