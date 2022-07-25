#
# Set fast orbit feedback configuration
#
import argparse
import epics
import numpy
import sys
import time

parser = argparse.ArgumentParser(description='Configure fast orbit feedback to useful defaults.', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-b', '--bpm', type=int, choices=range(0,511), default=0, help='BPM number')
parser.add_argument('-p', '--prefix', default='SR01:CC:', help='PV name prefix')
args = parser.parse_args()

pvCorrectorGains = epics.PV(args.prefix + "FOFBgains")
pvMatrixRow = []
pvFIRrow = []
for i in range(0,16):
    pvMatrixRow.append(epics.PV(args.prefix + "FOFBrow%02d" % (i)))
    pvFIRrow.append(epics.PV(args.prefix + "FOFB_FIR%02d" % (i)))
pvGains = epics.PV(args.prefix + "FOFBgains")

# Set all correctors to unity gain
gains = numpy.ones(16)
pvGains.put(gains)

# Set up a very simple inverse sensitivity matrix
matrixRow = numpy.zeros(1024)
for i in range(0,16,8):
    matrixRow[args.bpm] = 0.01
    matrixRow[args.bpm+512] = 0.0
    pvMatrixRow[0+i].put(matrixRow)
    matrixRow[args.bpm] = 0.0
    matrixRow[args.bpm+512] = 0.01
    pvMatrixRow[1+i].put(matrixRow)
    matrixRow[args.bpm] = 0.01
    matrixRow[args.bpm+512] = 0.01
    pvMatrixRow[2+i].put(matrixRow)
    matrixRow[args.bpm] = -0.01
    matrixRow[args.bpm+512] = 0.0
    pvMatrixRow[3+i].put(matrixRow)
    matrixRow[args.bpm] = 0.0
    matrixRow[args.bpm+512] = -0.01
    pvMatrixRow[4+i].put(matrixRow)
    matrixRow[args.bpm] = -0.01
    matrixRow[args.bpm+512] = -0.01
    pvMatrixRow[5+i].put(matrixRow)


# Set up a very simple set of FIR filters
firRow = numpy.zeros(512)
for i in range(0,16):
    firRow[0] = 1.0 if (i <= 7) else 0.5
    pvFIRrow[i].put(firRow)
