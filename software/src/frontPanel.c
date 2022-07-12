/*
 * Deal with front panel/interlock devices
 */

#include <stdio.h>
#include "frontPanel.h"
#include "gpio.h"
#include "util.h"

#define WR_CSR(v) GPIO_WRITE(GPIO_IDX_PILOT_TONE_CSR,(v))
#define RD_CSR() GPIO_READ(GPIO_IDX_PILOT_TONE_CSR)

#define CSR_R_RELAY_CLOSED      0x10

#define CSR_W_RELAY             0x10
#define CSR_W_LED1              0x100

int
fpModuleRelayStatus(void)
{
    return (RD_CSR() & CSR_R_RELAY_CLOSED) != 0;
}

static uint32_t csrShadow;
void
fpModuleRelayControl(int enable)
{
    if (enable) csrShadow |=  CSR_W_RELAY;
    else        csrShadow &= ~CSR_W_RELAY;
    WR_CSR(csrShadow);
}
