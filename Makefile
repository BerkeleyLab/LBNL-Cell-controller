include dir_list.mk

CROSS_COMPILE    ?=
PLATFORM         ?= marble
APP              ?= cctrl

TARGET       = $(APP)_$(PLATFORM)
GW_TGT_DIR   = $(GW_SYN_DIR)/$(TARGET)
BIT          = $(GW_TGT_DIR)/$(TARGET)_top.bit
SW_TGT_DIR   = $(SW_APP_DIR)/$(APP)

.PHONY: all bit sw download

all: bit sw

bit:
	make -C $(GW_TGT_DIR) TARGET=$(TARGET) $(TARGET)_top.bit
	make -C $(GW_TGT_DIR) TARGET=$(TARGET) $(TARGET)_top.mmi

sw:
	make -C $(SW_TGT_DIR) TARGET=$(TARGET) BIT=$(BIT) all

swclean:
	make -C $(SW_TGT_DIR) TARGET=$(TARGET) clean

gwclean:
	make -C $(GW_TGT_DIR) TARGET=$(TARGET) clean

clean: swclean gwclean
	rm -f *.log *.jou
