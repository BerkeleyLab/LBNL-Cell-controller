#!/usr/bin/env python

import sys, time, argparse
from configuration.jtag import *

parser = argparse.ArgumentParser(description='Program Kintex-7 firmware directly', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
parser.add_argument('-b', '--bit', help='Firmware bitfile to program')
args = parser.parse_args()

# Initialise the chain control
chain = jtag.chain(ip=args.target, stream_port=50005, input_select=1, speed=0)

print 'There are', chain.num_devices(), 'devices in the chain:'

print
for i in range(0, chain.num_devices()):
        print hex(chain.idcode(i))+' - '+ chain.idcode_resolve_name(chain.idcode(i))
print

# Parse the bitfile and resolve the part type
print 'Loading bitfile:', args.bit
bitfile = xilinx_bitfile_parser.bitfile(args.bit)

print 'Design name:', bitfile.design_name()
print 'Device name:', bitfile.device_name()
print 'Build date:', bitfile.build_date()
print 'Build time:', bitfile.build_time()
print 'Length:', bitfile.length(), 'bits'

print

matching_devices = list()
for i in range(0, chain.num_devices()):
        if bitfile.match_idcode(chain.idcode(i)):
                matching_devices.append(i)

if len(matching_devices) == 0:
        print 'No devices matching bitfile found in JTAG chain'
        exit()

# Default to first (and only) entry
device_choice = matching_devices[0]

# Override choice from argument line if there's more than one device
#if len(matching_devices) > 1:
#        if len(sys.argv) < 4:
#                print 'More than one matching FPGA in device chain - you must add a chain ID to the arguments'
#                exit()

#        choice_made = False
#        for i in matching_devices:
#                if i == int(sys.argv[3]):
#                        device_choice = i
#                        choice_made = True

#        if choice_made == False:
#                print 'No matching device selection found that corresponds to JTAG chain'
#                exit()
#else:
print 'Defaulting device selection in chain from IDCODE'

print 'Device selected for programming is in chain location:',str(device_choice)

if str('Xilinx Virtex 5') in chain.idcode_resolve_name(chain.idcode(device_choice)):
        print 'Xilinx Virtex 5 interface selected'
        interface = xilinx_virtex_5.interface(chain)
elif str('Xilinx Spartan 6') in chain.idcode_resolve_name(chain.idcode(device_choice)):
        print 'Xilinx Spartan 6 interface selected'
        interface = xilinx_spartan_6.interface(chain)
elif str('Xilinx Kintex 7') in chain.idcode_resolve_name(chain.idcode(device_choice)):
        print 'Xilinx Kintex 7 interface selected'
        interface = xilinx_kintex_7.interface(chain)
elif str('Xilinx Virtex 7') in chain.idcode_resolve_name(chain.idcode(device_choice)):
        print 'Xilinx Virtex 7 interface selected'
        interface = xilinx_virtex_7.interface(chain)
else:
        print 'Not able to program this device'
        exit()

print 'Programming...'
print

# Load the bitfile
interface.program(bitfile.data(), device_choice)
