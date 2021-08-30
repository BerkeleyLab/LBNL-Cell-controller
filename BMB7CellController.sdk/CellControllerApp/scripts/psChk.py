#!/usr/bin/env python

import argparse
import socket
import struct
import time

parser = argparse.ArgumentParser(description='Receive fast feedabck broadcast packets',
                        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-i', '--interface', default='0.0.0.0', help='Interface to use')
parser.add_argument('-m', '--multicast', default='224.243.71.4', help='multicast group')
parser.add_argument('-s', '--sparse', default=10000, type=int, help='Receive sparsing factor')
parser.add_argument( '-v', '--verbose', action='store_true', help='Show raw data')
args = parser.parse_args()

ffbUdpPort = 30721

UDPSock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
UDPSock.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
UDPSock.setsockopt(socket.SOL_IP,socket.IP_ADD_MEMBERSHIP,
           socket.inet_aton(args.multicast)+socket.inet_aton(args.interface))
UDPSock.bind((args.multicast,ffbUdpPort))

lastSequenceNumber = -1
receivedPacketCount = 0
lostPacketCount = 0
runtPacketCount = 0
sparseCount = args.sparse
skipCount = 10
startTime = time.time()
try:
    while (True):
        rawData, addr = UDPSock.recvfrom(2048)
        l = len(rawData)
        if (l < 18):
            runtPacketCount += 1
        else:
            supplyCount = (len(rawData) - 12) / 6
            hdr = struct.unpack_from('>HHQ', rawData, 0)
            sequenceNumber = hdr[2]
            if (skipCount == 0):
                lost = sequenceNumber - (lastSequenceNumber + 1)
                if ((lost > 0) and (lost < 50000)): lostPacketCount += lost
                sparseCount -= 1
            else:
                skipCount -= 1;
            lastSequenceNumber = sequenceNumber
            if (args.verbose and (sparseCount <= 0)):
                sparseCount = args.sparse
                print "=====", hdr
                for i in range(0, supplyCount):
                    ps = struct.unpack_from('>Hf', rawData, 12 + 6 * i)
                    print ps
            receivedPacketCount += 1
except KeyboardInterrupt:
    elapsedTime = time.time() - startTime
    print "\nReceived %d, runt %d, lost %d, elapsed %g, rate %.7g/s" % \
                        (receivedPacketCount, runtPacketCount, lostPacketCount,
                        elapsedTime, receivedPacketCount / elapsedTime)
