#
# Convert AD9520 '.stp' file to C initializer
#
import re
import sys
import string

regList = [];
show = False
for line in sys.stdin:
    if (re.match(r'^"[0-9A-F][0-9A-F][0-9A-F][0-9A-F]"', line)):
        cols = re.sub('"', '', line.strip()).split(',')
        reg = int(cols[0], 16)
        val = int(cols[2], 16)
        # Ignore status, EPROM and read-only registers
        if ((reg >= 0x010) and (reg <= 0x01E)) or ((reg >= 0x190) and (reg <= 0x230)):
            regList.append([reg, val])
    if (re.match(r'^"Other Settings', line)):
        show = True
        print("/*")
    if (re.match(r'^""', line)) and show:
        show = False
        print(" */")
    if show:
        print(" * %s" % (re.sub('"', '', line.strip())))
if show:
    show = False
    print(" */")
print("static const uint16_t XXXX[] = {")
for l in regList:
    print("    0x%03X, 0x%02X," % (l[0], l[1]))
print("};")
