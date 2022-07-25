#!/bin/env python

import bmb7_spartan, argparse

parser = argparse.ArgumentParser(description='Display BMB7 FMC PROM data', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
args = parser.parse_args()

# Start the class
x = bmb7_spartan.interface(args.target)

# Most PROMs have similar basic behavior on the BMB7, but the exact addressing varies.
# Typically, the PROM base address is (0x50 | ADDR), where ADDR == 0 to 7 depending on how GA0 & GA1 are wired up.
# In the BMB7, the top FMC is GA0 = GA1 = 0, the bottom FMC is GA0 = 1, GA1 = 0.

# For the HW-FMC-105-DEBUG: TOP FMC == 0x50, BOTTOM FMC == 0x52, DEVICE == m24c02
# For the LCLS-II ADC mezzanine: TOP FMC == 0x50, BOTTOM FMC == 0x51, DEVICE == at24c32d

# To read or write a byte from a given address, use:
# write_[DEVICE]_prom(PROM ADDRESS, ADDRESS, BYTE)
# read_[DEVICE]_prom(PROM ADDRESS, ADDRESS, BYTE)

################################
# Example: Read first 10 bytes from M24C02 PROM on HW-FMC-105-DEBUG mounted on top FMC site

PROM_ADDRESS = 0x50 # 0x52 for bottom FMC site

#for i in range(0, 10):
#   x.write_m24c02_prom(PROM_ADDRESS, i, i)

for i in range(0, 10):
   print str(i)+'\t'+str(hex(x.read_m24c02_prom(PROM_ADDRESS, i)))

################################
# Example: Read first 10 bytes from AT24C32D PROM on LCLS-II ADC mezzanine mounted on top FMC site

#PROM_ADDRESS = 0x50 # 0x51 for bottom FMC site

#for i in range(0, 10):
#   x.write_at24c32d_prom(PROM_ADDRESS, i, i)

#for i in range(0, 10):
#   print str(i)+'\t'+str(hex(x.read_at24c32d_prom(PROM_ADDRESS, i)))
