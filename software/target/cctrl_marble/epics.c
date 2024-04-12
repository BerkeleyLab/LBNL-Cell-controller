/*
 * New marble version using bwudp and badger;
 * Accept and act upon commands from IOC
 */

#include <stdio.h>
#include <string.h>
#include "aurora.h"
#include "cellControllerProtocol.h"
#include "eebi.h"
#include "epics.h"
#include "evr.h"
#include "fastFeedback.h"
#include "fofbEthernet.h"
#include "gpio.h"
#include "pilotTones.h"
#include "psAWG.h"
#include "psWaveformRecorder.h"
#include "qsfp.h"
#include "softwareBuildDate.h"
#include "util.h"
#include "xadc.h"

#include "bwudp.h"
#include "systemParameters.h"

#define BPM_COUNT_MASK 0x3F

static struct ccProtocolPacket reply;
static int replyCount;

static void parseCmd(struct ccProtocolPacket *cmd, int length);
static void rxPacketCallback(bwudpHandle handle, char *payload, int length);

static bwudpHandle handleNonce;

int epicsInit(void) {
    int rval = bwudpRegisterInterface(
                         (ethernetMAC *)&systemParameters.netConfig.ethernetMAC,
                         (ipv4Address *)&systemParameters.netConfig.np.address,
                         (ipv4Address *)&systemParameters.netConfig.np.netmask,
                         (ipv4Address *)&systemParameters.netConfig.np.gateway);
    rval |= bwudpRegisterServer(htons(CC_PROTOCOL_UDP_PORT), (bwudpCallback)rxPacketCallback);
    return rval;
}

static void rxPacketCallback(bwudpHandle handle, char *payload, int length) {
    // Handle the packet
    handleNonce = handle;
    parseCmd((struct ccProtocolPacket *)payload, length);
    return;
}

static void sendReply(void) {
    if (debugFlags & DEBUGFLAG_EPICS)
        printf("%d REPLY %X %X %X\n", replyCount, reply.magic,
                                            reply.identifier, reply.command);
    bwudpSend(handleNonce, (const char *)&reply, replyCount);
}

void epicsService(void) {
    bwudpCrank();
}

/*
 * Handle an EEBI reset request
 */
static void
crankEEBIresetStateMachine(int value)
{
    static uint16_t match[] = { 1, 100, 10000 };
    static int i;

    if (value == match[i]) {
        i++;
        if (i == (sizeof match / sizeof match[0])) {
            eebiResetInterlock();
        }
    }
    else if (value == match[0]) {
        i = 1;
    }
    else {
        i = 0;
    }
}
/*
 * Return system monitors
 */
static int
sysmon(void)
{
    int i;
    int pll;
    int rIndex = 0;

    xadcUpdate();
    for (i = 0 ; i < XADC_CHANNEL_COUNT ; ) {
        uint32_t v = xadcVal[i++];
        if (i < XADC_CHANNEL_COUNT) v |= xadcVal[i++] << 16;
        reply.args[rIndex++] = v;
    }
    for (i = 0 ; i < QSFP_COUNT ; i++) {
        int r;
        reply.args[rIndex++] = (qsfpTemperature(i)<<16) | qsfpVoltage(i);
        for (r = 0 ; r < QSFP_RX_COUNT ; ) {
            uint32_t v = qsfpRxPower(i, r++);
            v |= qsfpRxPower(i, r++) << 16;
            reply.args[rIndex++] = v;
        }
    }
    reply.args[rIndex++] = (GPIO_READ(GPIO_IDX_EVENT_STATUS) << 16);
    for (i = 0 ; i < PILOT_TONE_ADC_COUNT ; i += 2)
        reply.args[rIndex++] = (ptADC(i+1) << 16) | ptADC(i);
    for (i = 0 ; i < PILOT_TONE_TEMPERATURE_COUNT ; i++)
        reply.args[rIndex++] = ptTemperature(i);
    for (pll = 0 ; pll < 2 ; pll++) {
        for (i = 0 ; i < PILOT_TONE_PLL_OUTPUT_COUNT ; i += 2) {
            reply.args[rIndex++] = (ptPLLvalue(pll, i+1)<<16) |
                                    ptPLLvalue(pll, i);
        }
        reply.args[rIndex++] = (ptPLLtable(pll) << 16) |
                                ptPLLvalue(pll, PILOT_TONE_PLL_OUTPUT_COUNT);
    }
    reply.args[rIndex++] = (evrNtooManySecondEvents() << 16) |
                            evrNtooFewSecondEvents();
    reply.args[rIndex++] = evrNoutOfSequenceSeconds();
    reply.args[rIndex++] = GPIO_READ(GPIO_IDX_AWG_CSR);
    reply.args[rIndex++] = GPIO_READ(GPIO_IDX_WFR_CSR);
    reply.args[rIndex++] = fofbEthernetGetPCSPMAstatus();
    return rIndex;
}

