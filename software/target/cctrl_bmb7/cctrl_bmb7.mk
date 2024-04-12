__CCTRL_BMB7_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CCTRL_BMB7_DIR := $(__CCTRL_BMB7_DIR:/=)

__HDR_CCTRL_BMB7_FILES = \
	gpio.h
HDR_CCTRL_BMB7_FILES = $(addprefix $(CCTRL_BMB7_DIR)/, $(__HDR_CCTRL_BMB7_FILES))

__SRC_CCTRL_BMB7_FILES = \
	qsfp.c \
	epics.c \
	iicProcStub.c \
	iicChunkStub.c \
	mgtClkSwitchStub.c \
	mmcMailboxStub.c \
	bootFlashStub.c \
	tftpStub.c \
	systemParametersStub.c
SRC_CCTRL_BMB7_FILES = $(addprefix $(CCTRL_BMB7_DIR)/, $(__SRC_CCTRL_BMB7_FILES))

# For top-level makfile
HDR_FILES += $(HDR_GEN_CCTRL_BMB7_FILES)
SRC_FILES += $(SRC_CCTRL_BMB7_FILES)

#clean::
#	$(RM) -rf $(HDR_GEN_CCTRL_BMB7_FILES)
