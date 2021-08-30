#
# Display board power consumption
#
import argparse
import epics

parser = argparse.ArgumentParser(description='Display pilot tone generator PLL configuration.', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-p', '--prefix', default='SR01:CC:', help='PV name prefix')
parser.add_argument('-v', '--verbose', action='store_true', help='Show values as they are read')
args = parser.parse_args()

supplies = ('TopFMC3_3',  \
            'TopFMCVADJ', \
            'MAIN3_3',    \
            'SBY3_3',     \
            'TopFMC12',   \
            'BtmFMCVIOB', \
            'BtmFMC12',   \
            'BOOT3_3',    \
            'S61_2',      \
            'BtmFMC3_3',  \
            'BtmFMCVADJ', \
            'S6GTP1_2',   \
            'K7GTX1_2',   \
            'SBY1_2',     \
            'K7GTX1_0',   \
            'K7INT1_0',   \
            'K71_8');

def get(name):
    pv = epics.PV(name)
    v = pv.get()
    if (args.verbose): print "%s: %g" % (name, v)
    return pv.get()

power = 0.0
for s in supplies:
    voltage = get(args.prefix + s + ':V')
    if (voltage > 0):
        current = voltage = get(args.prefix + s + ':I')
        power += voltage * current
print "Supplies output: %.1f W" % (power)
