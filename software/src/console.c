/*
 * Simple command interperter
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <xparameters.h>
#include "aurora.h"
#include "cellControllerProtocol.h"
#include "eebi.h"
#include "evr.h"
#include "eyescan.h"
#include "fastFeedback.h"
#include "fofbEthernet.h"
#include "gpio.h"
#include "pilotTones.h"
#include "qsfp.h"
#include "util.h"

#ifdef SIMULATION
#include "simplatform.h"
#endif

#define UART_CSR_TX_FULL    0x80000000
#define UART_CSR_RX_READY   0x100

enum consoleMode { consoleModeCommand };
static enum consoleMode consoleMode;

/*
 * Hang on to start messages
 */
#define STARTBUF_SIZE   4000
static char startBuf[STARTBUF_SIZE];
static int startIdx = 0;
static int isStartup = 1;

/*
 * Console output uses our own UART transmitter
 */
void
outbyte(char c)
{
    if (c == '\n') outbyte('\r');
    while (GPIO_READ(GPIO_IDX_UART_CSR) & UART_CSR_TX_FULL) continue;
    GPIO_WRITE(GPIO_IDX_UART_CSR, c & 0xFF);
    if (isStartup && (startIdx < STARTBUF_SIZE))
        startBuf[startIdx++] = c;
}

static void
showFrequencyCounters(void)
{
    int i;
    static const char *names[] = { "System", "EVR recovered", "Aurora user",
                                   "Ethernet/EVR reference",
                                   "Aurora reference" };

    for (i = 0 ; i < sizeof names / sizeof names[0] ; i++) {
        GPIO_WRITE(GPIO_IDX_FREQUENCY_MONITOR_CSR, i);
        printf("%24s clock: %9d\n", names[i],
                                     GPIO_READ(GPIO_IDX_FREQUENCY_MONITOR_CSR));
    }
}

static int
cmdDEBUG(int argc, char **argv)
{
    char *endp;
    int d;

    if (argc > 1) {
        d = strtol(argv[1], &endp, 16);
        if (*endp == '\0') {
            debugFlags = d;
            if (d & DEBUGFLAG_QSFP_DUMP) qsfpDump();
        }
    }
    if (debugFlags & DEBUGFLAG_SHOW_FREQUENCY_COUNTERS) showFrequencyCounters();
    if (debugFlags & DEBUGFLAG_SHOW_PS_SETPOINTS) ffbShowPowerSupplySetpoints();
    if (debugFlags & DEBUGFLAG_BRINGUP_PS_LINKS) fofbEthernetBringUp();
    if (debugFlags & DEBUGFLAG_RESET_EEBI_INTERLOCK) {
        debugFlags &= ~DEBUGFLAG_RESET_EEBI_INTERLOCK;
        eebiResetInterlock();
    }
    printf("Debug flags: %x\n", debugFlags);
    return 0;
}

#ifndef MARBLE
static int
cmdAD9520(int argc, char **argv)
{
    ad9520show();
    return 0;
}
#endif

static int
cmdQSFP(int argc, char **argv)
{
    qsfpShowInfo();
    return 0;
}

static int
cmdBPMinhibit(int argc, char **argv)
{
    char *endp;
    static int inhibitFlags;

    if (argc > 1) {
        inhibitFlags = strtol(argv[1], &endp, 16);
        if (*endp == '\0') {
            bpmInhibit(inhibitFlags);
        }
    }
    switch (inhibitFlags & 0x3) {
    case 0: printf("Both BPM links enabled.\n");    break;
    case 1: printf("CCW BPM link inhibited.\n");    break;
    case 2: printf("CW BPM link inhibited.\n");     break;
    case 3: printf("Both BPM links inhibited.\n");  break;
    }
    return 0;
}

static int
cmdCellInhibit(int argc, char **argv)
{
    char *endp;
    static int inhibitFlags;

    if (argc > 1) {
        inhibitFlags = strtol(argv[1], &endp, 16);
        if (*endp == '\0') {
            cellInhibit(inhibitFlags);
        }
    }
    switch (inhibitFlags & 0x3) {
    case 0: printf("Both cell links enabled.\n");    break;
    case 1: printf("CCW cell link inhibited.\n");    break;
    case 2: printf("CW cell link inhibited.\n");     break;
    case 3: printf("Both cell links inhibited.\n");  break;
    }
    if (inhibitFlags & 0x4) printf("Use fake data.\n");
    return 0;
}

