/*
 * Quad small-form pluggable transceiver support
 */
#ifndef _QSFP_H_
#define _QSFP_H_

#define QSFP_COUNT    2
#define QSFP_RX_COUNT 4

void qsfpInit(void);
void qsfpShowInfo(void);
void qsfpDump(void);
void qsfpShowMonitor(void);
int qsfpRxPower(int qsfpIndex, int channel);
int qsfpVoltage(int qsfpIndex);
int qsfpTemperature(int qsfpIndex);

#endif /* _QQSFP_H_ */
