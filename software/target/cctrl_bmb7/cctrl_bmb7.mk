__CCTRL_BMB7_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CCTRL_BMB7_DIR := $(__CCTRL_BMB7_DIR:/=)

__HDR_CCTRL_BMB7_FILES = \
	gpio.h
HDR_CCTRL_BMB7_FILES = $(addprefix $(CCTRL_BMB7_DIR)/, $(__HDR_CCTRL_BMB7_FILES))

# For top-level makfile
HDR_FILES += $(HDR_GEN_CCTRL_BMB7_FILES)
# SRC_FILES +=

# clean::
# 	$(RM) -rf
