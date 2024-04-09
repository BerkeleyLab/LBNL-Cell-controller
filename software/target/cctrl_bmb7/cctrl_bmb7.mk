__CCTRL_BMB7_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CCTRL_BMB7_DIR := $(__CCTRL_BMB7_DIR:/=)

__HDR_CCTRL_BMB7_FILES = \
	gpio.h \
	qsfp.h \
	iicProc.h \
	iicChunk.h \
	mgtClkSwitch.h \
	epics.h \
	mmcMailbox.h \
	bootFlash.h
HDR_CCTRL_BMB7_FILES = $(addprefix $(CCTRL_BMB7_DIR)/, $(__HDR_CCTRL_BMB7_FILES))

__SRC_CCTRL_BMB7_FILES = \
	qsfp.c \
	iicProc.c \
	iicChunk.c \
	mgtClkSwitch.c \
	epics.c \
	mmcMailbox.c \
	bootFlash.c
SRC_CCTRL_BMB7_FILES = $(addprefix $(CCTRL_BMB7_DIR)/, $(__SRC_CCTRL_BMB7_FILES))

# For top-level makfile
HDR_FILES += $(HDR_GEN_CCTRL_BMB7_FILES)
SRC_FILES += $(SRC_CCTRL_BMB7_FILES)

#clean::
#	$(RM) -rf $(HDR_GEN_CCTRL_BMB7_FILES)
