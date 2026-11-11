# Cell Controller — Configuration

> [!NOTE]
> **LBNL-Cell-controller docs:** [Overview](README.md) · [Firmware Notes](FirmwareNotes.md) · [Hardware Notes](HardwareNotes.md) · [Configuration](CellControllerConfiguration.md)<br>
> **Related projects:** [EPICS support ↗](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller/-/blob/HEAD/documentation/EPICSnotes.md) · [cell-comm ↗](https://github.com/BerkeleyLab/cell-comm)

This guide covers building, loading, and configuring the **Marble**-based cell controller.

## Contents

- [Building](#building)
- [Loading over JTAG](#loading-over-jtag)
- [Writing the Flash](#writing-the-flash)
- [Setting Network Parameters](#setting-network-parameters)
- [TFTP Server](#tftp-server)
- [Console Commands](#console-commands)
- [Network Services](#network-services)

---

## Building

Requires GNU Make and Vivado/Vitis 2020.2.2 (`vivado` and `vitis` on `PATH`). Fetch the submodules first:

```sh
git submodule update --init
make CROSS_COMPILE=<vitis>/gnu/microblaze/lin/bin/mb- APP=cctrl_aurora_8b10b PLATFORM=marble
```

| `APP` | Link protocol |
|---|---|
| `cctrl_aurora_8b10b` (default) | Aurora 8B/10B |
| `cctrl_aurora_64b66b` | Aurora 64B/66B |

The bootable image — gateware with the µBlaze software merged in — is written to:

```
software/app/<APP>/<APP>_marble.<git-hash>.bit
```

---

## Loading over JTAG

For development, load an image straight into the FPGA with OpenOCD:

```sh
cd scripts
EXTRA_OPTS= BITFILE=../software/app/<APP>/<APP>_marble.<git-hash>.bit ./deploy.sh
```

`deploy.sh` uses `scripts/marble.cfg`. It reads the image from `BITFILE` (default `cctrl_aurora_64b66b_marble.bit` in the current directory) and passes `EXTRA_OPTS` to OpenOCD as an extra command.

> [!IMPORTANT]
> Set `EXTRA_OPTS`, even to an empty value as above. The script runs with `set -u` and stops with an "unbound variable" error if it isn't defined.

This loads the FPGA only; nothing is written to flash.

---

## Writing the Flash

The flash holds two boot images, `CCTRL_A.bit` and `CCTRL_B.bit`. Write them over the network with `scripts/programFlash.sh`, which uploads the image by TFTP, reads it back, and compares:

```sh
scripts/programFlash.sh -i <cell-controller-ip> -s <image.bit> [-d CCTRL_B.bit]
```

| Option | Meaning | Default |
|---|---|---|
| `-i` | Cell controller address | *(required)* |
| `-s` | Image to upload | `CCTRL_A.bit` |
| `-d` | Flash slot to write | `CCTRL_A.bit` |

Look for **Flash write succeeded.**

> [!NOTE]
> A comment in `software/src/tftp.c` notes that the first half of the flash (which holds `CCTRL_A.bit`) is write protected.

A safe update sequence:

1. Write the new image to `CCTRL_B.bit`.
2. Run `boot -b` on the console and confirm with `y` to start it.
3. If it works, write the same image to `CCTRL_A.bit` and run `boot`. If not, reboot to return to the existing A image.

---

## Setting Network Parameters

If the network parameters in flash are missing or invalid, the cell controller starts with these defaults and prints *Invalid parameters in flash -- Assigning default parameters* on the console:

| Setting | Default |
|---|---|
| IPv4 address | `192.168.1.180/24` |
| Gateway | `192.168.1.1` |
| Ethernet MAC | `AA:4C:42:4E:4C:09` |

To set them:

1. Connect to the console, either through the Marble USB serial port or over the network with the support module's [`console.py`](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller/-/blob/HEAD/documentation/EPICSnotes.md#support-scripts).
2. Run `net www.xxx.yyy.zzz[/n]` and `mac aa:bb:cc:dd:ee:ff`, answering `y` to write each to flash.
3. Reboot.

---

## TFTP Server

| Name | Flash location | Size | Description |
|---|---|--:|---|
| `CCTRL_A.bit` | 0 MiB | 7 MiB | Primary boot image |
| `CCTRL_B.bit` | 8 MiB | 7 MiB | Alternate boot image, started with `boot -b` |
| `SystemParameters.bin` | 15 MiB | 4 KiB | Network settings, Aurora reference clock trim, startup debug flags |
| `FullFlash.bin` | 0 MiB | 16 MiB | Entire flash |
| `FMC1_EEPROM.bin` | — | 256 B | IPMI EEPROM of the card in FMC 1 |
| `FMC2_EEPROM.bin` | — | 256 B | IPMI EEPROM of the card in FMC 2 |

Transfer files in binary mode. Downloading a `.bit` or `.bin` file returns the whole area, so the result is padded beyond the uploaded image.

---

## Console Commands

The console is available on the Marble USB serial port and on UDP port 50004 (`console.py`).

- No command history; the only editing is backspace/delete.
- Carriage return or line feed ends a line. Arguments are separated by spaces or commas.
- Commands are case-insensitive and may be shortened to any **unique** prefix — for example `fmo` for `fmon`, since `f` alone matches `fofb`, `fmps`, and `fmon`. An ambiguous prefix prints *Not unique*.
- `help` or `?` lists the commands.

| Command | Description |
|---|---|
| `boot [-b]` | Reboot the FPGA from `CCTRL_A.bit`, or `CCTRL_B.bit` with `-b`. Asks for confirmation. |
| `bpmInhibit [bitmap]` | Inhibit packet reception on BPM links (hex: 0 none, 1 CCW, 2 CW, 3 both). Without an argument, shows the current state. |
| `cellInhibit [bitmap]` | Same, for the cell controller links. Bit 2 (`4`) substitutes fake data. |
| `debug [-s] [-h] [flags]` | Show or set the debug flags (hex). `-s` also saves them in flash as the startup value; `-h` lists the flags. |
| `evr` | Show event receiver status and the current EVR time. |
| `fmon` | Show the FPGA clock frequencies. |
| `fmps [i [n]]` | Show *n* (default 1) fast MPS values starting at *i*. |
| `fofb [i [n]]` | Show *n* (default 1) fast orbit feedback deviation values starting at index *i* (0–511). |
| `gtx [-n\|-r] [lane]` | Eye scan of an Aurora GTX receiver. `-n` shows log₂ error counts as hex digits, `-r` raw counts. EPICS communication and fast feedback continue meanwhile. |
| `log` | Replay the startup messages. |
| `mac [aa:bb:cc:dd:ee:ff]` | Show the MAC address, or set it in flash (with confirmation). |
| `net [www.xxx.yyy.zzz[/n]]` | Show the network settings, or set them in flash (with confirmation). |
| `pslink` | Show the status of the fiber Ethernet link to the power supplies. |
| `qsfp` | Show QSFP module status. |
| `reg [r [n]]` | Show *n* (default 1) GPIO registers starting at *r*. |
| `stats [0]` | Show the Aurora link statistics; clear them afterwards with `0`. |
| `tlog` | Log timing system events (heartbeats, PPS with decoded time, other events with tick intervals) until a key is pressed. |
| `userMGT [ppm]` | Show or trim the Aurora MGT reference clock, ±3500 ppm. The setting is saved in flash. |
| `wAurora [reg]` | Write the Aurora/GTX reset CSR (hex), then show the link statistics. |

### Debug flags

| Mask | Effect |
|---|---|
| `0x1` | EPICS UDP messages |
| `0x2` | TFTP messages |
| `0x4` | Boot flash messages |
| `0x8` | Power supply waveform recorder transactions |
| `0x10` | Arbitrary waveform generator transactions |
| `0x20` | Setpoint updates |
| `0x800` | I²C processing |
| `0x1000` | Show the frequency counters (runs `fmon`) |
| `0x4000` | Show a snapshot of the power supply setpoints |
| `0x8000` | Restart the fast power supply Ethernet links |
| `0x10000` | Scan the I²C buses |
| `0x20000` | Show MGT resets |
| `0x40000` | Show the receive aligner |
| `0x80000` | Si570 setting messages |
| `0x100000` | Show FOFB values in hex |
| `0x200000` | Show FMPS values in hex |
| `0x1000000` | Show MGT clock switch activity |
| `0x2000000` | Dump the MGT clock switch registers |

---

## Network Services

| UDP port | Service |
|--:|---|
| 69 | TFTP server |
| 50004 | Network console |
| 50006 | EPICS protocol ([support module](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller)) |
