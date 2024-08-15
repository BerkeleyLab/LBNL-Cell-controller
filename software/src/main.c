#include <stdio.h>
#include <xil_io.h>
#include <xparameters.h>
#include "platform.h"
#include "console.h"
#include "aurora.h"
#ifdef SIMULATION
#include "simplatform.h"
#else
  #include "bwudp.h"
#endif  // SIMULATION
#include "epics.h"
#include "evr.h"
#include "eyescan.h"
#include "fastFeedback.h"
#include "fofbEthernet.h"
#include "gpio.h"
#include "util.h"
#include "iicChunk.h"
#include "iicProc.h"
#include "mgtClkSwitch.h"
#include "xadc.h"
#include "systemParameters.h"
#include "tftp.h"
#include "mmcMailbox.h"
#include "bootFlash.h"
#include "mgt.h"

int main()
{
    uint32_t lastDiagnostic, now;

    /*
     * Announce our presence
     */
    init_platform();
    printf("\n");
    printf("Git ID (32-bit): 0x%08x\n", GPIO_READ(GPIO_IDX_GITHASH));

    /*
     * Initialize IIC chunk and give it time to complete a scan
     */
    iicChunkInit();
    microsecondSpin(500000);
    iicProcInit();

    /*
     * Initialize mailbox
     */
    if(!mmcMailboxInit()) {
        fatal("MMC mailbox not working");
    }

    /*
     * Boot, default configuration
     */
    bootFlashInit();
    systemParametersInit();
    showNetworkConfig(&systemParameters.netConfig.np);
    epicsInit();

    /*
     * Continue with initialization
     */
    tftpInit();
    mgtClkSwitchInit();
    eyescanInit();
    mgtInit();
    auroraInit();
    evrInit();
    evrShow();
    fofbEthernetInit();
    xadcInit();

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
        mgtCrankRxAligner();
        epicsService();
        consoleCheck();
    }
    cleanup_platform();
    return 0;
}

