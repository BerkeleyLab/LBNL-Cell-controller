#
# Display PLL configuration
#
import argparse
import epics
import re
import sys
import time

parser = argparse.ArgumentParser(description='Display PLL configuration.', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-c', '--cell', type=int, default=None, help='Cell number')
parser.add_argument('-f', '--file', default=None, help='Data file')
parser.add_argument('-p', '--prefix', default='SR01:CC:', help='PV name prefix')
args = parser.parse_args()

regs = [None for x in range(0,3000)]

if (args.file):
    with open(args.file, "r") as fin:
        r = re.compile('[ \t\n\r:]+')
        for l in fin:
            c = r.split(l.strip())
            reg = int(c[0], 16)
            val = int(c[1], 16)
            regs[reg] = val
else:
    if (args.cell != None):
        args.prefix = "UT:%2.2d:" % (args.cell)
    def pv(suffix):
        pv = epics.PV(args.prefix+suffix, connection_timeout=2)
        if (pv.get() == None):
            print "Can't connect to %s" % (pv.pvname)
            sys.exit(1)
        return pv
    pvSelect  = pv('ptPLLregSelect')
    pvSet     = pv('ptPLLregSet')
    pvGet     = pv('ptPLLregGet')
    pvGetMDEL = pv('ptPLLregGet.MDEL')

    def getReg(reg):
        global pvSelect, pvGet
        then = pvGet.timestamp
        pvSelect.put(reg, wait=True)
        i = 0
        while (pvGet.timestamp == then):
            i += 1
            if (i == 100):
                print >>sys.stderr, 'Register value failed to update.'
                sys.exit(1)
            time.sleep(0.001)
        return pvGet.get()

    def setReg(reg, value):
        global pvSelect, pvSet
        pvSelect.put(reg, wait=True)
        pvSet.put(value, wait=True)

    regList = [ \
     0x000, 0x003, 0x004, 0x005, 0x006,                      \
     0x010, 0x011, 0x012, 0x013, 0x014, 0x015, 0x016, 0x017, \
     0x018, 0x019, 0x01A, 0x01B, 0x01C, 0x01D, 0x01E, 0x01F, \
     0x0F0, 0x0F1, 0x0F2, 0x0F3, 0x0F4, 0x0F5, 0x0F6, 0x0F7, \
     0x0F8, 0x0F9, 0x0FA, 0x0FB, 0x0FC, 0x0FD,               \
     0x190, 0x191, 0x192, 0x193, 0x194, 0x195, 0x196, 0x197, \
     0x198, 0x199, 0x19A, 0x19B, 0x19C,                      \
     0x1E0, 0x1E1, 0x230,                                    \
     0xA00, 0xA01, 0xA02, 0xA03, 0xA04, 0xA05, 0xA06, 0xA07, \
     0xA08, 0xA09, 0xA0A, 0xA0B, 0xA0C, 0xA0D, 0xA0E, 0xA0F, \
     0xA10, 0xA11, 0xA12, 0xA13, 0xA14, 0xA15, 0xA16 ]

    # Read active registers
    svMDEL = pvGetMDEL.get()
    pvGetMDEL.put(-1)
    sv = getReg(4)
    setReg(4, 1)
    time.sleep(1)
    for r in regList:
        regs[r] = getReg(r)
    setReg(4, sv)
    pvGetMDEL.put(svMDEL)

# Show in nice format
for r in range(0, len(regs)):
    v = regs[r]
    if (v == None): continue
    print "  %03X %02X" % (r, v),
    if ((r < 0x005) and (v == 0xFF)):
        print " Unreasonable value -- AD9520 not responding to I2C?"
        break

    if (r == 0x000):
        print " Soft reset %sactive" % ("in" if ((v & 0x20) == 0) else ""),

    if (r == 0x003):
        print " %s" % ("AD94520-0" if (v == 0x20) else \
                       "AD94520-1" if (v == 0x60) else \
                       "AD94520-2" if (v == 0xA0) else \
                       "AD94520-3" if (v == 0x61) else \
                       "AD94520-4" if (v == 0xE1) else \
                       "AD94520-5" if (v == 0xE0) else \
                       "Unknown device identification code"),

    if (r == 0x004):
        print " Read back %s registers"%("active" if (v & 0x1) else "buffer"),

    if ((r == 0x005) or (r == 0x006)):
        print " EEPROM customer ID (%sSB)"% ("L" if (r == 0x005) else "M"),

    if (r == 0x010):
        print " %s PFD, CP current: %s%.1f mA, PLL: %s" % (
                    "Negative" if (v & 0x80) else "Positive",
                    "Non-standard mode, " if ((v & 0x0C) != 0x0C) else "",
                    ((((v & 0x70) >> 4) + 1) * 6) / 10.0,
                    "Power-down" if (v & 0x03) else "Normal"),

    if (r == 0x011): rLo = v
    if (r == 0x012):
        refDivisor = ((v & 0x3F) << 8) | rLo
        print " Reference divider (R): %d" % (refDivisor),

    if (r == 0x013):
        a = v & 0x3F
        print " A counter: %d" % (a),

    if (r == 0x014): bLo = v
    if (r == 0x015):
        b = ((v & 0x1F) << 8) | bLo
        print " B counter: %d" % (b),

    if (r == 0x016):
        print " Prescaler (P):",
        p =  1 if ((v & 0x7) == 0) else \
             2 if ((v & 0x7) == 1) else \
            -2 if ((v & 0x7) == 2) else \
            -4 if ((v & 0x7) == 3) else \
            -8 if ((v & 0x7) == 4) else \
           -16 if ((v & 0x7) == 5) else \
           -32 if ((v & 0x7) == 6) else 3
        if (p < 0):
            p = -p
            if (a == 0):
                print "%d" % (p),
            else:
                print "%d/%d" % (p, p+1),
            print "(Dual modulus),",
        else:
            print "%d (Fixed Divide)," % (p),
        print "Fvco = Fref * %d" % ((p * b) + a),
        if (refDivisor != 1):
                print "/ %d" % (refDivisor),
    if (r ==  0x017):
        print " STATUS pin SEL: %02X%s, antibacklash code %X" % (
                            v>>2,
                            ", !(DLD & selected ref status & VCO status)"
                                            if ((v >>2) == 0x3A) else "",
                            v&3),
    if (r ==  0x018):
        print " %sCMOS offset, lock in %d, %s range, lock %s, VCO cal div %d%s" % (
                            ""    if v & 0x80 else "No ",
                            5     if (v & 0x60) == 0x00 else
                            16    if (v & 0x60) == 0x20 else
                            64    if (v & 0x60) == 0x40 else 255,
                            "low" if v & 0x10 else "high",
                            "off" if v & 0x08 else "on",
                            2 << ((v & 0x6) >> 1),
                            ", CAL" if v & 0x1 else ""),

    if (r ==  0x01A):
        print " Ref valid if > %s, LD pin SEL: %02X%s" % (
                    "6 kHz" if (v & 0x40) else "1.02 MHz",
                    v & 0x3F,
                    ", !(Digital Lock Detect)" if ((v & 0x3F) == 0x3D) else ""),

    if (r ==  0x01B):
        print " Fmon: VCO %s, REF2 %s, REF1 %s.  REFMON pin SEL: %02X%s" % (
                "ON" if v & 0x80 else "OFF",
                "ON" if v & 0x40 else "OFF",
                "ON" if v & 0x20 else "OFF",
                v & 0x1F,
                ", (Selected ref status)"  if ((v & 0x1F) == 0x05) else
                ", !(Selected ref status)" if ((v & 0x1F) == 0x15) else ""),
    if (r ==  0x01C):
        print " %s switchover, deglitch %s, %s,%s%s%s%s" % (
                        "Automatic"      if v & 0x10 else "Manual",
                        "off"            if v & 0x80 else "on",
                        "REF_SEL pin"    if v & 0x20 else 
                        "use REF2"       if v & 0x40 else "use REF1", 
                        " Stay on REF2," if v & 0x08 else "",
                        " REF2 on,"      if v & 0x14 != 0 else "",
                        " REF1 on,"      if v & 0x12 != 0 else "",
                        " differential" if v & 0x01 else " single-ended"),

    if (r ==  0x01D):
        print " STATUS pin = %s, PLL status %sabled, holdover %sabled" % (
                                "STATUS_EEPROM" if v & 0x80 else "REG 0x17",
                                "dis"           if v & 0x10 else "en",
                                "en"            if v & 0x01 else "dis"),

    if (r ==  0x01E):
        print " Zero-delay %sabled" %(
                                    "en" if v & 0x02 else  "dis"),

    if (r ==  0x01F):
        print " VCO cal%s done,%s REF%d, VCO%c, REF2%c, REF1%cthreshold, PLL %slocked" % (
                                    ""           if v & 0x40 else  " not",
                                    " Holdover," if v & 0x20 else  "",
                                    2            if v & 0x10 else  1,
                                    '>'          if v & 0x08 else  '<',
                                    '>'          if v & 0x44 else  '<',
                                    '>'          if v & 0x02 else  '<',
                                    ""           if v & 0x01 else  "un"),

    if ((r >= 0x0F0) and (r <= 0x0FB)):
        print " Output %2d:" % (r - 0x0F0),
        if (v & 0x80): print "LVCMOS, A %s, B %s" % (
                        "Tristate" if ((v & 0x20) == 0) else 
                            "Inverting" if (v & 0x8) else "Non-inverting",
                        "Tristate" if ((v & 0x40) == 0) else 
                            "Inverting" if ((v & 0x10) ^ ((v & 0x8) << 1))
                                                     else "Non-inverting"),
        else: print "LVPECL%s, %s" % (", Inverting" if (v & 0x10) else "",
                                "Safe power down" if (v & 0x1) else
                                "400 mV" if ((v & 0x6) == 0x0) else
                                "600 mV" if ((v & 0x6) == 0x2) else
                                "780 mV" if ((v & 0x6) == 0x4) else
                                "960 mV"),

    if ((r == 0x0FC) or (r == 0x0FD)):
        if (r == 0x0FD): v &= 0xF
        print " %s outputs affected by CSDLD signal" % (
                                                "Some" if v else "No"),

    if (r == 0x190) or (r == 0x193) or (r == 0x196) or (r == 0x199):
        chan = (r - 0x190) / 3
        bypassDivider = regs[0x191+3*chan] & 0x80
        if (bypassDivider == 0):
            l = ((v & 0xF0) >> 4) + 1
            h = (v & 0x0F) + 1
            print " Divider %d divide by %d (%d low, %d high)" % (chan,
                                                            l + h, l, h),
    if (r == 0x191) or (r == 0x194) or (r == 0x197) or (r == 0x19A):
        chan = (r - 0x191) / 3
        s = " Divider %d %s" % (chan, "bypassed" if v & 0x80 else "active")
        if ((v & 0x80)==0):s += ", %s SYNC" % ("ignore" if v & 0x40 else "obey")
        print s,
    if (r == 0x192) or (r == 0x195) or (r == 0x198) or (r == 0x19B):
        chan = (r - 0x192) / 3
        s = " Channel %d %s" % (chan, "powered down" if v & 0x04 else "active")
        if ((v & 0x04) == 0):
            s += ", source is %s" % ("CLK/VCO" if v & 0x02 else "divider")
            if ((v & 0x01) != 0): s += ", duty-cycle correction disabled"
        print s,
    if (r == 0x1E0):
        print " VCO divider %s" % (
                            "divide by 2" if ((v & 0x7) == 0) else
                            "divide by 3" if ((v & 0x7) == 1) else
                            "divide by 4" if ((v & 0x7) == 2) else
                            "divide by 5" if ((v & 0x7) == 3) else
                            "divide by 6" if ((v & 0x7) == 4) else
                            "bypassed"    if ((v & 0x7) == 6) else
                            "output static"),

    if (r == 0x1E1):
        print " %s power down, %s to VCO divider, VCO divider %s" % (
                                    "Some"     if v & 0x1C else "No", 
                                    "VCO"      if v & 0x02 else "CLK", 
                                    "bypassed" if v & 0x01 else "active"),

    print
