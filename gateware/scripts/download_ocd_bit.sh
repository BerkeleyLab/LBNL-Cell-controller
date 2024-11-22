#!/bin/sh
set -e

BITFILE=${BITFILE:-cctrl_aurora_64b66b_marble.bit}
EXTRA_OPTS=${EXTRA_OPTS}
THISDIR=$(dirname "$0")

if test -r "$BITFILE"; then
  openocd -s "$THISDIR" -f marble.cfg -c "${EXTRA_OPTS}" -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 $BITFILE; exit"
else
  echo "$BITFILE not found"
fi
