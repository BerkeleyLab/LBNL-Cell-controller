#!/bin/env python

import bmb7_spartan, argparse, time, datetime

parser = argparse.ArgumentParser(description='Display BMB7 monitors', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
args = parser.parse_args()

# Start the class
x = bmb7_spartan.interface(args.target)

while True:
    print
    print '----------------------------------', datetime.datetime.now(), '----------------------------------'
    x.print_monitors()
    time.sleep(1)

