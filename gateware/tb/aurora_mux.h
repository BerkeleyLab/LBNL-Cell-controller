#ifndef _AURORA_MUX_H
#define _AURORA_MUX_H

/*
Recall: Aurora packets:
  | Header (4B) | Data X (4B) | Data Y (4B) | Data S (4B) |( CRC (4B) |)

           31                16          15         14             10     9      8               0
  Header: | Magic 0xA5BE (16b) | FOFB Enabled (1b) | Cell Index (5b) | pad (1b) | FOFB Index (9b) |
  Data X: | -------------------------- Beam Position along X axis in nm ------------------------- |
  Data Y: | -------------------------- Beam Position along Y axis in nm ------------------------- |
  Data S: | CRC Fault (1b) | ADC Clipping (1b) | --------------- Sum Value (30b) ---------------- |
  CRC:    | ---------------------------------- Aurora CRC Word ---------------------------------- |

These packets are destined for the hardware/simulated Stream MUX, so they have one additional word:
  UDP Packet Payload:
    MUXInfo: | Traffic Magic (0x0327) (16b)  | pad (14b) | nStream (2b) |
    Header:  |                    Aurora Header (32b)                   |
    Data X:  |                    Aurora Data X (32b)                   |
    Data Y:  |                    Aurora Data Y (32b)                   |
    Data S:  |                    Aurora Data S (32b)                   |
    CRC:     |                   Aurora CRC Word (32b)                  |

  nStream     Stream Dest
  -----------------------
  0           Cell CCW
  1           Cell CW
  2           BPM CCW
  3           BPM CW
*/

#define NSTREAM_CELL_CCW          (0)
#define NSTREAM_CELL_CW           (1)
#define NSTREAM_BPM_CCW           (2)
#define NSTREAM_BPM_CW            (3)

#define MUXINFO_MAGIC         (0x0327)

#define PACK_MUXINFO(nstream)   ((MUXINFO_MAGIC << 16) | (nstream & 0x03))
#define PACK_AUHEADER(fofb_en, cell_index, fofb_index) \
  ((0xA5BE <<16) | (fofb_en & 1) << 15 | (cell_index & 0x1f) << 10 | (fofb_index & 0x1ff))
#define PACK_AUDATAS(crc_fault, adc_clipping, sum) \
  ((crc_fault & 1) << 31 | (adc_clipping << 30) | (sum & 0x3fffffff))

#define UNPACK_CELL_INDEX(auHeader)     ((auHeader >> 10) & 0x1f)
#define UNPACK_FOFB_INDEX(auHeader)            (auHeader & 0x1ff)

typedef struct {
  uint32_t muxinfo;
  uint32_t auHeader;
  uint32_t auDataX;
  uint32_t auDataY;
  uint32_t auDataS;
} stream_mux_pkt_t;

#define STREAM_PACKET_SIZE      (sizeof(stream_mux_pkt_t))

#endif // _AURORA_MUX_H
