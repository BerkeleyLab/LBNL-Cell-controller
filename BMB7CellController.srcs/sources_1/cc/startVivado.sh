#!/bin/bash

APP="vivado -nolog -nojournal"
VERS="${XILINX_VERSION=2018.2}"

while [ $# -ne 0 ]
do
    case "$1" in
        [0-9.][0-9]*)          VERS="$1"    ;;
        b*)                     APP="bash"   ;;
        sdk|xsdk)               APP="xsdk"   ;;
        v*)                     APP="vivado -nolog -nojournal" ;;
        *) echo "Usage: $0 [#.#] [xsdk|vivado|bash]" >&2 ; exit 1 ;;
    esac
    shift
done

case `uname -m` in
    *_64)   b=64 ;;
    *)      b=32 ;;
esac
s="/eda/xilinx/$VERS/Vivado/$VERS/settings$b.sh"
if [ -f "$s" ]
then
    echo "Getting settings from \"$s\"."
    . "$s"
else
    echo "Can't find $s" >&2
    exit 2
fi

export XILINXD_LICENSE_FILE="27004@engvlic2.lbl.gov"
#export LD_PRELOAD_64=$HOME/src/XilinxSupport/usb-driver-HEAD-2d19c7c/libusb-driver.so
#export LD_LIBRARY_PATH="/eda/xilinx/$VERS/ISE_DS/ISE/lib/lin64:$HOME/lib/xilinxSupport"
case "$APP" in
    bash) "$APP" -l   ;;
    *)     mkdir -p "$HOME/xilinxPlaypen"
           cd "$HOME/xilinxPlaypen" # Leave logging dregs in one place
           $APP & ;;
esac
