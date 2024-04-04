/*
 * I2C I/O from firmware
 */

#ifndef _IICCHUNK_H_
#define _IICCHUNK_H_

void iicChunkInit(void);
uint32_t *iicChunkReadback(uint32_t *buf);
int iicChunkIsQSFP2present(void);
void iicChunkSuspend(void);
void iicChunkResume(void);

#endif /* _IICCHUNK_H_ */
