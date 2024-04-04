"""
This script decodify the iicCommandTable.dat used by Marble i2c_chunk.v (i2cBridge) printing a report
"""

from os.path import isfile
from datetime import datetime


TCA9548_bus = {
    0: "FMC1",
    1: "FMC2",
    2: "CLK",
    3: "SO-DIM",
    4: "QSFP1",
    5: "QSFP2",
    6: "APP",
}


def main(file_path="./iicCommandTable.dat"):
    cmd_table = load_file(file_path)
    if not cmd_table: return
    else:
        report_file = f"File {cmd_table.name} - {datetime.now()}\n---- Start of report ----\n"
        report_file += "[instruction] -> description and data\n"
    for idx, cmd_line in enumerate(cmd_table):
        op_code = int(cmd_line[:2], 16) >> 5
        n_code = int(cmd_line[:2], 16) & 0x1f

        match op_code:
            case 0:  # special
                if n_code == 0:
                    report_file += f"[{hex(int(cmd_line[:2], 16))}] -> sleep\n"
                elif n_code == 2:
                    report_file += f"[{hex(int(cmd_line[:2], 16))}] -> result buffer flip\n"
                elif n_code == 3:
                    report_file += f"[{hex(int(cmd_line[:2], 16))}] -> trigger logic analyzer\n"
                elif n_code >= 16:
                    report_file += f"[{hex(int(cmd_line[:2], 16))}] -> select hardware bus {n_code-16}\
                                                                            - {TCA9548_bus[n_code-16]}\n"

            case 1:  # read
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> read - addr: \
                                  {hex(int(next(cmd_table)[:2], 16))} - data number: {n_code-1}\n"

            case 2:  # write
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> write - addr: \
                                  {hex(int(next(cmd_table)[:2], 16))} - data:"
                for j in range(n_code-1): report_file += f" {hex(int(next(cmd_table)[:2], 16))}"
                report_file += '\n'

            case 3:  # write followed by repeated start
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> write - addr: \
                                  {hex(int(next(cmd_table)[:2], 16))} - START - data:"
                for j in range(n_code-2): report_file += f" {hex(int(next(cmd_table)[:2], 16))}"
                report_file += '\n'

            case 4:  # pause (ticks are 8 bit times)
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> short pause of {n_code} cycles\n"

            case 5:  # pause (ticks are 256 bit times)
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> long pause of {n_code*32} cycles\n"

            case 6:  # jump
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> jump +{n_code} ({hex(n_code)}) lines\n"

            case 7:  # set result address
                report_file += f"[{hex(int(cmd_line[:2], 16))}] -> set result address {n_code} ({hex(n_code)})\n"
    report_file += "---- End of report ----\n"
    print(report_file)


def load_file(file_path="./iicCommandTable.dat"):
    if isfile(file_path):
        try:
            return iter(open(file_path, 'rb'))
        except Exception as e:
            print(f"Error during file opening: [{e}]")
            return None
    else:
        print(f'File "{file_path}" not found')
        return None


if __name__ == '__main__': main()
