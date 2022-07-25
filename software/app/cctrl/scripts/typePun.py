#!/usr/bin/env python

import argparse
import struct
import sys

l = 0
ac = len(sys.argv)
if (ac == 2): l = int(sys.argv[1], 16)
elif (ac == 5): l = (int(sys.argv[1], 16) << 24) | \
                    (int(sys.argv[2], 16) << 16) | \
                    (int(sys.argv[3], 16) <<  8) | \
                     int(sys.argv[4], 16) 
else:
    print("Bad arguments", file=sys.stderr)
    sys.exit(1)

b = struct.pack("I", l)
f = struct.unpack("f", b)[0]
print("%x %g" % (l, f))
