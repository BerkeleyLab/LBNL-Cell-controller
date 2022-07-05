/*
 * Aurora serial links
 */

#ifndef _AURORA_H_
#define _AURORA_H_

#define AURORA_LINK_COUNT           4
#define AURORA_LINK_READOUT_COUNT   4

#define AUSTATS_TIMEOUT_COUNTER_LINK    7
#define AUSTATS_TIMEOUT_COUNTER_IDX     3

void auroraInit(void);
void auroraResetGTX(void);
int  auroraReadoutIsUp(int link);
void auroraReadoutStats(int link, int idx, unsigned int *hi, unsigned int *lo);
void auroraReadoutShowStats(int showTimeout);
void auroraReadoutClearStats(void);
void auroraWriteCSR(unsigned int csr);

#endif /* _AURORA_H_ */
