#!/usr/bin/env python

import time, sys, ntplib, argparse
from datetime import datetime, timedelta
from configuration.jtag import *
from configuration.spi import *

FIRMWARE_ID_ADDRESS = 23 * spi.SECTOR_SIZE

parser = argparse.ArgumentParser(description='Program Spartan-6 boot image', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
parser.add_argument('-b', '--bit', help='Firmware bitfile to store')
args = parser.parse_args()

# Initialise the interface to the PROM
prom = spi.interface(jtag.chain(ip=args.target, stream_port=50005, input_select=0, speed=0, noinit=True))

# Read the VCR and VECR
print 'PROM ID (0x20BA, Capacity=0x19, EDID+CFD length=0x10, EDID (2 bytes), CFD (14 bytes)',

print 'VCR (should be 0xfb by default):',hex(prom.read_register(spi.RDVCR, 1)[0])
print 'VECR (should be 0xdf):',hex(prom.read_register(spi.RDVECR, 1)[0])

if prom.prom_size() != 25:
    print 'ERROR: PROM size incorrect, read',interface.prom_size()
    exit()

print 'PROM size: 256Mb == 500 x 64KB blocks'

print
print 'Loading bitfile:', args.bit
bitfile = xilinx_bitfile_parser.bitfile(args.bit)

print 'Design name:', bitfile.design_name()
print 'Device name:', bitfile.device_name()
print 'Build date:', bitfile.build_date()
print 'Build time:', bitfile.build_time()
print 'Length:', bitfile.length(), 'bits'

print

# Safety check to match bitfile to Spartan-6
if bitfile.device_name() != '6slx45tcsg324':
    print 'ERROR: Bitfile device name is not a Spartan-6 FPGA'
    exit()

# Write the Spartan 6 bitfile at 64KB block address 0
prom.program_bitfile(args.bit, 0)

parser = xilinx_bitfile_parser.bitfile(args.bit)

# Get the current date & time from NTP
# Otherwise use local
storage_date = 0

try:
    c = ntplib.NTPClient()
    response = c.request('0.pool.ntp.org', version=3)
    storage_date = int(response.tx_time)
except ntplib.NTPException:
    print 'ERROR: Timeout on NTP request, using local clock instead'
    storage_date = int(time.time())

# Extract the build date and time from the bitfile and encode it
build_date = int(time.mktime(datetime.strptime(parser.build_date() + ' ' + parser.build_time(), '%Y/%m/%d %H:%M:%S').timetuple()))

# Calculate SHA256 of bitfile
sha256 = parser.hash()

sha256.append((build_date >> 56) & 0xFF)
sha256.append((build_date >> 48) & 0xFF)
sha256.append((build_date >> 40) & 0xFF)
sha256.append((build_date >> 32) & 0xFF)
sha256.append((build_date >> 24) & 0xFF)
sha256.append((build_date >> 16) & 0xFF)
sha256.append((build_date >> 8) & 0xFF)
sha256.append((build_date) & 0xFF)

sha256.append((storage_date >> 56) & 0xFF)
sha256.append((storage_date >> 48) & 0xFF)
sha256.append((storage_date >> 40) & 0xFF)
sha256.append((storage_date >> 32) & 0xFF)
sha256.append((storage_date >> 24) & 0xFF)
sha256.append((storage_date >> 16) & 0xFF)
sha256.append((storage_date >> 8) & 0xFF)
sha256.append((storage_date) & 0xFF)

sha256 += bytearray([0xFF]) * (256 - len(sha256) % 256)

# Compare the current data with the previous to see if we have to erase
pd = prom.read_data(FIRMWARE_ID_ADDRESS, len(sha256))

# Only check the first two, the third changes each time
did_break = False
for i in range(0, 40):
    if ( sha256[i] != pd[i] ):
        did_break = True
        if ( pd[i] != 0xFF ):
            # Erase the previous table
            print 'Erasing old firwmare ID'
            prom.sector_erase(FIRMWARE_ID_ADDRESS)
            break

print

if did_break == False:
    print 'Firmware ID matches bitfile'
    print
    print 'SHA256:',
    s = str()
    for j in sha256[0:32]:
        s += '{:02x}'.format(j)
    print s
    print 'Build timestamp:', build_date, '('+str(datetime.utcfromtimestamp(build_date))+')'
    storage_date = 0
    for i in range(0, 8):
        storage_date += int(pd[40+i]) * 2**(56-i*8)
    print 'Storage timestamp:', storage_date, '('+str(datetime.utcfromtimestamp(storage_date))+')'
    exit()

print 'Updating firmware ID'
for i in range(0, len(sha256) / 256):
    prom.page_program(sha256[i * 256 : (i+1) * 256], i * 256 + FIRMWARE_ID_ADDRESS)

# Verify
pd = prom.read_data(FIRMWARE_ID_ADDRESS, len(sha256))
for i in range(0, 40):
    if ( sha256[i] != pd[i] ):
        print
        raise SPI_Base_Exception('Firmware ID update byte', str(i), 'failed')

print 'SHA256:',
s = str()
for j in sha256[0:32]:
    s += '{:02x}'.format(j)
print s

print 'Build timestamp:', build_date, '('+str(datetime.utcfromtimestamp(build_date))+')'

storage_date = 0
for i in range(0, 8):
    storage_date += int(pd[40+i]) * 2**(56-i*8)
print 'Storage timestamp:', storage_date, '('+str(datetime.utcfromtimestamp(storage_date))+')'