/*
 * Return EEBI status
 */
static int
fetchEEBI(void)
{
    reply.args[0] = GPIO_READ(GPIO_IDX_EEBI_CSR);
    eebiFetchFaultInfo(&reply.args[1], &reply.args[2], &reply.args[3]);
    return 4;
}

/*
 * Return or clear Aurora link statistics
 */
static int
auroraStats(int argc)
{
    int link;
    int rIndex = 0;
    int i;

    if (argc) {
        auroraReadoutClearStats();
    }
    else {
        unsigned int hi, lo;
        for (link = 0 ; link < AURORA_LINK_COUNT ; link++) {
            reply.args[rIndex++] = auroraReadoutIsUp(link);
            reply.args[rIndex++] = auroraReadoutCount(link);
            for (i = 0 ; i < AURORA_LINK_READOUT_COUNT ; i++) {
                auroraReadoutStats(link, i, &hi, &lo);
                reply.args[rIndex++] = lo;
                reply.args[rIndex++] = hi;
            }
        }
        auroraReadoutStats(AUSTATS_TIMEOUT_COUNTER_LINK,
                           AUSTATS_TIMEOUT_COUNTER_IDX, &hi, &lo);
        reply.args[rIndex++] = lo;
        reply.args[rIndex++] = hi;
        reply.args[rIndex++] = GPIO_READ(GPIO_IDX_BPMLINKS_EXTRA_STATUS) & BPM_COUNT_MASK;
        reply.args[rIndex++] = GPIO_READ(GPIO_IDX_BPM_RX_BITMAP);
        reply.args[rIndex++] = GPIO_READ(GPIO_IDX_CELL_RX_BITMAP);
        reply.args[rIndex++] = ffbReadoutTime();
        reply.args[rIndex++] = ffbCellIndex();
        reply.args[rIndex++] = ffbCellCount();
        reply.args[rIndex++] = ffbCellBPMcount();
        reply.args[rIndex++] = ffbReadoutIsValid();
        reply.args[rIndex++] = GPIO_READ(GPIO_IDX_FOFB_CSR);
        reply.args[rIndex++] = GPIO_READ(GPIO_IDX_FOFB_ENABLE_BITMAP);
    }
    return rIndex;
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

static void
handleCommand(int argc, struct ccProtocolPacket *cmdp)
{
    int replyArgCount = 0;
    int hi  = cmdp->command & CC_PROTOCOL_CMD_MASK_HI;
    int lo  = cmdp->command & CC_PROTOCOL_CMD_MASK_LO;
    int idx = cmdp->command & CC_PROTOCOL_CMD_MASK_IDX;

    switch (hi) {
    case CC_PROTOCOL_CMD_HI_FOFB_GAIN:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_FOFB_GAIN, argc, cmdp->args);
            break;

    case CC_PROTOCOL_CMD_HI_CLIP_LIMIT:
        switch(lo) {
        case CC_PROTOCOL_CMD_LO_CLIP_LIMIT_PS:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_PS_CLIP_LIMIT, argc, cmdp->args);
            break;

        case CC_PROTOCOL_CMD_LO_CLIP_LIMIT_FFB:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_FFB_CLIP_LIMIT, argc, cmdp->args);
            break;

        default: return;
        }
        break;

    case CC_PROTOCOL_CMD_HI_PS_OFFSET:
            dspUpdateAll(GPIO_DSP_CMD_WRITE_PS_OFFSET, argc, cmdp->args);
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
        for (i = 1 ; i < argc ; i++, col++) {
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

        for (i = 1 ; i < argc ; i++, col++) {
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
        case CC_PROTOCOL_CMD_LONGIN_IDX_FIRMWARE_BUILD_DATE:
            reply.args[0] = GPIO_READ(GPIO_IDX_FIRMWARE_BUILD_DATE);
            replyArgCount = 1;
            break;
        case CC_PROTOCOL_CMD_LONGIN_IDX_SOFTWARE_BUILD_DATE:
            reply.args[0] = SOFTWARE_BUILD_DATE;
            replyArgCount = 1;
            break;
        default: return;
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

            case CC_PROTOCOL_CMD_LONGOUT_IDX_CLEAR_EEBI_TRIP:
                crankEEBIresetStateMachine(cmdp->args[0]);
                break;

            default: return;
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
        replyArgCount = sysmon();
        break;

    case CC_PROTOCOL_CMD_HI_LINKSTATS:
        replyArgCount = auroraStats(argc);
        break;

    case CC_PROTOCOL_CMD_HI_SET_ATTENUATOR:
        ptAttenWrite(idx, cmdp->args[0]);
        break;

    case CC_PROTOCOL_CMD_HI_SET_PLL_OUTPUT:
        ptPLLoutputControl(lo != 0, idx, cmdp->args[0]);
        break;

    case CC_PROTOCOL_CMD_HI_SET_PLL_TABLE:
        ad9520SetTable(idx, cmdp->args[0]);
        break;

    case CC_PROTOCOL_CMD_HI_PLL_REG_IO:
        reply.args[0] = ad9520RegIO(idx, cmdp->args[0]);
        replyArgCount = 1;
        break;

    case CC_PROTOCOL_CMD_HI_SET_EEBI_CONFIG:
        if (argc != EEBI_ARG_COUNT) return;
        eebiConfig(cmdp->args);
        break;

    case CC_PROTOCOL_CMD_HI_GET_EEBI:
        replyArgCount = fetchEEBI();
        break;

    case CC_PROTOCOL_CMD_HI_SET_DAC:
        max5802write(idx, cmdp->args[0]);
        break;

    case CC_PROTOCOL_CMD_HI_I32ARRAY_OUT:
        switch (lo) {
        case CC_PROTOCOL_CMD_LO_I32A_BPM_SETPOINTS:
            ffbStashSetpoints(argc, cmdp->args, cmdp->cellInfo);
            eebiHaveSetpoints();
            break;
        default: return;
        }
        break;

    case CC_PROTOCOL_CMD_HI_F32ARRAY_OUT:
        switch (lo) {
        case CC_PROTOCOL_CMD_LO_F32A_AWG_PATTERN:
            psAWGstashSamples(&cmdp->args[1], cmdp->args[0], argc - 1);
            break;

        default: return;
        }
        break;

    case CC_PROTOCOL_CMD_HI_WAVEFORM:
        replyArgCount = psRecorderFetch(reply.args, CC_PROTOCOL_ARG_CAPACITY,
                                                            idx, cmdp->args[0]);
        break;

    default: return;
    }
    if (reply.magic == CC_PROTOCOL_MAGIC_SWAPPED) {
        int i;
        for (i = 0 ; i < replyArgCount ; i++)
            reply.args[i] = __builtin_bswap32(reply.args[i]);
    }
    replyCount = CC_PROTOCOL_ARG_COUNT_TO_SIZE(replyArgCount);
    sendReply();
}

static void parseCmd(struct ccProtocolPacket *cmd, int length) {
    if (length >= (int)CC_PROTOCOL_ARG_COUNT_TO_U32_COUNT(0)) {
        if (debugFlags & DEBUGFLAG_EPICS)
            printf("%d CMD %X %X %X\n", length, cmd->magic, cmd->identifier,
                    cmd->command);
        if ((cmd->magic == reply.magic)
                && (cmd->identifier == reply.identifier)) {
            sendReply();
        }
        else {
            int argc = CC_PROTOCOL_U32_COUNT_TO_ARG_COUNT(length);
            reply.magic = cmd->magic;
            reply.identifier = cmd->identifier;
            reply.command = cmd->command;
            if (cmd->magic == CC_PROTOCOL_MAGIC_SWAPPED) {
                int i;
                cmd->magic = __builtin_bswap32(cmd->magic);
                cmd->identifier = __builtin_bswap32(cmd->identifier);
                cmd->command = __builtin_bswap32(cmd->command);
                for (i = 0 ; i < argc ; i++)
                    cmd->args[i] = __builtin_bswap32(cmd->args[i]);
            }
            if (cmd->magic == CC_PROTOCOL_MAGIC) handleCommand(argc, cmd);
        }
    }
    return;
}
