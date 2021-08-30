/*
 * Power supply arbitrary waveform generator
 */

#ifndef _PSAWG_H_
#define _PSAWG_H_

#include <stdint.h>

void psAWGstashSamples(uint32_t *samples, int base, int count);
int psAWGcommand(int addrIdx, uint32_t value);

#endif /* _PSAWG_H_ */
