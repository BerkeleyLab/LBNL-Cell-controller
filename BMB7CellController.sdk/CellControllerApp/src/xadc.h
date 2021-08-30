/*
 * Read XADC system monitor
 */

#ifndef _XADC_H_
#define _XADC_H_

#include <stdint.h>

#define XADC_CHANNEL_COUNT   4

extern uint16_t xadcVal[XADC_CHANNEL_COUNT];

void xadcInit(void);
void xadcUpdate(void);


#endif /* _XADC_H_ */
