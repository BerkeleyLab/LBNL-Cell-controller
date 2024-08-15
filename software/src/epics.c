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
#include "fofbEthernet.h"
#include "gpio.h"
#include "psAWG.h"
#include "psWaveformRecorder.h"
#include "qsfp.h"
#include "util.h"
#include "xadc.h"

#include "bwudp.h"
#include "systemParameters.h"

#define BPM_COUNT_MASK 0x3F

/*
 * Return system monitors
 */
static int
sysmonFetch(uint32_t *args)
{
    uint32_t *ap = args;
    int i;

    xadcUpdate();
    for (i = 0 ; i < XADC_CHANNEL_COUNT ; ) {
        uint32_t v = xadcVal[i++];
        if (i < XADC_CHANNEL_COUNT) v |= xadcVal[i++] << 16;
        *ap++ = v;
    }
    for (i = 0 ; i < QSFP_COUNT ; i++) {
        int r;
        *ap++ = (qsfpTemperature(i)<<16) | qsfpVoltage(i);
        for (r = 0 ; r < QSFP_RX_COUNT ; ) {
            uint32_t v = qsfpRxPower(i, r++);
            v |= qsfpRxPower(i, r++) << 16;
            *ap++ = v;
        }
    }
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
                            (GPIO_DSP_CMD_LATCH_ADDRESS << GPIO_DSP_CMD_SHIFT) |
                            (idx << 10));
    GPIO_WRITE(GPIO_IDX_DSP_CSR,
                         (GPIO_DSP_CMD_LATCH_HIGH_VALUE << GPIO_DSP_CMD_SHIFT) |
                         ((value >> 16) & 0xFFFF));
    GPIO_WRITE(GPIO_IDX_DSP_CSR, (cmdCode << GPIO_DSP_CMD_SHIFT) |
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
    int hi  = cmdp->command & CC_PROTOCOL_CMD_MASK_HI;
    int lo  = cmdp->command & CC_PROTOCOL_CMD_MASK_LO;
    int idx = cmdp->command & CC_PROTOCOL_CMD_MASK_IDX;

    switch (hi) {
    case CC_PROTOCOL_CMD_HI_FOFB_GAIN:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_FOFB_GAIN, commandArgCount, cmdp->args);
            break;

    case CC_PROTOCOL_CMD_HI_CLIP_LIMIT:
        switch(lo) {
        case CC_PROTOCOL_CMD_LO_CLIP_LIMIT_PS:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_PS_CLIP_LIMIT, commandArgCount, cmdp->args);
            break;

        case CC_PROTOCOL_CMD_LO_CLIP_LIMIT_FFB:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_FFB_CLIP_LIMIT, commandArgCount, cmdp->args);
            break;

        default: return -1;
        }
        break;

    case CC_PROTOCOL_CMD_HI_PS_OFFSET:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_PS_OFFSET, commandArgCount, cmdp->args);
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
                            (GPIO_DSP_CMD_LATCH_ADDRESS << GPIO_DSP_CMD_SHIFT) |
                            (activeRow << (GPIO_FOFB_MATRIX_ADDR_WIDTH+1)) |
                            (1 << GPIO_FOFB_MATRIX_ADDR_WIDTH));
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                           (GPIO_DSP_CMD_LATCH_HIGH_VALUE<<GPIO_DSP_CMD_SHIFT));
        }
        activeRow = row;
        /* Ensure that previous update has completed */
        while (GPIO_READ(GPIO_IDX_DSP_CSR) & 0x3) continue;
        GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (GPIO_DSP_CMD_LATCH_ADDRESS<<GPIO_DSP_CMD_SHIFT) |
                            (row << (GPIO_FOFB_MATRIX_ADDR_WIDTH+1)) | 0);
        for (i = 1 ; i < commandArgCount ; i++, col++) {
            uint32_t value = cmdp->args[i];
            if (col == CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE) {
                printf("Too many FIR coefficients\n");
                break;
            }
            if (col == (CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE - 1)) {
                /* Assert reload TLAST (address 'plane select' bit) */
                GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (GPIO_DSP_CMD_LATCH_ADDRESS << GPIO_DSP_CMD_SHIFT) |
                            (row << (GPIO_FOFB_MATRIX_ADDR_WIDTH+1)) |
                            (1 << GPIO_FOFB_MATRIX_ADDR_WIDTH));
            }
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                           (GPIO_DSP_CMD_LATCH_HIGH_VALUE<<GPIO_DSP_CMD_SHIFT) |
                           ((value >> 16) & 0xFFFF));
            /* Ensure that previous update has completed */
            while (GPIO_READ(GPIO_IDX_DSP_CSR) & 0x1) continue;
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (GPIO_DSP_CMD_FIR_RELOAD<<GPIO_DSP_CMD_SHIFT) |
                            (value & 0xFFFF));
            if (col == (CC_PROTOCOL_FOFB_CORRECTOR_FIR_SIZE - 1)) {
                uint32_t csr;
                /* Ensure that previous update has completed */
                while (GPIO_READ(GPIO_IDX_DSP_CSR) & 0x2) continue;
                GPIO_WRITE(GPIO_IDX_DSP_CSR,
                            (GPIO_DSP_CMD_FIR_CONFIG<<GPIO_DSP_CMD_SHIFT));
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
                        (GPIO_DSP_CMD_LATCH_ADDRESS<<GPIO_DSP_CMD_SHIFT) |
                        (row << 10) | col);
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                        (GPIO_DSP_CMD_LATCH_HIGH_VALUE<<GPIO_DSP_CMD_SHIFT) |
                        ((value >> 16) & 0xFFFF));
            GPIO_WRITE(GPIO_IDX_DSP_CSR,
                        (GPIO_DSP_CMD_WRITE_MATRIX_ELEMENT<<GPIO_DSP_CMD_SHIFT) |
                        (value & 0xFFFF));
        }
        }
        break;

    case CC_PROTOCOL_CMD_HI_LONGIN:
        switch (idx) {
        case CC_PROTOCOL_CMD_LONGIN_IDX_GIT_HASH_ID:
            replyp->args[0] = GPIO_READ(GPIO_IDX_GITHASH);
            replyArgCount = 1;
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
            dspUpdate(GPIO_DSP_CMD_WRITE_PS_OFFSET, idx, cmdp->args[0]);
            break;

        case CC_PROTOCOL_CMD_LONGOUT_LO_AWG:
            psAWGcommand(idx, cmdp->args[0]);
            break;
        }
        break;

    case CC_PROTOCOL_CMD_HI_SYSMON:
        replyArgCount = sysmonFetch(replyp->args);
        break;

    case CC_PROTOCOL_CMD_HI_LINKSTATS:
        replyArgCount = auroraStats(replyp->args, commandArgCount);
        break;

    case CC_PROTOCOL_CMD_HI_PLL_REG_IO:
        break;

    case CC_PROTOCOL_CMD_HI_SET_DAC:
        break;

    case CC_PROTOCOL_CMD_HI_I32ARRAY_OUT:
        switch (lo) {
        case CC_PROTOCOL_CMD_LO_I32A_BPM_SETPOINTS:
            ffbStashSetpoints(commandArgCount, cmdp->args, cmdp->cellInfo);
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
    static uint32_t lastIdentifier;

    /*
     * Ignore weird-sized packets
     */
    if ((length < CC_PROTOCOL_ARG_COUNT_TO_SIZE(0))
     || (length > sizeof(struct ccProtocolPacket))
     || ((length % sizeof(uint32_t)) != 0)) {
        return;
    }
    commandArgCount = CC_PROTOCOL_SIZE_TO_ARG_COUNT(length);
    if (cmdp->magic == CC_PROTOCOL_MAGIC_SWAPPED) {
        mustSwap = 1;
        bswap32(&cmdp->magic, length / sizeof(int32_t));
    }
    if (cmdp->magic == CC_PROTOCOL_MAGIC) {
        if (debugFlags & DEBUGFLAG_EPICS) {
            printf("Command:%X identifier:%X args:%d 0x%x\n",
                         (unsigned int)cmdp->command, (unsigned int)cmdp->identifier,
                         commandArgCount, (unsigned int)cmdp->args[0]);
        }
        if (cmdp->identifier != lastIdentifier) {
            int n;
            memcpy(&reply, cmdp, CC_PROTOCOL_ARG_COUNT_TO_SIZE(0));
            if ((n = handleCommand(commandArgCount, cmdp, &reply)) < 0) {
                return;
            }
            lastIdentifier = cmdp->identifier;
            replySize = CC_PROTOCOL_ARG_COUNT_TO_SIZE(n);
            if (mustSwap) {
                bswap32(&reply.magic, replySize / sizeof(int32_t));
            }
        }
        bwudpSend(replyHandle, (const char *)&reply, replySize);
    }
}

void epicsInit(void) {
    bwudpRegisterServer(htons(CC_PROTOCOL_UDP_PORT), epicsHandler);
}
