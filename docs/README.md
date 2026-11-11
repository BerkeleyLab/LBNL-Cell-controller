# Cell Controller — Firmware and Hardware Documentation

This folder documents the cell controller **gateware, µBlaze software, and hardware**. The cell controllers gather beam positions from their local BPMs, share them around the storage ring over Aurora fiber links, and compute the fast orbit feedback corrector setpoints.

| Document | What's inside |
|---|---|
| 💾 [Firmware Notes](FirmwareNotes.md) | BPM readout, cell-to-cell replication, setpoint computation (matrix, FIR, gain, clipping) |
| 🔧 [Hardware Notes](HardwareNotes.md) | Marble transceiver and reference clock assignments, indicators |
| ⚙️ [Configuration](CellControllerConfiguration.md) | Building, JTAG loading, flash updates, network setup, TFTP files, console commands |

## Reference documents

| Document | Contents |
|---|---|
| [LTC4310](DataSheets/431012fa.pdf) | Hot-swappable I²C isolator datasheet |
| [TCA6416A](DataSheets/tca6416a.pdf) | 16-bit I²C I/O expander datasheet |
| [CFPB](DataSheets/CFPB.pdf), [CPIIB](DataSheets/CPIIB.pdf) | Chassis board schematics |
| [Pilot tone generator](DataSheets/PilotTone.pdf) | Pilot tone generator schematics |
| [PilotToneREFMON.ods](notes/PilotToneREFMON.ods) | Pilot tone REFMON notes |

The `.graffle` files are the OmniGraffle sources for the `.svg` figures; `make` regenerates the SVGs from PDFs exported from OmniGraffle.

## Related projects

| Project | Documentation |
|---|---|
| **[sioccellcontroller](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller)** — EPICS support module and IOC: records, `cctrlConfigure`, screens, scripts | [EPICS Support ↗](https://git.als.lbl.gov/accelerator-controls/epics/iocs/sioccellcontroller/-/blob/HEAD/documentation/EPICSnotes.md) |
| **[cell-comm](https://github.com/BerkeleyLab/cell-comm)** — Cell communication gateware modules, included here as the `gateware/submodules/cell-comm` submodule | [Repository ↗](https://github.com/BerkeleyLab/cell-comm) |
