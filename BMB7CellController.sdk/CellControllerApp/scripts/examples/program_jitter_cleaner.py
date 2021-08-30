#!/bin/env python

from socket import *
import string
import time
import sys
import bmb7_spartan

# Start the class
x = bmb7_spartan.interface(sys.argv[1])

x.setup_jitter_cleaner()
x.store_jitter_cleaner()