static int
cmdEVR(int argc, char **argv)
{
    evrTimestamp ts;
    evrShow();
    evrCurrentTime(&ts);
    printf("EVR seconds:ticks  %d:%09d\n", ts.secPastEpoch, ts.ticks);
    return 0;
}

static int
cmdFOFB(int argc, char **argv)
{
    char *endp;
    int first = 0;
    int n = 1;

    if (argc > 1) {
        first = strtol(argv[1], &endp, 0);
        if (*endp != '\0')
            return 1;
        if (argc > 2) {
            n = strtol(argv[2], &endp, 0);
            if (*endp != '\0')
                return 1;
        }
        if ((first < 0)
         || (first >= CC_PROTOCOL_FOFB_CAPACITY_PER_PLANE) || (n < 0))
            return 1;
        if ((first + n) > CC_PROTOCOL_FOFB_CAPACITY_PER_PLANE)
            n = CC_PROTOCOL_FOFB_CAPACITY_PER_PLANE - first;
    }
    showFOFB(first, n);
    return 0;
}

static int
cmdFOFBlink(int argc, char **argv)
{
    fofbEthernetShowStatus();
    return 0;
}


static int
cmdREG(int argc, char **argv)
{
    char *endp;
    int i;
    int first;
    int n = 1;

    if (argc > 1) {
        first = strtol(argv[1], &endp, 0);
        if (*endp != '\0')
            return 1;
        if (argc > 2) {
            n = strtol(argv[2], &endp, 0);
            if (*endp != '\0')
                return 1;
        }
        if ((first < 0) || (first >= GPIO_IDX_COUNT) || (n <= 0))
            return 1;
        if ((first + n) > GPIO_IDX_COUNT)
            n = GPIO_IDX_COUNT - first;
        for (i = first ; i < first + n ; i++) {
            showReg(i);
        }
    }
    return 0;
}

static int
cmdREPLAY(int argc, char **argv)
{
    int i;

    for (i = 0 ; i < startIdx ; i++) {
        unsigned char c = startBuf[i];
        while (GPIO_READ(GPIO_IDX_UART_CSR) & UART_CSR_TX_FULL) continue;
        GPIO_WRITE(GPIO_IDX_UART_CSR, c);
    }
    return 0;
}

static int
cmdSTATS(int argc, char **argv)
{
    auroraReadoutShowStats(1);
    if (argc > 1) {
        if (strcmp(argv[1], "0") == 0) auroraReadoutClearStats();
    }
    return 0;
}

