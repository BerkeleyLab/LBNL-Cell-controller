// simplatform.h

#ifndef _SIMPLATFORM_H_
#define _SIMPLATFORM_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <ctype.h> // for isprint()
#include "xil_io.h"

int simService(void);

int udpInit(uint32_t csrAddress, const char *name);

int udpRxCheck32(unsigned int udpIndex, uint32_t *dest, int capacity);
int udpTx32(unsigned int udpIndex, const uint32_t *src, int count);
int udpTxIsBusy(unsigned int udpIndex);

int udpRxCheck8(unsigned int udpIndex, uint8_t *dest, int capacity);
int udpTx8(unsigned int udpIndex, const uint8_t *src, int count);

#ifdef __cplusplus
}
#endif

#endif /* _SIMPLATFORM_H_ */
