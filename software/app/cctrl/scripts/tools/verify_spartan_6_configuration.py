#!/usr/bin/env python

import time, sys, argparse
from configuration.jtag import *
from configuration.spi import *

CONFIG_ADDRESS = 24 * spi.SECTOR_SIZE

parser = argparse.ArgumentParser(description='Verify Spartan-6 boot configuration', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
args = parser.parse_args()

def fletcher(data):

    sum1 = 0xAA
    sum2 = 0x55

    for i in data:
        sum1 = sum1 + int(i)
        sum2 = sum1 + sum2

    sum1 = sum1 % 255
    sum2 = sum2 % 255

    return bytearray([sum1, sum2])

def fletcher_check(data):

    v = fletcher(data)

    sum1 = 0xFF - ((int(v[0]) + int(v[1])) % 255)
    sum2 = 0xFF - ((int(v[0]) + sum1) % 255)

    return bytearray([sum1, sum2])

# Initialise the interface to the PROM
prom = spi.interface(jtag.chain(ip=args.target, stream_port=50005, input_select=0, speed=0, noinit=True))

# Read the VCR and VECR
print 'PROM ID (0x20BA, Capacity=0x19, EDID+CFD length=0x10, EDID (2 bytes), CFD (14 bytes)',

print 'VCR (should be 0xfb by default):',hex(prom.read_register(spi.RDVCR, 1)[0])
print 'VECR (should be 0xdf):',hex(prom.read_register(spi.RDVECR, 1)[0])

if prom.prom_size() != 25:
    print 'PROM size incorrect, read',interface.prom_size()
    exit()

print 'PROM size: 256Mb == 500 x 64KB blocks'

print 'Reading Spartan-6 configuration settings'

pd = prom.read_data(CONFIG_ADDRESS, 87)
v = fletcher_check(pd[0:85])

if ( v != pd[85:87] ):
    print 'PROM configuration checksum invalid'
    exit()
print 'PROM configuration checksum valid'
print

print '-------------------------------------------'
print 'NETWORK SETTINGS'
print '-------------------------------------------'

print 'Multicast MAC address:',
s = str()
for i in pd[0:6]: s += '{:02X}'.format(i) + ':'
print s[:-1]

print 'Multicast IPv4 address:',
s = str()
for i in pd[6:10]: s += '{:d}'.format(i) + '.'
print s[:-1]

print 'Multicast port:',
print int(pd[10]) * 256 + pd[11]

print 'Unicast MAC address:',
s = str()
for i in pd[12:18]: s += '{:02X}'.format(i) + ':'
print s[:-1]

print 'Unicast IPv4 address:',
s = str()
for i in pd[18:22]: s += '{:d}'.format(i) + '.'
print s[:-1]

print 'Kintex-7 firmware to loaded on boot (SHA256 hash identifier):',
s = str()
for i in pd[22:54]: s += '{:02x}'.format(i)
print s
print

# 54 to 60 are unused

print '---------------------------------------------------------------------------------------'
print 'SYSTEM I2C BOOT MANAGER'
print '---------------------------------------------------------------------------------------'

print 'Monitor and power enables (monitor is a oneshot - should be 0 at boot) [0bXXX, MONITOR, FMC, KINTEX GTX, MAIN, SPARTAN GTP]:', hex(pd[66])
print

print '---------------------------------------------------------------------------------------'
print 'SI57X OSCILLATOR'
print '---------------------------------------------------------------------------------------'

print 'RFREQ[37:0]:', hex(pd[67]), hex(pd[68]), hex(pd[69]), hex(pd[70]), hex(pd[71])
print 'N1[6:0]:', hex(pd[72])
print 'HSDIV[2:0]:', hex(pd[73])
print 'I2C manager controls [0bXXXXX, UPDATE, OE, DISABLE]:', hex(pd[74])
print

print '---------------------------------------------------------------------------------------'
print 'JITTER CLEANER (BOOTS FROM INTERNAL PROM TO 125MHZ REFERENCE WHEN NOT IN POWER DOWN)'
print '---------------------------------------------------------------------------------------'

print 'SPI bus (always == 1 in PROM) [0bXXXXX, CLK, LE, MOSI]:', hex(pd[81])
print 'Power enable and external reference select [0bXXXXXX, REF_SEL, NOT_POWER_DOWN]:', hex(pd[82])
print

print '---------------------------------------------------------------------------------------'
print 'UARTs'
print '---------------------------------------------------------------------------------------'

print 'UART 0 clock divider (from 50MHz):', hex(pd[77]), hex(pd[78]), '=>', float(50000) / float(int(pd[77]) * 256 + pd[78]), 'kbps'
print 'UART 0 TX & RX source select:', hex(pd[63]), hex(pd[64])
print 'UART 1 clock divider (from 50MHz):', hex(pd[75]), hex(pd[76]), '=>', float(50000) / float(int(pd[75]) * 256 + pd[76]), 'kbps'
print 'UART 0 TX & RX source select:', hex(pd[61]), hex(pd[62])
print

print '---------------------------------------------------------------------------------------'
print 'OTHER CONTROLS'
print '---------------------------------------------------------------------------------------'

print 'Enable Kintex-7 JTAG debug header [0bXXXXXXX, ENABLE]:', hex(pd[65])
print 'Kintex data path master enables (interlocked with Kintex-7 DONE pin), RS-232 PHY enables, and FMC JTAG [0bX, ENABLE_KINTEX_MULTICAST, ENABLE_UART_1, ENABLE_UART_0, ENABLE_KINTEX_DAQ, ENABLE_KINTEX_CONFIGURATION, BOTTOM_FMC_TRST_L, TOP_FMC_TRST_L]:', hex(pd[79])
print 'FMC I2C bus (always == 1 in PROM) [0bXXXXXX, SDA, SCL]:', hex(pd[80])
print 'Force supply burst mode (i.e. disable sync clock when bit == 1, 0 for lower supply noise but higher static power dissipation) [0bXXXXXXX,EN]:', hex(pd[83])
print 'System I2C override (always == 1 in PROM) [0bXXXXX, MUX RESET, SDA, SCL]', hex(pd[84])
print
