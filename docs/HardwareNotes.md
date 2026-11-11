# Cell Controller — Hardware Notes

> [!NOTE]
> **LBNL-Cell-controller docs:** [Overview](README.md) · [Firmware Notes](FirmwareNotes.md) · [Hardware Notes](HardwareNotes.md) · [Configuration](CellControllerConfiguration.md)<br>
> **Related projects:** [EPICS support ↗](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller/-/blob/HEAD/documentation/EPICSnotes.md) · [cell-comm ↗](https://github.com/BerkeleyLab/cell-comm)

The cell controller runs on a **Marble** FPGA carrier (Kintex-7).

## Contents

- [Marble Platform](#marble-platform)
  - [Transceiver assignments](#transceiver-assignments)
  - [MGT reference clocks](#mgt-reference-clocks)
  - [Indicators](#indicators)

---

## Marble Platform

### Transceiver assignments

From `gateware/top/common_cctrl/common_cctrl_top_pins.xdc` and `common_cctrl_top.v`:

| QSFP channel | Fiber pair | Tile | MGT | TX P/N | RX P/N | Function |
|---|:---:|:---:|---|:---:|:---:|---|
| QSFP1-0 | 1/12 | X0Y5 | Bank 116 MGT 1 | D2/D1 | E4/E3 | Event receiver |
| QSFP1-1 | 2/11 | X0Y6 | Bank 116 MGT 2 | B2/B1 | C4/C3 | BPM CCW |
| QSFP1-2 | 3/10 | X0Y4 | Bank 116 MGT 0 | F2/F1 | G4/G3 | BPM CW |
| QSFP1-3 | 4/9 | X0Y7 | Bank 116 MGT 3 | A4/A3 | B6/B5 | BPM test link |
| QSFP2-0 | 1/12 | X0Y1 | Bank 115 MGT 1 | M2/M1 | N4/N3 | Cell CCW |
| QSFP2-1 | 2/11 | X0Y2 | Bank 115 MGT 2 | K2/K1 | L4/L3 | Cell CW |
| QSFP2-2 | 3/10 | X0Y0 | Bank 115 MGT 0 | P2/P1 | R4/R3 | FOFB power supply chain (Tx) |
| QSFP2-3 | 4/9 | X0Y3 | Bank 115 MGT 3 | H2/H1 | J4/J3 | FOFB power supply chain (Rx) |

The EPICS QSFP power records number the channels 1–4 rather than 0–3; see [System Monitors](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller/-/blob/HEAD/documentation/EPICSnotes.md#qsfp-modules).

### MGT reference clocks

| Reference | Pins (P/N) | Schematic net | Use |
|---|:---:|---|---|
| MGTREFCLK0_116 | D6/D5 | MGT_CLK_0 | Event receiver reference (≈125 MHz) |
| MGTREFCLK1_116 | F6/F5 | MGT_CLK_1 | Aurora reference (125 MHz) |
| MGTREFCLK0_115 | H6/H5 | MGT_CLK_2 | 125 MHz reference |
| MGTREFCLK1_115 | K6/K5 | MGT_CLK_3 | Unused |

The Aurora reference can be trimmed in ppm with the [`userMGT`](CellControllerConfiguration.md#console-commands) console command.

### Indicators

| Indicator | Behavior |
|---|---|
| Marble LD16 | Follows event receiver trigger bus bit 0 |
| Marble LD17 | Off |

The gateware also computes three front-panel LED states — EVR heartbeat, cell link status, and BPM link status (red: both links down, yellow: one down, green: both up) — but they aren't connected to any Marble pins yet.
