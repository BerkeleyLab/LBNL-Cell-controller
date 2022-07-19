#!/bin/bash

set -eu

STP_FILES=$@

SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

idx=0
for f in $STP_FILES
do
    python3 ${SCRIPTPATH}/ad9520stp2c.py < $f | sed -e "s/XXXX/pt${idx}table/g"
    idx=$((idx + 1))
done
