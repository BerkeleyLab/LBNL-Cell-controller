include dir_list.mk

CROSS_COMPILE    ?=
PLATFORM         ?= marble
APP              ?= cctrl

TARGET       = $(APP)_$(PLATFORM)
GW_DIR       = $(GW_SYN_DIR)/$(TARGET)
BIT          = $(GW_DIR)/$(TARGET)_top.bit
SW_DIR       = $(SW_APP_DIR)/$(APP)

.PHONY: all bit sw download

all: bit sw bundle

bit:
	make -C $(GW_DIR) TARGET=$(TARGET) $(TARGET)_top.bit
	make -C $(GW_DIR) TARGET=$(TARGET) $(TARGET)_top.mmi

sw:
	make -C $(SW_DIR) TARGET=$(TARGET) BIT=$(BIT) all

bundle:
	make -C $(SW_DIR) TARGET=$(TARGET) BIT=$(BIT) bundle

swclean:
	make -C $(SW_DIR) TARGET=$(TARGET) clean

gwclean:
	make -C $(GW_DIR) TARGET=$(TARGET) clean

clean: swclean gwclean
	rm -f *.log *.jou

# Download bitstream to FPGA
download: $(SW_DIR)/download_$(PLATFORM).bit
	BITFILE=$< $(PROJECTS_DIR)/test_marble_family/mutil usb
#	openocd -f $(GW_SCRIPTS_DIR)/marble_openocd.cfg -c "init; pld load 0 $<; exit;"
#	xsct $(GW_SCRIPTS_DIR)/download_bit.tcl $(BIT)

# Run microblaze software from RAM (TODO)
run:
	xsct $(SW_SCRIPTS_DIR)/download_elf.tcl <psu_init_tcl> <elf>"
