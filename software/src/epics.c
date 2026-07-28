/*
 * New marble version using bwudp and badger;
 * Accept and act upon commands from IOC
 */

#include <stdio.h>
#include <string.h>
#include "aurora.h"
#include "cellControllerProtocol.h"
#include "epics.h"
#include "evr.h"
#include "fastFeedback.h"
#include "fastMPS.h"
#include "fofbEthernet.h"
#include "gpio.h"
#include "psAWG.h"
#include "psWaveformRecorder.h"
#include "util.h"
#include "xadc.h"
#include "iicChunk.h"
#include "mmcMailbox.h"

#include "bwudp.h"
#include "systemParameters.h"

#define BPM_COUNT_MASK 0x3F

/*
 * Handle a reboot request
 */
static void
crankRebootStateMachine(int value)
{
    static uint16_t match[] = { 1, 100, 10000 };
    static int i;

    if (value == match[i]) {
        i++;
        if (i == (sizeof match / sizeof match[0])) {
            resetFPGA(0);
        }
    }
    else {
        i = 0;
    }
}

/*
 * Read fan tachometers
 * Works for even or odd number of fans
 */
static int
fetchFanSpeeds(uint32_t *ap)
{
    int i, shift = 0, count = 0;
    uint32_t v = 0;
    for (i = 0 ; i < CFG_FAN_COUNT ; i++) {
        if (shift > 16) {
            *ap++ = v;
            count++;
            shift = 0;
        }
        GPIO_WRITE(GPIO_IDX_FAN_TACHOMETERS, i);
        v |= (GPIO_READ(GPIO_IDX_FAN_TACHOMETERS) & 0xFFFF) << shift;
        shift += 16;
    }
    *ap = v;
    return count + 1;
}

/*
 * Fetch system monitors
 */
static int
sysmonFetch(uint32_t *args)
{
    uint32_t *ap = args;
    ap = xadcUpdate(ap);
    ap = iicChunkReadback(ap);
    ap = mmcMailboxFetchSysmon(ap);
    /*
     * Get recovered clock frequency.
     * Channel order set by frequencyCounters instantiation in common_cctrl_top.v
     */
    GPIO_WRITE(GPIO_IDX_FREQUENCY_MONITOR_CSR, 2);
    *ap++ = GPIO_READ(GPIO_IDX_FREQUENCY_MONITOR_CSR) & 0x3FFFFFFF;
    GPIO_WRITE(GPIO_IDX_FREQUENCY_MONITOR_CSR, 3);
    *ap++ = GPIO_READ(GPIO_IDX_FREQUENCY_MONITOR_CSR) & 0x3FFFFFFF;
    GPIO_WRITE(GPIO_IDX_FREQUENCY_MONITOR_CSR, 4);
    *ap++ = GPIO_READ(GPIO_IDX_FREQUENCY_MONITOR_CSR) & 0x3FFFFFFF;
    GPIO_WRITE(GPIO_IDX_FREQUENCY_MONITOR_CSR, 6);
    *ap++ = GPIO_READ(GPIO_IDX_FREQUENCY_MONITOR_CSR) & 0x3FFFFFFF;
    ap += fetchFanSpeeds(ap);
    *ap++ = (GPIO_READ(GPIO_IDX_EVENT_STATUS) << 16);
    *ap++ = (evrNtooManySecondEvents() << 16) |
                            evrNtooFewSecondEvents();
    *ap++ = evrNoutOfSequenceSeconds();
    *ap++ = GPIO_READ(GPIO_IDX_AWG_CSR);
    *ap++ = GPIO_READ(GPIO_IDX_WFR_CSR);
    *ap++ = fofbEthernetGetPCSPMAstatus();
    return ap - args;
}

/*
 * Return or clear Aurora link statistics
 */
static int
auroraStats(uint32_t *args, int clearStats)
{
    uint32_t *ap = args;
    int link;
    int i;

    if (clearStats) {
        auroraReadoutClearStats();
    }
    else {
        unsigned int hi, lo;
        for (link = 0 ; link < AURORA_LINK_COUNT ; link++) {
            *ap++ = auroraReadoutIsUp(link);
            *ap++ = auroraReadoutCount(link);
            for (i = 0 ; i < AURORA_LINK_READOUT_COUNT ; i++) {
                auroraReadoutStats(link, i, &hi, &lo);
                *ap++ = lo;
                *ap++ = hi;
            }
        }
        auroraReadoutStats(AUSTATS_TIMEOUT_COUNTER_LINK,
                           AUSTATS_TIMEOUT_COUNTER_IDX, &hi, &lo);
        *ap++ = lo;
        *ap++ = hi;
        *ap++ = GPIO_READ(GPIO_IDX_BPMLINKS_EXTRA_STATUS) & BPM_COUNT_MASK;
        *ap++ = GPIO_READ(GPIO_IDX_BPM_RX_BITMAP);
        *ap++ = GPIO_READ(GPIO_IDX_CELL_RX_BITMAP);
        *ap++ = ffbReadoutTime();
        *ap++ = ffbCellIndex();
        *ap++ = ffbCellCount();
        *ap++ = ffbCellBPMcount();
        *ap++ = ffbReadoutIsValid();
        *ap++ = GPIO_READ(GPIO_IDX_FOFB_CSR);
        *ap++ = GPIO_READ(GPIO_IDX_FOFB_ENABLE_BITMAP);
    }
    return ap - args;
}

