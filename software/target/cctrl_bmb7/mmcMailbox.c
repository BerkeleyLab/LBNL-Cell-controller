#include <stdio.h>
#include <stdint.h>

void
mmcMailboxWrite(unsigned int address, int value)
{}

void
mmcMailboxWriteAndWait(unsigned int address, int value)
{}

int
mmcMailboxRead(unsigned int address)
{
    return 0;
}

void
mmcMailboxInit(void)
{}

uint32_t *
mmcMailboxFetchSysmon(uint32_t *ap)
{
    return NULL;
}
