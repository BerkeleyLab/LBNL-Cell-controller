/*
 * DRP control
 */

#ifndef _DRP_H_
#define _DRP_H_

#define DRP_REG_ES_QUAL_MASK0     0x031
#define DRP_REG_ES_QUAL_MASK1     0x032
#define DRP_REG_ES_QUAL_MASK2     0x033
#define DRP_REG_ES_QUAL_MASK3     0x034
#define DRP_REG_ES_QUAL_MASK4     0x035
#define DRP_REG_ES_SDATA_MASK0    0x036
#define DRP_REG_ES_SDATA_MASK1    0x037
#define DRP_REG_ES_SDATA_MASK2    0x038
#define DRP_REG_ES_SDATA_MASK3    0x039
#define DRP_REG_ES_SDATA_MASK4    0x03A
#define DRP_REG_ES_PS_VOFF        0x03B
#define DRP_REG_ES_HORZ_OFFSET    0x03C
#define DRP_REG_ES_CSR            0x03D
#define DRP_REG_ES_ERROR_COUNT    0x14F
#define DRP_REG_ES_SAMPLE_COUNT   0x150
#define DRP_REG_ES_STATUS         0x151
#define DRP_REG_PMA_RSV2          0x082
#define DRP_REG_TXOUT_RXOUT_DIV   0x088
#define DRP_LANE_SELECT_SHIFT 11 /* 2048 bytes per DRP lane */

void drp_gen_write(uint32_t csrIdx, int regOffset, int value);
int drp_gen_read(uint32_t csrIdx, int regOffset);

#endif