#define CMD_TLOG_ARGC_CRANK 0
#define CMD_TLOG_ARGC_STOP  -1
#define CMD_TLOG_ARGC_START 1
static int
cmdTLOG(int argc, char **argv)
{
    uint32_t csr;
    int event;
    uint32_t ticks;
    static enum { s_idle, s_recording, s_header, s_printing } state = s_idle;
    int entryState = state;
    static unsigned int nOutOfSequenceSeconds;
    static unsigned int nTooFewSecondEvents;
    static unsigned int nTooManySecondEvents;
    static int rIdx, wIdx, addrMask;
    static uint32_t firstTicks, previousTicks, sec;
    static int bitCount;

    switch (state) {
    case s_idle:
        if (argc >= CMD_TLOG_ARGC_START) {
            GPIO_WRITE(GPIO_IDX_EVENT_LOG_CSR, 0x80000000);
            nOutOfSequenceSeconds = evrNoutOfSequenceSeconds();
            nTooFewSecondEvents = evrNtooFewSecondEvents();
            nTooManySecondEvents = evrNtooManySecondEvents();
            printf("--- Event logger started --- Press any key to terminate ---\n");
            state = s_recording;
        }
        break;
    case s_recording:
        if ((nOutOfSequenceSeconds != evrNoutOfSequenceSeconds())
         || (nTooFewSecondEvents != evrNtooFewSecondEvents())
         || (nTooManySecondEvents != evrNtooManySecondEvents())
         || (argc == CMD_TLOG_ARGC_STOP)) {
            GPIO_WRITE(GPIO_IDX_EVENT_LOG_CSR, 0);
            state = s_header;
        }
        break;
    case s_header:
        csr = GPIO_READ(GPIO_IDX_EVENT_LOG_CSR);
        addrMask = ~(~0UL << ((csr >> 24) & 0xF));
        wIdx = csr & addrMask;
        if (csr & 0x40000000) {  /* Write address has wrapped, buffer full */
            rIdx = wIdx;
        }
        else {
            rIdx = 0;
            if (wIdx == 0) {
                printf("\nNo events!\n");
                state = s_idle;
                break;
            }
        }
        GPIO_WRITE(GPIO_IDX_EVENT_LOG_CSR, rIdx);
        printf("\n Event    Delta Ticks          Ticks      Seconds\n");
        ticks = GPIO_READ(GPIO_IDX_EVENT_LOG_TICKS);
        firstTicks = ticks;
        previousTicks = ticks;
        bitCount = 0;
        state = s_printing;
        break;
    case s_printing:
        if (argc == CMD_TLOG_ARGC_STOP) {
            state = s_idle;
        }
        else {
            GPIO_WRITE(GPIO_IDX_EVENT_LOG_CSR, rIdx);
            microsecondSpin(1);
            csr = GPIO_READ(GPIO_IDX_EVENT_LOG_CSR);
            event = (csr >> 16) & 0xFF;
            ticks = GPIO_READ(GPIO_IDX_EVENT_LOG_TICKS);
            printf("%3d ", event);
            switch(event) {
            case 112: printf("  0 ");  sec=(sec<<1)|0; bitCount++ ; break;
            case 113: printf("  1 ");  sec=(sec<<1)|1; bitCount++ ; break;
            case 122: printf(" HB ");  break;
            case 125: printf("PPS ");  break;
            default:  printf("    ");  break;
            }
            uintPrint((uint32_t)(ticks - previousTicks));
            printf("  ");
            uintPrint((uint32_t)(ticks - firstTicks));
            if (event == 125) {
                if (bitCount == 32) {
                    printf("  %10u", (unsigned int)sec);
                }
                else {
                    printf("    <%d BIT%s>", bitCount, bitCount==1?"":"S");
                }
                bitCount = 0;
            }
            printf("\n");
            previousTicks = ticks;
            rIdx = (rIdx + 1) & addrMask;
            if (rIdx == wIdx) state = s_idle;
        }
        break;
    }
    return (entryState != s_idle);
}

static int
cmdWAURORA(int argc, char **argv)
{
    char *endp;
    unsigned int r;

    if (argc > 1) {
        r = strtol(argv[1], &endp, 16);
        if (*endp == '\0') {
            auroraWriteCSR(r);
            microsecondSpin(10);
        }
    }
    auroraReadoutShowStats(0);
    return 0;
}

struct commandInfo {
    const char *name;
    int       (*handler)(int argc, char **argv);
    const char *description;
};