static void
dspUpdate(int cmdCode, int idx, uint32_t value)
{
    GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (CFG_DSP_CMD_LATCH_ADDRESS << CFG_DSP_CMD_SHIFT) |
                            (idx << 10));
    GPIO_WRITE(GPIO_IDX_DSP_CSR,
                         (CFG_DSP_CMD_LATCH_HIGH_VALUE << CFG_DSP_CMD_SHIFT) |
                         ((value >> 16) & 0xFFFF));
    GPIO_WRITE(GPIO_IDX_DSP_CSR, (cmdCode << CFG_DSP_CMD_SHIFT) |
                                 (value & 0xFFFF));
}

static void
dspUpdateAll(int cmdCode, int argc, uint32_t *args)
{
    int i;
    if (argc > CC_PROTOCOL_FOFB_CORRECTOR_CAPACITY) {
        argc = CC_PROTOCOL_FOFB_CORRECTOR_CAPACITY;
    }
    for (i = 0 ; i < argc ; i++) {
        dspUpdate(cmdCode, i, args[i]);
    }
}

/*
 * Process command
 */
static int
handleCommand(int commandArgCount, struct ccProtocolPacket *cmdp,
                                   struct ccProtocolPacket *replyp)
{
    int replyArgCount = 0;
    unsigned int hi  = cmdp->command & CC_PROTOCOL_CMD_MASK_HI;
    unsigned int lo  = cmdp->command & CC_PROTOCOL_CMD_MASK_LO;
    unsigned int idx = cmdp->command & CC_PROTOCOL_CMD_MASK_IDX;
    static int powerUpStatus = 1;

