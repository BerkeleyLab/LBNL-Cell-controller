/*
 * Configuration parameters shared between software and firmware
 * The restrictions noted in gpio.h apply here, too.
 */

#ifndef _CONFIG_H_
#define _CONFIG_H_

#include <assert.h>

/*
 * Number of internal fans
 */
#define CFG_FAN_COUNT   2

/*
 * FOFB DSP definifions
 */
#define CFG_DSP_CMD_LATCH_ADDRESS        0
#define CFG_DSP_CMD_LATCH_HIGH_VALUE     1
#define CFG_DSP_CMD_WRITE_MATRIX_ELEMENT 2
#define CFG_DSP_CMD_WRITE_FOFB_GAIN      3
#define CFG_DSP_CMD_WRITE_PS_OFFSET      4
#define CFG_DSP_CMD_WRITE_PS_CLIP_LIMIT  5
#define CFG_DSP_CMD_WRITE_FFB_CLIP_LIMIT 6
#define CFG_DSP_CMD_FIR_RELOAD           7
#define CFG_DSP_CMD_FIR_CONFIG           8
#define CFG_DSP_CMD_SHIFT                28

#define CFG_AWG_CAPACITY           8192
#define CFG_RECORDER_CAPACITY      32768
#define CFG_CHANNEL_COUNT          24
#define CFG_FOFB_MATRIX_ADDR_WIDTH 9

/*
 * FMPS definitions
 */
#define CFG_FMPS_INDEX_WIDTH       5


#endif /* _CONFIG_H_ */
