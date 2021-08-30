#!/bin/sh

DEST="../../../BMB7CellController.srcs/sources_1/cc/gpioIDX.v"

#
# Create Verilog definitions of GPIO indexes
#
(
echo '// DO NOT EDIT -- CHANGES WILL BE OVERWRITTEN WHEN'
echo '// THIS FILE IS REGENERATED FROM THE C HEADER FILE'
sed -n -e '/ *# *include/q' \
       -e '/ *# *define *\(GPIO_[^ ]*\) *\([0-9][0-9]*\).*/s//parameter \1 = \2;/p' \
                gpio.h
) >"$DEST"
