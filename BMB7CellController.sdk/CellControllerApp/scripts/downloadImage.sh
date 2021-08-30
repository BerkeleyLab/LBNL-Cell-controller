#!/bin/sh

IP=""
FILE="../../CellController_hw_platform_0/download.bit"

usage() {
    echo "Usage: $0 [IP_ADDRESS] [download.bit]" >&2
    exit 1
}
for i
do
    case "$i" in
    [0-9]*.[0-9]*.[0-9]*.[0-9]*) IP="$IP $i"  ;;
    *.bit) FILE="$i" ;;
    *) echo $i ; usage ;;
    esac
done

if [ -z "$IP" ]
then
    IP="192.168.1.222"
fi
if [ \! -r "$FILE" ]
then
    echo "Can't open \"$FILE\"" >&2
    exit 2
fi

set -ex

PYDIR="tools"
for ip in $IP
do
    python2.7 $PYDIR/program_kintex_7.py -t "$ip" -b "$FILE" &
done
wait
