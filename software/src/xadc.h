/*
 * Read XADC system monitor
 */

#ifndef _XADC_H_
#define _XADC_H_

#include <stdint.h>

#define XADC_CHANNEL_COUNT   4

void xadcInit(void);
uint32_t *xadcUpdate(uint32_t *buf);
int xadcGetFPGAtemp(void);

#endif /* _XADC_H_ */
