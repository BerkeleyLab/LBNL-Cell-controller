#!/bin/sh

IP=""
FILE="download.bit"

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

PYDIR="tools"
for ip in $IP
do
    # Clear out old image(s)
    HASH=`python2.7 $PYDIR/list_kintex_7_images.py -t "$ip" | sed -n -e '/SHA256: /s///p'`
    if [ \! -z "$HASH" ]
    then
        yes | python2.7 $PYDIR/erase_kintex_7_image.py -t "$ip" -s "$HASH"
        HASH=`python2.7 $PYDIR/list_kintex_7_images.py -t "$ip" | sed -n -e '/SHA256: /s///p'`
        if [ \! -z "$HASH" ]
        then
            echo "Didn't erase!" >&2
            exit 3
        fi
    fi

    # Add new image
    python2.7 $PYDIR/add_kintex_7_image.py -t "$ip" -b "$FILE"

    # Check (and get SHA key)
    HASH=`python2.7 $PYDIR/list_kintex_7_images.py -t "$ip" | sed -n -e '/SHA256: /s///p'`

    # Program that key as the one to boot
    python2.7 $PYDIR/program_spartan_6_configuration.py -t "$ip" -s "$HASH"
done
