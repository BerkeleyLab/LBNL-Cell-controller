#!/bin/sh

set -ex

(
cd ../scripts
python ad9520stp2c.py <AD9520-4_IDLE.stp | sed -e 's/XXXX/pt0table/'
python ad9520stp2c.py <AD9520-4_PT_LO_1_2.stp | sed -e 's/XXXX/pt1table/'
python ad9520stp2c.py <AD9520-4_RF.stp | sed -e 's/XXXX/pt2table/'
python ad9520stp2c.py <AD9520-4_PT_HI_1_2.stp | sed -e 's/XXXX/pt3table/'
python ad9520stp2c.py <AD9520-4_PT_LO_11_19.stp | sed -e 's/XXXX/pt4table/'
python ad9520stp2c.py <AD9520-4_PT_HI_11_19.stp | sed -e 's/XXXX/pt5table/'
python ad9520stp2c.py <AD9520-4_RF_11_19_compat.stp | sed -e 's/XXXX/pt6table/'
) >ad9520Tables.h


