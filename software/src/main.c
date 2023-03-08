#include <stdio.h>
#include <xil_io.h>
#include <xparameters.h>
#include "platform.h"
#include "console.h"
#include "aurora.h"
#ifdef SIMULATION
#include "simplatform.h"
#else
  #ifndef MARBLE
    #include "bmb7_udp.h"
  #endif
#endif  // SIMULATION
#include "epics.h"
#include "evr.h"
#include "eyescan.h"
#include "fastFeedback.h"
#include "fofbEthernet.h"
#include "frontPanel.h"
#include "gpio.h"
#include "pilotTones.h"
#include "qsfp.h"
#include "softwareBuildDate.h"
#include "util.h"
#include "xadc.h"

int udpEPICS;

#define MARBLE

void rx8chk(void) {
    static unsigned char buf[1600];
    int i, n;
    for (;;) {
        if ((n = udpRxCheck8(udpEPICS, buf, sizeof buf)) > 0) {
            printf("%4d:", n);
            for (i = 0 ; i < n ; i++ ) {
                int c = buf[i];
                if (isprint(c)) {
                    printf("%c", c);
                }
                else switch (c) {
                default:   printf("\\x%02x", c); break;
                case '\b': printf("\\b");        break;
                case '\n': printf("\\n");        break;
                case '\r': printf("\\r");        break;
                case '\t': printf("\\t");        break;
                case '\\': printf("\\\\");       break;
                }
            }
            printf("\n");
            udpTx8(udpEPICS, buf, n);
        }
    }
}

int main()
{
    uint32_t lastDiagnostic, lastPacket, now;
    int pass;

    /*
     * Announce our presence
     */
    init_platform();
    printf("\n");
    printf("Firmware build POSIX seconds: %d\n",
                                    GPIO_READ(GPIO_IDX_FIRMWARE_BUILD_DATE));
    printf("Software build POSIX seconds: %d\n", SOFTWARE_BUILD_DATE);

    /*
     * Continue with initialization
     */
    eyescanInit();
    qsfpInit();
    auroraInit();
    evrInit();
    evrShow();
    fofbEthernetInit();
    xadcInit();
    setPilotToneReference(328 * 2); // SROC/2 for now
    ptInit();
    udpEPICS = epicsInit(); // udpEPICS unused in marble build

    /*
     * Toss any junk present in UDP receive buffers
     */
    lastPacket = MICROSECONDS_SINCE_BOOT();
#ifndef MARBLE
    for (pass = 0 ; pass < 1000000 ; pass++) {
        if (udpRxCheck32(udpEPICS, NULL, 0) > 0) {
            lastPacket = MICROSECONDS_SINCE_BOOT();
        }
        else if ((MICROSECONDS_SINCE_BOOT() - lastPacket) > 5) {
            break;
        }
    }
#endif

    /*
     * Main processing loop
     */
    lastDiagnostic = MICROSECONDS_SINCE_BOOT();
    for (;;) {
        now = MICROSECONDS_SINCE_BOOT();
        if ((now - lastDiagnostic) >= 1000000) {
            lastDiagnostic = now;
            xadcUpdate();
        }
        epicsService();
        consoleCheck();
        ptCrank();
    }
    cleanup_platform();
    return 0;
}

