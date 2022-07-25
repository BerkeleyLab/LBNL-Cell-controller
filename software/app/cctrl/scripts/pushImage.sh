#!/bin/sh

# Send FPGA update to production machine

set -ex

tar -c -z -f ccFPGA.tgz tools downloadImage.sh flashImage.sh cable.sh download.bit
scp ccFPGA.tgz enorum@access.als.lbl.gov:/vxboot/siocsrcc/head/FPGA
ssh enorum@access.als.lbl.gov "cd /vxboot/siocsrcc/head/FPGA ; tar xf ccFPGA.tgz ; rm -f ccFPGA.tgz"
rm ccFPGA.tgz

