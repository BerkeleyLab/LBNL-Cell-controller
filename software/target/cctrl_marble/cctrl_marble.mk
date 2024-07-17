__CCTRL_MARBLE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CCTRL_MARBLE_DIR := $(__CCTRL_MARBLE_DIR:/=)

__HDR_CCTRL_MARBLE_FILES = \
	gpio.h
HDR_CCTRL_MARBLE_FILES = $(addprefix $(CCTRL_MARBLE_DIR)/, $(__HDR_CCTRL_MARBLE_FILES))

# For top-level makfile
HDR_FILES += $(HDR_GEN_CCTRL_MARBLE_FILES)
#SRC_FILES +=

#clean::
#	$(RM) -rf
