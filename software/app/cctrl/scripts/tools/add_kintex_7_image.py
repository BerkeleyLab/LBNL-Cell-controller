#!/usr/bin/env python

import time, sys, argparse
from configuration.jtag import *
from configuration.spi import *

parser = argparse.ArgumentParser(description='Add a Kintex-7 boot image', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
parser.add_argument('-b', '--bit', help='Firmware bitfile to add')
args = parser.parse_args()

# Initialise the interface to the PROM
prom = spi.interface(jtag.chain(ip=args.target, stream_port=50005, input_select=0, speed=0, noinit=True))

# Read the VCR and VECR
print 'PROM ID (0x20BA, Capacity=0x19, EDID+CFD length=0x10, EDID (2 bytes), CFD (14 bytes)',

print 'VCR (should be 0xfb by default):',hex(prom.read_register(spi.RDVCR, 1)[0])
print 'VECR (should be 0xdf):',hex(prom.read_register(spi.RDVECR, 1)[0])

if prom.prom_size() != 25:
    print 'PROM size incorrect, read',prom.prom_size()
    exit()

print 'PROM size: 256Mb == 500 x 64KB blocks'

# Create a Kintex firmware interface
interface = kintex_7_firmware.interface(prom)

# Write the image into available space if possible
interface.add_image(args.bit)
