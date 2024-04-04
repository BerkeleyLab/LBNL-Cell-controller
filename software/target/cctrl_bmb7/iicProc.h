/*
 * I2C I/O from processor
 */

#ifndef _IICPROC_H_
#define _IICPROC_H_

void iicProcInit(void);
const char *iicProcFMCproductType(int fmcIndex);

void iicProcTakeControl(void);
void iicProcRelinquishControl(void);

int iicProcSetMux(int port);
int iicProcRead(int device, int subaddress, uint8_t *buf, int n);
int iicProcWrite(int device, int subaddress, uint8_t *buf, int n);
int iicProcReadFMC_EEPROM(int fmcIndex, uint8_t *buf, int n);
int iicProcWriteFMC_EEPROM(int fmcIndex, uint8_t *buf, int n);
void iicProcScan(void);

#endif /* _IICPROC_H_ */
