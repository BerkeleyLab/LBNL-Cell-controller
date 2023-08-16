#! /usr/bin/python3

# Load an I2C program file over SCRAP

import sys
import os
import argparse

import scrap

def is_plaintext(file):
    """Returns True if file with filename 'file' is plaintext (ASCII/utf-8), False otherwise."""
    _ascii = True
    with open(file, 'r') as fd:
        line = True
        while line:
            try:
                line = fd.read(100)
            except UnicodeDecodeError as e:
                _ascii = False
                break
    return _ascii

def loadFile(filename):
    if not os.path.exists(filename):
        raise Exception(f"File {filename} does not exist")
    data = []
    if is_plaintext(filename):
        with open(filename, 'r') as fd:
            line = True
            while line:
                line = fd.readline()
                data.extend([int(x,16) for x in line.split()])
    else:
        with open(filename, 'rb') as fd:
            chunk = True
            while chunk:
                chunk = fd.read(1024)
                data.extend([x for x in chunk])
    return data

def doLoad(argv):
    parser = argparse.ArgumentParser(description="Load a command file to i2c_chunk via SCRAP protocol")
    devhelp = "Device to interface with.  Can be /dev/ttyUSBx to talk over TTY" + \
              " or 'udp:12345' to talk over UDP on localhost (127.0.0.1) on port 12345."
    parser.add_argument('-t', '--dev', default='/dev/ttyUSB2', help=devhelp)
    parser.add_argument('-o', '--offset', default=0, help='Memory offset of destination')
    parser.add_argument('filename', default=None, help='Program file to load', nargs='?')
    args = parser.parse_args()
    silent = True
    offset = scrap._int(args.offset)
    dev = scrap.SCRAPDevice(args.dev, baud=scrap.SCRAP_BAUDRATE, silent=silent)
    data = loadFile(args.filename)
    ndata = len(data)
    print(f"Writing {ndata} bytes to memory address 0x{offset:x}")
    success, nwritten = dev.write(offset, data, extended=True)
    if success & (nwritten == ndata):
        print("Success")
    else:
        if not success:
            rtypeText = dev.getLastRtypeText()
            print(f"Failed; {rtypeText}")
        else:
            print("Failed; Wrote {nwritten} out of {ndata} bytes")
        return False
    success, readback = dev.read(offset, ndata, extended=True)
    if len(readback) != ndata:
        print("Failed to read back. Read {len(readback)} out of {ndata} bytes")
        return False
    equal = True
    for n in range(ndata):
        if readback[n] != data[n]:
            equal = False
    if not equal:
        print("WARNING: Data integrity could not be verified.  Does memory have R/W access?")
    else:
        print("Data integrity verified")
    return True

if __name__ == "__main__":
    doLoad(sys.argv)
