/*
 * IIC readout using i2c_chunk firmware
 */
#include <stdio.h>
void
iicChunkInit(void)
{}

uint32_t *
iicChunkReadback(uint32_t *buf)
{
    return NULL;
}

int
iicChunkIsQSFP2present(void)
{
    return 0;
}

void
iicChunkSuspend(void)
{}

void
iicChunkResume(void)
{}