    switch (hi) {
    case CC_PROTOCOL_CMD_HI_FOFB_GAIN:
            dspUpdateAll(CFG_DSP_CMD_WRITE_FOFB_GAIN, commandArgCount, cmdp->args);
            break;

    case CC_PROTOCOL_CMD_HI_CLIP_LIMIT:
        switch(lo) {
        case CC_PROTOCOL_CMD_LO_CLIP_LIMIT_PS:
            dspUpdateAll(CFG_DSP_CMD_WRITE_PS_CLIP_LIMIT, commandArgCount, cmdp->args);
            break;

        case CC_PROTOCOL_CMD_LO_CLIP_LIMIT_FFB:
            dspUpdateAll(CFG_DSP_CMD_WRITE_FFB_CLIP_LIMIT, commandArgCount, cmdp->args);
            break;

        default: return -1;
        }
        break;

    case CC_PROTOCOL_CMD_HI_PS_OFFSET:
            dspUpdateAll(CFG_DSP_CMD_WRITE_PS_OFFSET, commandArgCount, cmdp->args);
            break;

    case CC_PROTOCOL_CMD_HI_FOFB_FIR: {
        int i;
        int row = cmdp->command & ~CC_PROTOCOL_CMD_MASK_HI;
        int col = cmdp->args[0] & 0x3FF;
        static int activeRow = -1;
        /* Check for partial fill */
        if ((activeRow >= 0) && (row != activeRow)) {
            warn("FIR %d incompletely configured", activeRow);
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (CFG_DSP_CMD_LATCH_ADDRESS << CFG_DSP_CMD_SHIFT) |
                            (activeRow << (CFG_FOFB_MATRIX_ADDR_WIDTH+1)) |
                            (1 << CFG_FOFB_MATRIX_ADDR_WIDTH));
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                           (CFG_DSP_CMD_LATCH_HIGH_VALUE<<CFG_DSP_CMD_SHIFT));
        }
        activeRow = row;
        /* Ensure that previous update has completed */
        while (GPIO_READ(GPIO_IDX_DSP_CSR) & 0x3) continue;
        GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (CFG_DSP_CMD_LATCH_ADDRESS<<CFG_DSP_CMD_SHIFT) |
                            (row << (CFG_FOFB_MATRIX_ADDR_WIDTH+1)) | 0);
        for (i = 1 ; i < commandArgCount ; i++, col++) {
            uint32_t value = cmdp->args[i];
            if (col == CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE) {
                printf("Too many FIR coefficients\n");
                break;
            }
            if (col == (CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE - 1)) {
                /* Assert reload TLAST (address 'plane select' bit) */
                GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (CFG_DSP_CMD_LATCH_ADDRESS << CFG_DSP_CMD_SHIFT) |
                            (row << (CFG_FOFB_MATRIX_ADDR_WIDTH+1)) |
                            (1 << CFG_FOFB_MATRIX_ADDR_WIDTH));
            }
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                           (CFG_DSP_CMD_LATCH_HIGH_VALUE<<CFG_DSP_CMD_SHIFT) |
                           ((value >> 16) & 0xFFFF));
            /* Ensure that previous update has completed */
            while (GPIO_READ(GPIO_IDX_DSP_CSR) & 0x1) continue;
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (CFG_DSP_CMD_FIR_RELOAD<<CFG_DSP_CMD_SHIFT) |
                            (value & 0xFFFF));
            if (col == (CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE - 1)) {
                uint32_t csr;
                /* Ensure that previous update has completed */
                while (GPIO_READ(GPIO_IDX_DSP_CSR) & 0x2) continue;
                GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (CFG_DSP_CMD_FIR_CONFIG<<CFG_DSP_CMD_SHIFT));
                activeRow = -1;
                csr = GPIO_READ(GPIO_IDX_DSP_CSR);
                if (csr & 0xC) {
                    const char *cp;
                    switch( csr & 0xC) {
                    case 0x8:   cp = "Unexpected";  break;
                    case 0x4:   cp = "Missing";     break;
                    default:    cp = "Invalid";     break;
                    }
                    printf("FIR %d TLAST %s\n", row, cp);
                }
            }
        }
        }
        break;

    case CC_PROTOCOL_CMD_HI_FOFB_ROW: {
        int i;
        int row = cmdp->command & ~CC_PROTOCOL_CMD_MASK_HI;
        int col = cmdp->args[0] & 0x3FF;

        for (i = 1 ; i < commandArgCount ; i++, col++) {
            uint32_t value = cmdp->args[i];
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                        (CFG_DSP_CMD_LATCH_ADDRESS<<CFG_DSP_CMD_SHIFT) |
                        (row << 10) | col);
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                        (CFG_DSP_CMD_LATCH_HIGH_VALUE<<CFG_DSP_CMD_SHIFT) |
                        ((value >> 16) & 0xFFFF));
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                        (CFG_DSP_CMD_WRITE_MATRIX_ELEMENT<<CFG_DSP_CMD_SHIFT) |
                        (value & 0xFFFF));
        }
        }
        break;

    case CC_PROTOCOL_CMD_HI_LONGIN:
        if (commandArgCount != 0) {
            return -1;
        }
        replyArgCount = 1;

        switch (idx) {
        case CC_PROTOCOL_CMD_LONGIN_IDX_GIT_HASH_ID:
            replyp->args[0] = GPIO_READ(GPIO_IDX_GITHASH);
            break;

        default: return -1;
        }
        break;

    case CC_PROTOCOL_CMD_HI_LONGOUT:
        switch(lo) {
        case CC_PROTOCOL_CMD_LONGOUT_LO_GENERIC:
            switch (idx) {
            case CC_PROTOCOL_CMD_LONGOUT_IDX_FORCE_GTX_RESET:
                auroraResetGTX();
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_ENABLE_FAST_FEEDBACK:
                GPIO_WRITE(GPIO_IDX_FOFB_CSR, cmdp->args[0] != 0);
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_PS_BITMAP:
                psRecorderSetChannelMask(cmdp->args[0]);
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_PRETRIG_COUNT:
                psRecorderSetPretriggerCount(cmdp->args[0]);
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_POSTTRIG_COUNT:
                psRecorderSetPosttriggerCount(cmdp->args[0]);
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SET_PS_TRIG_EVENT:
                psRecorderSetTriggerEvent(cmdp->args[0]);
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_ARM:
                psRecorderArm(cmdp->args[0]);
                break;

            case CC_PROTOCOL_CMD_LONGOUT_IDX_WFR_SOFT_TRIGGER:
                psRecorderSoftTrigger();
                break;

            default: return -1;
            }
            break;

        case CC_PROTOCOL_CMD_LONGOUT_LO_FOFB_RB_MODE:
            fofbEthernetSetReadback(idx, cmdp->args[0]);
            break;


        case CC_PROTOCOL_CMD_LONGOUT_LO_PS_OFFSET:
            dspUpdate(CFG_DSP_CMD_WRITE_PS_OFFSET, idx, cmdp->args[0]);
            break;

        case CC_PROTOCOL_CMD_LONGOUT_LO_AWG:
            psAWGcommand(idx, cmdp->args[0]);
            break;

        case CC_PROTOCOL_CMD_LONGOUT_LO_NO_VALUE:
            switch (idx) {
            case CC_PROTOCOL_CMD_LONGOUT_NV_IDX_CLEAR_POWERUP_STATUS:
                powerUpStatus = 0;
                break;

            default: return -1;
            }
            break;
        }
        break;

    case CC_PROTOCOL_CMD_HI_SYSMON:
        if (commandArgCount != 0) return -1;
        replyp->args[0] = powerUpStatus;
        replyArgCount = sysmonFetch(replyp->args + 1) + 1;
        break;

    case CC_PROTOCOL_CMD_HI_LINKSTATS:
        replyp->args[0] = powerUpStatus;
        replyArgCount = auroraStats(replyp->args + 1, commandArgCount != 0) + 1;
        break;

    case CC_PROTOCOL_CMD_HI_I32ARRAY_OUT:
        switch (lo) {
        case CC_PROTOCOL_CMD_LO_I32A_BPM_SETPOINTS:
            ffbStashSetpoints(commandArgCount, cmdp->args, cmdp->cellInfo);
            // FIXME: FMPS should not be configured as part of the
            // BPM setpoint configuration
            fmpsConfig(cmdp->cellInfo);
            break;
        default: return -1;
        }
        break;

    case CC_PROTOCOL_CMD_HI_F32ARRAY_OUT:
        switch (lo) {
        case CC_PROTOCOL_CMD_LO_F32A_AWG_PATTERN:
            psAWGstashSamples(&cmdp->args[1], cmdp->args[0], commandArgCount - 1);
            break;

        default: return -1;
        }
        break;

    case CC_PROTOCOL_CMD_HI_WAVEFORM:
        replyArgCount = psRecorderFetch(replyp->args, CC_PROTOCOL_ARG_CAPACITY,
                                                            idx, cmdp->args[0]);
        break;

    default: return -1;
    }

    return replyArgCount;
}

