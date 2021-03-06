#!/usr/bin/env python

import time, sys

# JTAG codes for Spartan 6
BYPASS = 0x3F
IDCODE = 0x09
JPROGRAM = 0x0B
CFG_IN = 0x05
JSTART = 0x0C

#USER1 = 2
#USER2 = 3
#USER3 = 34
#USER4 = 35

class Spartan6_JTAG_Exception(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

# TODO - decide if I'd rather put this in the main JTAG control class
class shift_padder():
    def __init__(self, chain, target):
        self.__target = target
        self.__chain = chain

        self.__pre_pad_dr = 0
        self.__pre_pad_ir = 0
        for i in range(target+1, self.__chain.num_devices()):
            self.__pre_pad_dr += 1
            self.__pre_pad_ir += chain.idcode_resolve_irlen(chain.idcode(i))

        print 'DR pre padding:', self.__pre_pad_dr
        print 'IR pre padding:', self.__pre_pad_dr
            
        self.__post_pad_dr = 0
        self.__post_pad_ir = 0
        for i in range(0, target):
            self.__post_pad_dr += 1
            self.__post_pad_ir += chain.idcode_resolve_irlen(chain.idcode(i))

        print 'DR post padding:', self.__post_pad_dr
        print 'IR post padding:', self.__post_pad_ir
        print

    def pad_ir(self, data, num_bits):

        # Post-pad the bypass instruction
        result = 0
        for i in range(0, self.__post_pad_ir):
            result = (result << 1) | 0x1

        result = result << num_bits
        result |= data

        # Pre-pad the bypass instruction
        for i in range(0, self.__pre_pad_ir):
            result = (result << 1) | 0x1
        
        return [result, num_bits + self.__post_pad_ir + self.__pre_pad_ir]
    
    def pad_dr(self, data, num_bits):

        # Post-pad the bypass data bits
        result = 0
        for i in range(0, self.__post_pad_dr):
            result = (result << 1) | 0x1

        result = result << num_bits
        result |= data

        # Pre-pad the bypass data bits
        for i in range(0, self.__pre_pad_dr):
            result = (result << 1) | 0x1
        
        return [result, num_bits + self.__post_pad_dr + self.__pre_pad_dr]

    def post_pad_dr_len(self):
        return self.__post_pad_dr

    def pre_pad_dr_len(self):
        return self.__pre_pad_dr

    def pad_dr_len(self):
        return self.__post_pad_dr + self.__pre_pad_dr

    def unpad_dr(self, data, num_bits):

        # Shift out pre-padding
        data = data >> self.__pre_pad_dr

        # Mask off post-padding
        mask = 0
        for i in range(0, num_bits):
            mask = (mask << 1) | 1
        data &= mask

        return data

    def unpad_ir(self, data, num_bits):

        # Shift out pre-padding
        data = data >> self.__pre_pad_ir

        # Mask off post-padding
        mask = 0
        for i in range(0, num_bits):
            mask = (mask << 1) | 1
        data &= mask

        return data

class interface():
    def __init__(self, chain):
        self.__chain = chain

    def program(self, data, location):

        # Create a padder for the chain
        padder = shift_padder(self.__chain, location)

        PADDED_IDCODE = padder.pad_ir(IDCODE, 6)
        PADDED_BYPASS = padder.pad_ir(BYPASS, 6)
        PADDED_JPROGRAM = padder.pad_ir(JPROGRAM, 6)
        PADDED_JSTART = padder.pad_ir(JSTART, 6)
        PADDED_CFG_IN = padder.pad_ir(CFG_IN, 6)

        # Go to test logic reset to force all devices in the chain into bypass
        self.__chain.go_to_test_logic_reset()
        
        # Start in idle
        self.__chain.go_to_run_test_idle()

        # IDCODE
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_IDCODE[0], PADDED_IDCODE[1], True)
        self.__chain.go_to_run_test_idle()

        self.__chain.go_to_shift_dr()

        if padder.unpad_dr(self.__chain.write_read(padder.pad_dr(self.__chain.idcode(location), 32)[0], padder.pad_dr_len()+32, True), 32) != self.__chain.idcode(location):
            raise Spartan6_JTAG_Exception('IDCODE doesn\'t match expected target!')
        self.__chain.go_to_run_test_idle()

        # BYPASS
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_BYPASS[0], PADDED_BYPASS[1], True)
        self.__chain.go_to_run_test_idle()

        # Load the JPROGRAM instruction
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_JPROGRAM[0], PADDED_JPROGRAM[1], True)
        self.__chain.go_to_run_test_idle()

        # Load the CFG_IN instruction
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_CFG_IN[0], PADDED_CFG_IN[1], True)
        self.__chain.go_to_run_test_idle()

        # RUNTEST 10000 - debatably required
        self.__chain.jtag_clock(bytearray([0]) * 10000)

        tprev = time.time()
        init = 0
        
        while time.time() - tprev < 2.0:

            # Check for init gone high
            self.__chain.go_to_shift_ir()
            init = padder.unpad_ir(self.__chain.write_read(PADDED_BYPASS[0], PADDED_BYPASS[1], True), 6) & 0x10
            self.__chain.go_to_run_test_idle()
            if init:
                break

        if init == 0:
            raise Spartan6_JTAG_Exception('INIT_B did not go high')

        # Load the CFG_IN instruction
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_CFG_IN[0], PADDED_CFG_IN[1], True)
        self.__chain.go_to_run_test_idle()

        # Configuration fragment
        self.__chain.go_to_shift_dr()
        self.__chain.write(0, 46 + padder.pad_dr_len(), True)
        self.__chain.go_to_run_test_idle()

        # Load the CFG_IN instruction
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_CFG_IN[0], PADDED_CFG_IN[1], True)
        self.__chain.go_to_run_test_idle()

        # Go to SHIFT_DR
        self.__chain.go_to_shift_dr()

        # Pre-padding
        self.__chain.write(0, padder.pre_pad_dr_len(), False)

        # Load the bitstream 
        i = 0
        subarray = data[i : i + 14000]

        print '{:<9}'.format(''),

        while i + 14000 < len(data):
            self.__chain.write_bytearray(subarray, False, True)
            i = i + 14000
            subarray = data[i : i + 14000]
            print '\b\b\b\b\b\b\b\b\b\b' + '{:<9}'.format(str((i * 100) / len(data)) + '%'),
            sys.stdout.flush()

        print

        # Last block + flush padding
        self.__chain.write_bytearray(subarray, False, True)
        self.__chain.write(0, padder.post_pad_dr_len(), True)
        self.__chain.go_to_run_test_idle()
        
        # JSTART
        self.__chain.go_to_shift_ir()
        self.__chain.write(PADDED_JSTART[0], PADDED_JSTART[1], True)
        self.__chain.go_to_run_test_idle()

        # 24 clocks
        self.__chain.jtag_clock(bytearray([0]) * 24)

        tprev = time.time()
        done = 0

        while time.time() - tprev < 2.0:

            # Check for init gone high
            self.__chain.go_to_shift_ir()
            done = padder.unpad_ir(self.__chain.write_read(PADDED_BYPASS[0], PADDED_BYPASS[1], True), 6) & 0x20
            self.__chain.go_to_run_test_idle()
            if done:
                break

        if done == 0:
            raise Spartan6_JTAG_Exception('DONE did not go high')

        # Flush
        self.__chain.go_to_shift_dr()
        self.__chain.write(0, 1 + padder.pad_dr_len(), True)
        self.__chain.go_to_run_test_idle()

#    def enter_user_1_dr(self):
#        self.__chain.go_to_run_test_idle()
#        self.__chain.go_to_shift_ir()
#        self.__chain.write(USER1, 6, True)
#        self.__chain.go_to_shift_dr()
#        self.__chain.jtag_clock(bytearray([0]))

#    def enter_user_2_dr(self):
#        self.__chain.go_to_run_test_idle()
#        self.__chain.go_to_shift_ir()
#        self.__chain.write(USER2, 6, True)
#        self.__chain.go_to_shift_dr()
#        self.__chain.jtag_clock(bytearray([0]))

#    def enter_user_3_dr(self):
#        self.__chain.go_to_run_test_idle()
#        self.__chain.go_to_shift_ir()
#        self.__chain.write(USER3, 6, True)
#        self.__chain.go_to_shift_dr()
#        self.__chain.jtag_clock(bytearray([0]))

#    def enter_user_4_dr(self):
#        self.__chain.go_to_run_test_idle()
#        self.__chain.go_to_shift_ir()
#        self.__chain.write(USER4, 6, True)
#        self.__chain.go_to_shift_dr()
#        self.__chain.jtag_clock(bytearray([0]))