#ifdef MARBLE
static struct commandInfo commandTable[] = {
//  { "ad9520",     cmdAD9520,     "Show AD9520 registers"              },
  { "qsfp",       cmdQSFP,      "Show QSFP status"                    },
  { "bpmInhibit", cmdBPMinhibit,"Inhibit BPM link(s)"                 },
  { "cellInhibit",cmdCellInhibit,"Inhibit cell controller link(s)"    },
  { "debug",      cmdDEBUG,      "Set debug flags"                    },
  { "evr",        cmdEVR,        "Show EVR status"                    },
  { "fofb",       cmdFOFB,       "Show fast orbit feedback values"    },
  { "gtx",        eyescanCommand,"Perform GTX eye scan"               },
  { "log",        cmdREPLAY,     "Replay start up messages"           },
  { "pslink",     cmdFOFBlink,   "Show power supply ethernet status"  },
  { "reg",        cmdREG,        "Show GPIO register(s)"              },
  { "stats",      cmdSTATS,      "Show Aurora link statistics"        },
  { "tlog",       cmdTLOG,       "Start timing system event logger"   },
  { "wAurora",    cmdWAURORA,    "Write Aurora CSR"                   },
};
#else
static struct commandInfo commandTable[] = {
  { "ad9520",     cmdAD9520,     "Show AD9520 registers"              },
  { "qsfp",       cmdQSFP,      "Show QSFP status"                    },
  { "bpmInhibit", cmdBPMinhibit,"Inhibit BPM link(s)"                 },
  { "cellInhibit",cmdCellInhibit,"Inhibit cell controller link(s)"    },
  { "debug",      cmdDEBUG,      "Set debug flags"                    },
  { "evr",        cmdEVR,        "Show EVR status"                    },
  { "fofb",       cmdFOFB,       "Show fast orbit feedback values"    },
  { "gtx",        eyescanCommand,"Perform GTX eye scan"               },
  { "log",        cmdREPLAY,     "Replay start up messages"           },
  { "pslink",     cmdFOFBlink,   "Show power supply ethernet status"  },
  { "reg",        cmdREG,        "Show GPIO register(s)"              },
  { "stats",      cmdSTATS,      "Show Aurora link statistics"        },
  { "tlog",       cmdTLOG,       "Start timing system event logger"   },
  { "wAurora",    cmdWAURORA,    "Write Aurora CSR"                   },
};
#endif

static void
commandCallback(int argc, char **argv)
{
    int i;
    int len;
    int matched = -1;

    if (argc <= 0)
        return;
    len = strlen(argv[0]);
    for (i = 0 ; i < sizeof commandTable / sizeof commandTable[0] ; i++) {
        if (strncasecmp(argv[0], commandTable[i].name, len) == 0) {
            if (matched >= 0) {
                printf("Not unique.\n");
                return;
            }
            matched = i;
        }
    }
    if (matched >= 0) {
        (*commandTable[matched].handler)(argc, argv);
        return;
    }
    if ((strncasecmp(argv[0], "help", len) == 0) || (argv[0][0] == '?')) {
        printf("Commands:\n");
        for (i = 0 ; i < sizeof commandTable / sizeof commandTable[0] ; i++) {
            printf("%11s -- %s\n", commandTable[i].name,
                                   commandTable[i].description);
        }
    }
    else {
        printf("Invalid command\n");
    }
}

static void
handleLine(char *line)
{
    char *argv[10];
    int argc;
    char *tokArg, *tokSave;

    // DEBUG
    xil_printf("Handle line\r\n");
    argc = 0;
    tokArg = line;
    while ((argc < (sizeof argv / sizeof argv[0]) - 1)) {
        char *cp = strtok_r(tokArg, " ,", &tokSave);
        if (cp == NULL)
            break;
        argv[argc++] = cp;
        tokArg = NULL;
    }
    argv[argc] = NULL;
    switch (consoleMode) {
    case consoleModeCommand:   commandCallback(argc, argv);           break;
    }
}

/*
 * Check for and act upon character from console
 * Uses our own UART receiver
 */
void
consoleCheck(void)
{
    int c;
    static char line[200];
    static int idx = 0;
#ifdef SIMULATION
    simService();
#endif

    if (eyescanCrank()) return;
    c = GPIO_READ(GPIO_IDX_UART_CSR);
    if ((c & UART_CSR_RX_READY) == 0) {
        cmdTLOG(CMD_TLOG_ARGC_CRANK, NULL);
        return;
    }
    GPIO_WRITE(GPIO_IDX_UART_CSR, UART_CSR_RX_READY);
    if (cmdTLOG(CMD_TLOG_ARGC_STOP, NULL)) return;
    c &= 0xFF;
    if (c > '\177') return;
    if (c == '\t') c = ' ';
    else if (c == '\177') c = '\b';
    else if (c == '\r') c = '\n';
    if (c == '\n') {
        outbyte('\n');
        isStartup = 0;
        line[idx] = '\0';
        idx = 0;
        handleLine(line);
        return;
    }
    if (c == '\b') {
        if (idx) {
            outbyte('\b');
            outbyte(' ');
            outbyte('\b');
            idx--;
        }
        return;
    }
    if (c < ' ')
        return;
    if (idx < ((sizeof line) - 1)) {
        outbyte(c);
        line[idx++] = c;
    }
}
