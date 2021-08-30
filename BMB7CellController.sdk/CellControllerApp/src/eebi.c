#include <stdio.h>
#include "cellControllerProtocol.h"
#include "eebi.h"
#include "evr.h"
#include "gpio.h"
#include "util.h"

#define EEBI_CSR_SET_ADDRESS            0x80000000
#define EEBI_CSR_SIMULATE_RESET_PRESS   0x40000000
#define EEBI_ADDRESS_EEBI_SELECT_SHIFT  3
#define EEBI_ADDRESS_SET_CURRENT_STATUS 0x7

#define EEBI_CSR_R_RESET_BUTTON_PRESSED     0x80000000
#define EEBI_CSR_R_COEFFICIENTS_VALID_AU    0x4000000
#define EEBI_CSR_R_BPM_TIMEOUT_AU           0x2000000
#define EEBI_CSR_R_BEAM_CURRENT_TIMEOUT_AU  0x1000000
#define EEBI_CSR_R_FAULT_MASK               0x700
#define EEBI_CSR_R_FAULT_SHIFT              8
#define EEBI_CSR_R_BEAM_CURRENT_ABOVE_LIMIT 0x10
#define EEBI_CSR_R_BEAM_CURRENT_TIMEOUT     0x8
#define EEBI_CSR_R_STATE_MASK               0x7

#define EEBI_CURRENT_ABOVE_THRESHOLD 0x1
#define EEBI_HAVE_COEFFICIENTS       0x2

static uint32_t haveCoefficients;

static void
setCoefficient(int eebi, int i, uint32_t v)
{
    GPIO_WRITE(GPIO_IDX_EEBI_CSR, EEBI_CSR_SET_ADDRESS | 
                                  (eebi << EEBI_ADDRESS_EEBI_SELECT_SHIFT) | i);
    GPIO_WRITE(GPIO_IDX_EEBI_CSR, v & ~EEBI_CSR_SET_ADDRESS);
}

/*
 * Second-last value is beam current limit (mA).
 * Last value is beam current (mA) as provided by EPICS.
 * Perform comparison here rather than in IOC since someday we may want
 * to use our own measurement of beam current (from LTC2945A ADC on
 * pilot tone generator board) instead.
 */
void
eebiConfig(const uint32_t *args)
{
    int eebi, i, argIndex = 0;
    uint32_t beamCurrentLimit = args[EEBI_ARG_COUNT-2];
    uint32_t beamCurrent = args[EEBI_ARG_COUNT-1];
    static uint32_t oldValue[CC_PROTOCOL_EEBI_COUNT][EEBI_COEFFICIENT_COUNT];
    static int beenHere = 0;

    for (eebi = 0 ; eebi < CC_PROTOCOL_EEBI_COUNT ; eebi++) {
        for (i = 0 ; i < EEBI_COEFFICIENT_COUNT ; i++) {
            if (!beenHere || (args[argIndex] != oldValue[eebi][i])) {
                setCoefficient(eebi, i, args[argIndex]);
                oldValue[eebi][i] = args[argIndex];
            }
            argIndex++;
        }
    }
    beenHere = 1;
    setCoefficient(0, EEBI_ADDRESS_SET_CURRENT_STATUS, haveCoefficients |
                                        ((beamCurrent > beamCurrentLimit) ?
                                             EEBI_CURRENT_ABOVE_THRESHOLD : 0));
}

/*
 * Get reason and time of most recent relay deactivation.
 * Try to ensure a consistent set of state, seconds and ticks.
 * If no fault info has been set, just return time at boot.
 */
void
eebiFetchFaultInfo(uint32_t *state, uint32_t *seconds, uint32_t *ticks)
{
    int pass = 0;
    uint32_t nSeconds, nTicks;

    *seconds = GPIO_READ(GPIO_IDX_EEBI_FAULT_TIME_SECONDS);
    *ticks = GPIO_READ(GPIO_IDX_EEBI_FAULT_TIME_TICKS);
    while (++pass < 10) {
        *state = (GPIO_READ(GPIO_IDX_EEBI_CSR) & EEBI_CSR_R_FAULT_MASK) >>
                                                         EEBI_CSR_R_FAULT_SHIFT;
        nSeconds = GPIO_READ(GPIO_IDX_EEBI_FAULT_TIME_SECONDS);
        nTicks = GPIO_READ(GPIO_IDX_EEBI_FAULT_TIME_TICKS);
        if ((nSeconds == *seconds) && (nTicks == *ticks)) break;
        *seconds = nSeconds;
        *ticks = nTicks;
    }
    if (*seconds == 0) {
        *seconds = evrSecondsAtBoot();
        *ticks = 0;
    }
}

/*
 * Let EEBI know that this cell's setpoints are valid
 */
void
eebiHaveSetpoints(void)
{
    haveCoefficients = EEBI_HAVE_COEFFICIENTS;
}

/*
 * Simulate press of front panel interlock reset
 */
void
eebiResetInterlock(void)
{
    GPIO_WRITE(GPIO_IDX_EEBI_CSR, EEBI_CSR_SET_ADDRESS | EEBI_CSR_SIMULATE_RESET_PRESS);
    GPIO_WRITE(GPIO_IDX_EEBI_CSR, EEBI_CSR_SET_ADDRESS);
}
