#include <math.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <xil_io.h>
#include <xparameters.h>
#include "console.h"
#include "gpio.h"
#include "util.h"

int debugFlags;

/*
 * Employ some gross hacks to avoid using vprintf (and thereby
 * bloating the text size by about 60 kB).
 */
void
fatal(const char *fmt, ...)
{
    va_list args;
    unsigned int now, then = MICROSECONDS_SINCE_BOOT();
    unsigned int limit = 0;
    static int enterCount = 0;
    unsigned int a[4];

    enterCount++;
    for (;;) {
        if (((now = MICROSECONDS_SINCE_BOOT()) - then) >= limit) {
            printf("*** Fatal error:  ");
            va_start(args, fmt);
            a[0] = va_arg(args, unsigned int);
            a[1] = va_arg(args, unsigned int);
            a[2] = va_arg(args, unsigned int);
            a[3] = va_arg(args, unsigned int);
            printf(fmt, a[0], a[1], a[2], a[3]);
            va_end(args);
            printf("\n");
            then = now;
            limit = 10000000;
        }
        if (enterCount == 1) consoleCheck();
    }
}

void
warn(const char *fmt, ...)
{
    va_list args;
    unsigned int a[4];

    printf("*** Warning: ");
    va_start(args, fmt);
    a[0] = va_arg(args, unsigned int);
    a[1] = va_arg(args, unsigned int);
    a[2] = va_arg(args, unsigned int);
    a[3] = va_arg(args, unsigned int);
    printf(fmt, a[0], a[1], a[2], a[3]);
    va_end(args);
    printf("\n");
}

void
microsecondSpin(unsigned int us)
{
    unsigned int now, then = MICROSECONDS_SINCE_BOOT();
    while (((now = MICROSECONDS_SINCE_BOOT()) - then) < us) continue;
}

/*
 * Pretty-print an unsigned integer value
 */
void
uintPrint(unsigned int n)
{
    int i;
    int t[4];
    for (i = 0 ; i < 4 ; i++) {
        t[i] = n % 1000;
        n /= 1000;
    }
    if (t[3])      printf("%d,%03d,%03d,%03d", t[3], t[2], t[1], t[0]) ;
    else if (t[2]) printf("%5d,%03d,%03d", t[2], t[1], t[0]) ;
    else if (t[1]) printf("%9d,%03d", t[1], t[0]) ;
    else           printf("%13d", t[0]) ;
}

/*
 * Show register contents
 */
void
showReg(int i)
{
    int r;

    i &= 0x3F;
    r = GPIO_READ(i);
    printf("  R%d = %04X:%04X %11d\n", i, (r>>16)&0xFFFF, r&0xFFFF, r);
}

/*
 * Write to the ICAP instance to force a warm reboot
 * Command sequence from UG470
 */
static void
writeICAP(int value)
{
    Xil_Out32(XPAR_HWICAP_0_BASEADDR+0x100, value); /* Write FIFO */
}

void
resetFPGA(int bootAlternateImage)
{
    printf("====== FPGA REBOOT ======\n\n");
    microsecondSpin(50000);
    writeICAP(0xFFFFFFFF); /* Dummy word */
    writeICAP(0xAA995566); /* Sync word */
    writeICAP(0x20000000); /* Type 1 NO-OP */
    writeICAP(0x30020001); /* Type 1 write 1 to Warm Boot STart Address Reg */
    writeICAP(bootAlternateImage ? MiB(FLASH_BITSTREAM_B_OFFSET)
                                 : MiB(FLASH_BITSTREAM_A_OFFSET)); /* Warm boot start addr */
    writeICAP(0x20000000); /* Type 1 NO-OP */
    writeICAP(0x30008001); /* Type 1 write 1 to CMD */
    writeICAP(0x0000000F); /* IPROG command */
    writeICAP(0x20000000); /* Type 1 NO-OP */
    Xil_Out32(XPAR_HWICAP_0_BASEADDR+0x10C, 0x1);   /* Initiate WRITE */
    microsecondSpin(1000000);
    printf("====== FPGA REBOOT FAILED ======\n");
}

void
printDebugFlags()
{
    struct debugFlagsTable {
        const char *name;
        uint32_t   flagValue;
    };
    static struct debugFlagsTable debugTable[] = {
        {"DEBUGFLAG_EPICS",                   DEBUGFLAG_EPICS},
        {"DEBUGFLAG_AWG",                      DEBUGFLAG_AWG},
        {"DEBUGFLAG_PS_WAVEFORM_RECORDER",    DEBUGFLAG_PS_WAVEFORM_RECORDER},
        {"DEBUGFLAG_SETPOINTS",               DEBUGFLAG_SETPOINTS},
        {"DEBUGFLAG_EEBI_CONFIG",             DEBUGFLAG_EEBI_CONFIG},
        {"DEBUGFLAG_TFTP",                    DEBUGFLAG_TFTP},
        {"DEBUGFLAG_IIC_PROC",                DEBUGFLAG_IIC_PROC},
        {"DEBUGFLAG_SHOW_FREQUENCY_COUNTERS", DEBUGFLAG_SHOW_FREQUENCY_COUNTERS},
        {"DEBUGFLAG_SHOW_PS_SETPOINTS",       DEBUGFLAG_SHOW_PS_SETPOINTS},
        {"DEBUGFLAG_BRINGUP_PS_LINKS",        DEBUGFLAG_BRINGUP_PS_LINKS},
        {"DEBUGFLAG_IIC_SCAN",                DEBUGFLAG_IIC_SCAN},
        {"DEBUGFLAG_SHOW_MGT_RESETS",         DEBUGFLAG_SHOW_MGT_RESETS},
        {"DEBUGFLAG_SHOW_RX_ALIGNER",         DEBUGFLAG_SHOW_RX_ALIGNER},
        {"DEBUGFLAG_SI570_SETTING",           DEBUGFLAG_SI570_SETTING},
        {"DEBUGFLAG_SHOW_MGT_SWITCH",         DEBUGFLAG_SHOW_MGT_SWITCH},
        {"DEBUGFLAG_DUMP_MGT_SWITCH",         DEBUGFLAG_DUMP_MGT_SWITCH}
    };
    printf("Debug flags available:\n");
    for (uint8_t i = 0 ; i < sizeof debugTable / sizeof debugTable[0] ; i++) {
        printf("%30s -- 0x%8x\n", debugTable[i].name, debugTable[i].flagValue);
    }
    return;
}
