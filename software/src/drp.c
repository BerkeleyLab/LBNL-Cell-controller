#include <stdio.h>
#include <stdint.h>
#include <xil_io.h>
#include <xparameters.h>
#include "gpio.h"
#include "util.h"
#include "drp.h"

#define ADDR(csrIdx,reg) ((csrIdx)+((reg)<<2))

// Generic DRP functions

void
drp_gen_write(uint32_t csrIdx, int regOffset, int value)
{
    Xil_Out32(ADDR(csrIdx, regOffset), value);
}

int
drp_gen_read(uint32_t csrIdx, int regOffset)
{
    return Xil_In32(ADDR(csrIdx, regOffset));
}
