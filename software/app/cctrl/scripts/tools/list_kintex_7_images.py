#!/usr/bin/env python

import time, sys, argparse
from datetime import datetime
from configuration.jtag import *
from configuration.spi import *

parser = argparse.ArgumentParser(description='List available Kintex-7 boot images', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
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

# List the images in the firmware
images = interface.get_images()

if len(images) == 0:
    print 'No images stored'
    exit()

for i in images:

    print

    print 'SHA256:',
    s = str()
    for j in i['sha256']:
        s += '{:02x}'.format(j)
    print s

    print 'Bitstream address:', i['address']
    print 'Bitstream length (bits):', i['length'] * 8
    print 'Firmware build date:', i['build_date'], '(' + str(datetime.utcfromtimestamp(i['build_date'])) + ')'
    print 'Firmware storage date:', i['storage_date'], '(' + str(datetime.utcfromtimestamp(i['storage_date'])) + ')'

print
