#!/bin/sh

set -x

rm -f updatemem.jou updatemem.log

updatemem -force \
  -meminfo ../../CellController_hw_platform_0/CellController.mmi \
  -bit ../../CellController_hw_platform_0/CellController.bit \
  -data ../Release/CellControllerApp.elf \
  -proc system_i/microblaze_0 \
  -out ../../CellController_hw_platform_0/download.bit 
