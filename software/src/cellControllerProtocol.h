#ifndef _CELL_CONTROLLER_PROTOCOL_
#define _CELL_CONTROLLER_PROTOCOL_

#include <stdint.h>
#include <assert.h>

#define CC_PROTOCOL_UDP_PORT        50006
#define CC_PROTOCOL_MAGIC           0xCC001245
#define CC_PROTOCOL_MAGIC_SWAPPED   0x451200CC
#define CC_PROTOCOL_ARG_CAPACITY    350

#define CC_PROTOCOL_MAX_CELLS               32
#define CC_PROTOCOL_MAX_BPM_PER_CELL        32
#define CC_PROTOCOL_FOFB_CAPACITY_PER_PLANE 512
#define CC_PROTOCOL_FOFB_CORRECTOR_CAPACITY 24
#define CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE 1000
#define CC_PROTOCOL_FMPS_CAPACITY           32

struct ccProtocolPacket {
    uint32_t        magic;
    uint32_t        nonce;
    uint32_t        command;
    uint32_t        cellInfo; /* Cell BPM count, Cell count, Cell index */
    uint32_t        args[CC_PROTOCOL_ARG_CAPACITY];
};

static_assert(sizeof(struct ccProtocolPacket) == 1416,
    "ccProtocolPacket size is incorrect, potential padding or member count issue");

#define CC_PROTOCOL_SIZE_TO_ARG_COUNT(s) (CC_PROTOCOL_ARG_CAPACITY - \
                    ((sizeof(struct ccProtocolPacket)-(s))/sizeof(uint32_t)))
#define CC_PROTOCOL_ARG_COUNT_TO_SIZE(a) (sizeof(struct ccProtocolPacket) - \
                        ((CC_PROTOCOL_ARG_CAPACITY - (a)) * sizeof(uint32_t)))
#define CC_PROTOCOL_ARG_COUNT_TO_U32_COUNT(a) \
                    ((sizeof(struct ccProtocolPacket) / sizeof(uint32_t)) - \
                                            (CC_PROTOCOL_ARG_CAPACITY - (a)))
#define CC_PROTOCOL_U32_COUNT_TO_ARG_COUNT(u) (CC_PROTOCOL_ARG_CAPACITY - \
                    (((sizeof(struct ccProtocolPacket)/sizeof(uint32_t)))-(u)))

#define CC_PROTOCOL_CMD_MASK_HI                     0xFF000000
#define CC_PROTOCOL_CMD_MASK_LO                     0x00FF0000
#define CC_PROTOCOL_CMD_MASK_IDX                    0x0000FFFF

#define CC_PROTOCOL_CMD_HI_LONGIN                   0x00000000
# define CC_PROTOCOL_CMD_LONGIN_IDX_GIT_HASH_ID     0x02

#define CC_PROTOCOL_CMD_HI_SYSMON                   0x01000000
# define CC_PROTOCOL_CMD_SYSMON_LO_INT32            0x000000
# define CC_PROTOCOL_CMD_SYSMON_LO_UINT16_LO        0x010000
# define CC_PROTOCOL_CMD_SYSMON_LO_UINT16_HI        0x020000
# define CC_PROTOCOL_CMD_SYSMON_LO_INT16_LO         0x030000
# define CC_PROTOCOL_CMD_SYSMON_LO_INT16_HI         0x040000

#define CC_PROTOCOL_CMD_HI_LINKSTATS                0x02000000
# define CC_PROTOCOL_CMD_LINKSTATS_LO_INT32         0x000000
# define CC_PROTOCOL_CMD_LINKSTATS_LO_UINT16_LO     0x010000
# define CC_PROTOCOL_CMD_LINKSTATS_LO_UINT16_HI     0x020000
# define CC_PROTOCOL_CMD_LINKSTATS_LO_INT16_LO      0x030000
# define CC_PROTOCOL_CMD_LINKSTATS_LO_INT16_HI      0x040000
# define CC_PROTOCOL_CMD_LINKSTATS_LO_UINT64        0x050000

#define CC_PROTOCOL_CMD_HI_FOFB_ROW                 0x09000000
#define CC_PROTOCOL_CMD_HI_FOFB_FIR                 0x0A000000
#define CC_PROTOCOL_CMD_HI_PS_OFFSET                0x0B000000
#define CC_PROTOCOL_CMD_HI_FOFB_GAIN                0x0C000000

#define CC_PROTOCOL_CMD_HI_CLIP_LIMIT               0x0D000000
# define CC_PROTOCOL_CMD_LO_CLIP_LIMIT_PS           0x000000
# define CC_PROTOCOL_CMD_LO_CLIP_LIMIT_FFB          0x010000

#define CC_PROTOCOL_CMD_HI_I32ARRAY_OUT             0x0F000000
# define CC_PROTOCOL_CMD_LO_I32A_BPM_SETPOINTS      0x000000

#define CC_PROTOCOL_CMD_HI_F32ARRAY_OUT             0x11000000
# define CC_PROTOCOL_CMD_LO_F32A_AWG_PATTERN        0x000000

#define CC_PROTOCOL_CMD_HI_LONGOUT                  0x12000000
# define CC_PROTOCOL_CMD_LONGOUT_LO_GENERIC         0x000000
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_FORCE_GTX_RESET         0x00
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_ENABLE_FAST_FEEDBACK    0x02
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_PS_BITMAP       0x03
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_PRETRIG_COUNT   0x04
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_POSTTRIG_COUNT  0x05
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_PS_TRIG_EVENT   0x06
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_ARM                 0x07
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SOFT_TRIGGER        0x08
# define CC_PROTOCOL_CMD_LONGOUT_LO_FOFB_RB_MODE    0x010000
# define CC_PROTOCOL_CMD_LONGOUT_LO_PS_OFFSET       0x020000
# define CC_PROTOCOL_CMD_LONGOUT_LO_AWG             0x030000
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_ENABLE          0x00
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_SOFT_TRIGGER    0x01
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_CONTROL         0x02
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_INTERVAL        0x03
#  define CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_EVENT           0x04
# define CC_PROTOCOL_CMD_LONGOUT_LO_NO_VALUE        0x0040000
#  define CC_PROTOCOL_CMD_LONGOUT_NV_IDX_CLEAR_POWERUP_STATUS  0x00

#define CC_PROTOCOL_CMD_HI_WAVEFORM                 0x20000000
#define CC_PROTOCOL_PS_WAVEFORM_CAPACITY            32768

#endif /* _CELL_CONTROLLER_PROTOCOL_ */
