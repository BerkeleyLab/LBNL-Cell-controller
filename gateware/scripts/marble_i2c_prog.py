# Marble-specific I2C map and associated functions

import sys
try:
    import marble_i2c
except ImportError:
    raise Exception("Must set PYTHONPATH=path/to/bedrock/projects/test_marble_family")

qsfp_init_d = {
    # Address : (size, fmt_string)
    148 : (16, "QSFP{}_VENDOR_NAME"),
    168 : (16, "QSFP{}_PART_NAME"),
    184 : (2, "QSFP{}_REVISION_CODE"),
    186 : (2, "QSFP{}_WAVELENGTH"),
    196 : (16, "QSFP{}_SER_NUM"),
    212 : (8, "QSFP{}_DATE_CODE")
    }

qsfp_poll_d = {
    2  : (1, "QSFP{}_MODULE_STATUS"),
    22 : (2, "QSFP{}_TEMPERATURE"),
    26 : (2, "QSFP{}_VSUPPLY"),
    34 : (8, "QSFP{}_RXPOWER"), # 4 channels, 2 bytes each
    42 : (8, "QSFP{}_TXBIAS"), # 4 channels, 2 bytes each
    50 : (8, "QSFP{}_TXPWR"), # 4 channels, 2 bytes each
    128: (2, "QSFP{}_IDENTIFIER"), # identifier and extended identifier
    }

class MarbleI2CProg(marble_i2c.MarbleI2C):
    def __init__(self, i2c_assembler=None):
        super().__init__(i2c_assembler)
        self.INA219_list = ["U17", "U32", "U57"]
        # Overriden values. Check marble_i2c.py class
        # for bit meaning
        self.u34_port0_out = 0b01001000
        self.u34_port1_out = 0b01001000
        self.u39_port0_out = 0b00000000


    def INA219_read_config(self, ic_name, reg_name=None):
        """Add a read instruction to the I2C program to read the value of the config register within 219 IC given by 'ic_name'
        Params:
            string ic_name: One of ('U17', 'U32', or 'U57')
            string reg_name: The name to be used in the memory map for the result address
        Gotchas:
            Raises an Exception if you specify an IC other than the three listed above
        """
        matched = False
        for index, name in self._ina219_map.items():
            if name == ic_name:
                matched = True
        if not matched:
            raise Exception(f"Using 219 helper function on incompatible IC {ic_name}")
        ina219_reg_cfg = 0  # Just for clarity
        return self.read(ic_name, ina219_reg_cfg, 2, reg_name=reg_name)


    def qsfp_init(self, qsfp_n=0):
        return self.qsfp_read_many(qsfp_n, qsfp_init_d)


    def qsfp_poll(self, qsfp_n=0):
        return self.qsfp_read_many(qsfp_n, qsfp_poll_d)


    def busmux_reset(self):
        if self._s is None:
            return
        # TODO - enable this functionality
        self._s.pause(10)
        self._s.hw_config(2)  # turn on reset
        self._s.pause(10)
        self._s.hw_config(0)  # turn off reset
        self._s.pause(10)
        return


    # Overridden
    def bsp_config(self):
        self.busmux_reset()
        self.U34_configure()
        self.U39_configure()
        return


    def bsp_init(self):
        for ina in self.INA219_list:
            self.INA219_read_config(ina, reg_name=f"{ina}_CFG")
        return


    # Overridden
    def bsp_poll(self):
        self.U34_read_data()
        self.U39_read_data()
        for ina in self.INA219_list:
            self.INA219_read_shunt_voltage(ina, reg_name=f"{ina}_SHUNTV")
            self.INA219_read_bus_voltage(ina, reg_name=f"{ina}_BUSV")
        return


def build_prog(argv):
    m = MarbleI2CProg()

    # ======= Program Instructions =======
    # Setup
    m.set_resx(0)  # Start from address 0
    m.bsp_config()
    m.bsp_init()
    m.qsfp_init(0)
    m.qsfp_init(1)
    # HACK! Doing this twice so this info is in both buffers
    m.buffer_flip()
    m.set_resx(0)  # Start from address 0
    m.bsp_init()
    m.qsfp_init(0)
    m.qsfp_init(1)
    # Loop start
    jump_n = m.jump_pad()
    # Required after a jump point before reading
    m.set_resx()

    # Read board configuration
    m.hw_config(1)
    m.bsp_poll()
    # Read QSFP1 dynamic params
    m.qsfp_poll(0)
    # Read QSFP2 dynamic params
    m.qsfp_poll(1)

    m.buffer_flip()
    m.pause(4096)  # Pause for roughly 0.24ms
    m.hw_config(0)
    m.pause(4096)  # Pause for roughly 0.24ms
    m.jump(jump_n) # Jump back to loop start

    # ======= End Program =======
    if len(argv) > 1:
        op = argv[1]
        if len(argv) > 2:
            offset = _int(argv[2])
        else:
            offset = 0

        if op == 'p':
            m.write_program()
        else:
            m.write_reg_map(offset=offset, style=op)
        return 0

if __name__ == "__main__":
    build_prog(sys.argv)
