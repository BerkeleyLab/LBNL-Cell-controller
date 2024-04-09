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
#include "softwareBuildDate.h"
#include "util.h"
#include "iicChunk.h"
#include "iicProc.h"
#include "mgtClkSwitch.h"
#include "xadc.h"

int udpEPICS;

int main()
{
    uint32_t lastDiagnostic, lastPacket, now;

    /*
     * Announce our presence
     */
    init_platform();
    printf("\n");
#ifdef MARBLE
    printf("Git ID (32-bit): 0x%08x\n", GPIO_READ(GPIO_IDX_GITHASH));
#else
    printf("Firmware build POSIX seconds: %d\n",
                                    GPIO_READ(GPIO_IDX_FIRMWARE_BUILD_DATE));
    printf("Software build POSIX seconds: %d\n", SOFTWARE_BUILD_DATE);
#endif

    /*
     * Initialize IIC chunk and give it time to complete a scan
     */
    iicChunkInit();
    microsecondSpin(500000);
    iicProcInit();

    /*
     * Continue with initialization
     */
    bootFlashInit();
    mmcMailboxInit();
    mgtClkSwitchInit();
    eyescanInit();
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
    int pass;
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

