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
#define EEBI_CSR_R_RESET_STATE              0x40000000
#define EEBI_CSR_R_EEBI_RELAY_CONTROL       0x10000000
#define EEBI_CSR_R_TRIP_STATUS              0x4000000
#define EEBI_CSR_R_COEFFICIENTS_VALID_AU    0x2000000
#define EEBI_CSR_R_BPM_TIMEOUT_AU           0x1000000
#define EEBI_CSR_R_FIRST_TRIP_MASK          0x3F0000
#define EEBI_CSR_R_FIRST_TRIP_SHIFT         16
#define EEBI_CSR_R_TRIPS_MASK               0x3F00
#define EEBI_CSR_R_TRIPS_SHIFT              8
#define EEBI_CSR_R_BEAM_CURRENT_ABOVE_LIMIT 0x80
#define EEBI_CSR_R_BEAM_CURRENT_TIMEOUT     0x40
#define EEBI_CSR_R_FAULT_MASK               0x38
#define EEBI_CSR_R_FAULT_SHIFT              3
#define EEBI_CSR_R_STATE_MASK               0x7

#define EEBI_CURRENT_ABOVE_THRESHOLD 0x1
#define EEBI_HAVE_COEFFICIENTS       0x2

static uint32_t haveCoefficients;

static void
setCoefficient(int eebi, int i, uint32_t v)
{
    if (debugFlags & DEBUGFLAG_EEBI_CONFIG) {
        printf("setCoefficient eebi:%d  i:%d  v:%d\n", eebi, i, (int)v);
    }
    GPIO_WRITE(GPIO_IDX_EEBI_CSR, EEBI_CSR_SET_ADDRESS | 
                                  (eebi << EEBI_ADDRESS_EEBI_SELECT_SHIFT) | i);
    GPIO_WRITE(GPIO_IDX_EEBI_CSR, v & ~EEBI_CSR_SET_ADDRESS);
}

static void
showSelection(char name, int s)
{
    int chan = s & CC_PROTOCOL_EEBI_CONFIG_ID_MASK;
    char plane = (s & CC_PROTOCOL_EEBI_CONFIG_PLANE_MASK) ? 'Y' : 'X';
    printf("  %c:%c:%d", name, plane, chan);
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
            uint32_t arg = args[argIndex];
            if (debugFlags & DEBUGFLAG_EEBI_CONFIG) {
                static const char *parmName[] = {
                    "Select",
                    "Offset A",
                    "Offset B",
                    "Limit A",
                    "Limit B",
                    "Skew",
                };
                printf("EEBI %d %9s: ", eebi, parmName[i]);
                if (i == 0) {
                    showSelection('A', arg);
                    showSelection('B', arg >> 16);
                }
                else {
                    printf("%d", (int)arg);
                }
                printf("\n");
            }
            if (!beenHere || (args[argIndex] != oldValue[eebi][i])) {
                setCoefficient(eebi, i, arg);
                oldValue[eebi][i] = arg;
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
        *state = GPIO_READ(GPIO_IDX_EEBI_CSR);
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
