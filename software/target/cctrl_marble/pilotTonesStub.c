/*
 * Communicate with pilot tone generator devices
 */

#include <stdio.h>
#include <stdint.h>

unsigned int
ptADC(int idx)
{
    return 0;
}

unsigned int
ptTemperature(int idx)
{
    return 0;
}

unsigned int
ptPLLvalue(int pllIndex, int idx)
{
    return 0;
}

void
ptPLLoutputControl(int pllIndex, int outputIndex, int value)
{}

void
ptAttenWrite(int attnIndex, int value)
{}

void
ptCrank(void)
{}

void
ad9520show(void)
{}

int
ad9520RegIO(int idx, unsigned int value)
{
    return 0;
}

void
ad9520SetTable(int pllIndex, int tableIndex)
{}

unsigned int
ptPLLtable(int pllIndex)
{
    return 0;
}

void
max5802write(int select, int value)
{}

int
setPilotToneReference(int rfClockDivider)
{
    return 0;
}

void
ptInit(void)
{}

void
ptSync(void)
{}
