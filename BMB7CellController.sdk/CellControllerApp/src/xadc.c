/*
 * Read XADC system monitor
 */
#include <stdio.h>
#include <xil_io.h>
#include <xparameters.h>
#include "xadc.h"
#include "util.h"

#define In32(offset)    Xil_In32(XPAR_XADC_WIZ_0_BASEADDR+(offset))

#define R_TEMP          0x200 /* On-chip Temperature */
#define R_VCCINT        0x204 /* FPGA VCCINT */
#define R_VCCAUX        0x208 /* FPGA VCCAUX */
#define R_VBRAM         0x218 /* FPGA VBRAM */
#define R_CFR0          0x300 /* Configuration Register 0 */
#define R_CFR1          0x304 /* Configuration Register 1 */
#define R_CFR2          0x308 /* Configuration Register 2 */
#define R_SEQ00         0x320 /* Seq Reg 00 -- Channel Selection */
#define R_SEQ01         0x324 /* Seq Reg 01 -- Channel Selection */
#define R_SEQ02         0x328 /* Seq Reg 02 -- Average Enable */
#define R_SEQ03         0x32C /* Seq Reg 03 -- Average Enable */
#define R_SEQ04         0x330 /* Seq Reg 04 -- Input Mode Select */
#define R_SEQ05         0x334 /* Seq Reg 05 -- Input Mode Select */
#define R_SEQ06         0x338 /* Seq Reg 06 -- Acquisition Time Select */
#define R_SEQ07         0x33C /* Seq Reg 07 -- Acquisition Time Select */

static void
showreg(const char *msg, unsigned int reg)
{
    printf("   %10s: %04X\n", msg, reg);
}

void
xadcInit(void)
{
    printf("XADC Configuration:\n");
    showreg("R_CFR0", In32(R_CFR0));
    showreg("R_CFR1", In32(R_CFR1));
    showreg("R_CFR2", In32(R_CFR2));
    showreg("R_SEQ00", In32(R_SEQ00));
    showreg("R_SEQ01", In32(R_SEQ01));
    showreg("R_SEQ02", In32(R_SEQ02));
    showreg("R_SEQ03", In32(R_SEQ03));
    showreg("R_SEQ04", In32(R_SEQ04));
    showreg("R_SEQ05", In32(R_SEQ05));
    showreg("R_SEQ06", In32(R_SEQ06));
    showreg("R_SEQ07", In32(R_SEQ07));
}

/*
 * Update the ADC readings
 */
uint16_t xadcVal[XADC_CHANNEL_COUNT];
void
xadcUpdate(void)
{
    xadcVal[0] = In32(R_TEMP);
    xadcVal[1] = In32(R_VCCINT);
    xadcVal[2] = In32(R_VCCAUX);
    xadcVal[3] = In32(R_VBRAM);
}
