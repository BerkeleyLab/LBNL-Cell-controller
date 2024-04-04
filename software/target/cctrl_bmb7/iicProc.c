#include <stdio.h>
#include <stdint.h>

void
iicProcTakeControl(void)
{}

void
iicProcRelinquishControl(void)
{}

int
iicProcRead(int device, int subaddress, uint8_t *buf, int n)
{
    return 1;
}

int
iicProcWrite(int device, int subaddress, uint8_t *buf, int n)
{
    return 1;
}

int
iicProcSetMux(int port)
{
    return 1;
}

int
iicProcReadFMC_EEPROM(int fmcIndex, uint8_t *buf, int n)
{
    return 1;
}

int
iicProcWriteFMC_EEPROM(int fmcIndex, uint8_t *buf, int n)
{
    return 1;
}

void
iicProcInit(void)
{}

const char *
iicProcFMCproductType(int fmcIndex)
{
    return "";
}

void
iicProcScan(void)
{}
