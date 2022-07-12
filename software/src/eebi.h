/*
 * Errant Electron Beam Interlock
 */
#ifndef _EEBI_H_
#define _EEBI_H_

#include <stdint.h>

/* BPM B:A selection, Offset A, Offset B, Limit A, Limit B, Skew limit */
#define EEBI_COEFFICIENT_COUNT      6
#define EEBI_ARG_COUNT  ((CC_PROTOCOL_EEBI_COUNT*EEBI_COEFFICIENT_COUNT)+2)

void eebiConfig(const uint32_t *args);
void eebiFetchFaultInfo(uint32_t *state, uint32_t *seconds, uint32_t *ticks);
void eebiHaveSetpoints(void);
void eebiResetInterlock(void);

#endif /* _EEBI_H_ */