/*
 * Handle commands from IOC
 */
static void
epicsHandler(bwudpHandle replyHandle, char *payload, int length)
{
    struct ccProtocolPacket *cmdp = (struct ccProtocolPacket *)payload;
    int mustSwap = 0;
    int commandArgCount;
    static struct ccProtocolPacket reply;
    static int replySize;
    static uint32_t lastnonce;

    /*
     * Ignore weird-sized packets
     */
    if ((length < CC_PROTOCOL_ARG_COUNT_TO_SIZE(0))
     || (length > sizeof(struct ccProtocolPacket))
     || ((length % sizeof(uint32_t)) != 0)) {
        if (debugFlags & DEBUGFLAG_EPICS) {
            printf("Unreasonable packet size\n");
        }
        return;
    }
    commandArgCount = CC_PROTOCOL_SIZE_TO_ARG_COUNT(length);

    if (cmdp->magic == CC_PROTOCOL_MAGIC_SWAPPED) {
        mustSwap = 1;
        bswap32(&cmdp->magic, length / sizeof(int32_t));
    }
    if (cmdp->magic == CC_PROTOCOL_MAGIC) {
        if (debugFlags & DEBUGFLAG_EPICS) {
            printf("Command:%X nonce:%X args:%d 0x%x\n",
                         (unsigned int)cmdp->command, (unsigned int)cmdp->nonce,
                         commandArgCount, (unsigned int)cmdp->args[0]);
        }
        if (cmdp->nonce != lastnonce) {
            int n;
            memcpy(&reply, cmdp, CC_PROTOCOL_ARG_COUNT_TO_SIZE(0));
            if ((n = handleCommand(commandArgCount, cmdp, &reply)) < 0) {
                return;
            }
            lastnonce = cmdp->nonce;
            replySize = CC_PROTOCOL_ARG_COUNT_TO_SIZE(n);
            if (mustSwap) {
                bswap32(&reply.magic, replySize / sizeof(int32_t));
            }
        }
        if (debugFlags & DEBUGFLAG_EPICS) {
            printf("Reply:%d\n", replySize);
        }
        bwudpSend(replyHandle, (const char *)&reply, replySize);
    }
    else {
        if (debugFlags & DEBUGFLAG_EPICS) {
            printf("Bad magic number 0x%08X\n", cmdp->magic);
        }
    }
}

void epicsInit(void) {
    bwudpRegisterServer(htons(CC_PROTOCOL_UDP_PORT), epicsHandler);
}
