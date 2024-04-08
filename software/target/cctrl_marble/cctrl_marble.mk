__CCTRL_MARBLE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CCTRL_MARBLE_DIR := $(__CCTRL_MARBLE_DIR:/=)

__HDR_CCTRL_MARBLE_FILES = \
	gpio.h \
	qsfp.h \
	iicProc.h \
	iicChunk.h \
	mgtClkSwitch.h \
	epics.h
HDR_CCTRL_MARBLE_FILES = $(addprefix $(CCTRL_MARBLE_DIR)/, $(__HDR_CCTRL_MARBLE_FILES))

__SRC_CCTRL_MARBLE_FILES = \
	qsfp.c \
	iicProc.c \
	iicChunk.c \
	mgtClkSwitch.c \
	epics.c
SRC_CCTRL_MARBLE_FILES = $(addprefix $(CCTRL_MARBLE_DIR)/, $(__SRC_CCTRL_MARBLE_FILES))

# For top-level makfile
HDR_FILES += $(HDR_GEN_CCTRL_MARBLE_FILES)
SRC_FILES += $(SRC_CCTRL_MARBLE_FILES)

#clean::
#	$(RM) -rf $(HDR_GEN_CCTRL_MARBLE_FILES)
