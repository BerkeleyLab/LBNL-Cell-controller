/*
 * Accept and act upon requests from the fast feedback system
 *
 * Packet transmission is normally in byte order of SYNC packet sender.
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <math.h>
#include "cellControllerProtocol.h"
#include "fastFeedback.h"
#include "frontPanel.h"
#include "gpio.h"
#include "bmb7_udp.h"
#include "util.h"

#define BPMLINKS_CSR_W_SWAP_BANKS               0x80000000
#define BPMLINKS_CSR_R_BANK                     0x80000000
#define BPMLINKS_CSR_RW_CELL_INDEX_MASK         0x1F000000
#define BPMLINKS_CSR_CELL_INDEX_SHIFT           24
#define BPMLINKS_CSR_RW_CCW_INHIBIT             0x800000
#define BPMLINKS_CSR_R_CCW_PACKET_COUNT_MASK    0x3F0000
#define BPMLINKS_CSR_CCW_PACKET_COUNT_SHIFT     16
#define BPMLINKS_CSR_RW_CW_INHIBIT              0x8000
#define BPMLINKS_CSR_R_CW_PACKET_COUNT_MASK     0x3F00
#define BPMLINKS_CSR_CW_PACKET_COUNT_SHIFT      8
#define BPMLINKS_CSR_RW_BPM_COUNT_MASK          0x3F

#define CELL_COMM_CSR_R_READOUT_ACTIVE           0x80000000
#define CELL_COMM_CSR_R_READOUT_VALID            0x40000000
#define CELL_COMM_CSR_R_READOUT_USEC_MASK        0x3E000000
#define CELL_COMM_CSR_READOUT_USEC_SHIFT         25
#define CELL_COMM_CSR_R_SEQNO_MASK               0x1C00000
#define CELL_COMM_CSR_READOUT_SEQNO_SHIFT        22
#define CELL_COMM_CSR_RW_USE_FAKE_DATA           0x100000
#define CELL_COMM_CSR_RW_CW_INHIBIT              0x80000
#define CELL_COMM_CSR_RW_CCW_INHIBIT             0x40000
#define CELL_COMM_CSR_R_CCW_PACKET_COUNT_MASK    0x3F000
#define CELL_COMM_CSR_CCW_PACKET_COUNT_SHIFT     12
#define CELL_COMM_CSR_R_CW_PACKET_COUNT_MASK     0xFC0
#define CELL_COMM_CSR_CW_PACKET_COUNT_SHIFT      6
#define CELL_COMM_CSR_RW_CELL_COUNT_MASK         0x3F

#define ERROR_CONVERT_CSR_R_EMPTY 0x80
#define ERROR_CONVERT_CSR_W_READ  0x1
#define ERROR_CONVERT_CSR_W_RESET 0x2
#define ERROR_CONVERT_CSR_W_SWAP  0x10

#define SUM_CHANNEL_STALE_MARKER  0x80000000
#define SUM_CHANNEL_CLIPPING_FLAG 0x40000000

#define FOFB_PS_SETPOINT_STATUS_FINAL_ADDRESS_MASK  0x3F
#define FOFB_PS_SETPOINT_STATUS_FILL_NUMBER_MASK    0x0F000000

static int cellIndex = -1;
static int cellCount = -1;
static int bpmCount = -1;
static uint32_t fofbPsBitmap = 0;

static void
showSP(const char *msg)
{
    int i;
    uint32_t csr = GPIO_READ(GPIO_IDX_BPMLINKS_CSR);

    printf("Setpoint CSR %s swap: %04X:%04X\n", msg, csr >> 16, csr & 0xFFFF);
    for (i = 0 ; i < 2 * CC_PROTOCOL_MAX_BPM_PER_CELL ; i++) {
        printf ("%c[%d] %d\n", (i & 0x1) ? 'Y' : 'X', i/2,
            *((volatile int32_t *)XPAR_BRAM_BPM_SETPOINTS_S_AXI_BASEADDR + i));
    }

}

int
ffbStashSetpoints(int count, const uint32_t *setpointArgs, int cellInfo)
{
    int i;
    uint32_t csr;
    int pkCellIndex = cellInfo & 0xFF;
    int pkCellCount = (cellInfo >> 8) & 0xFF;
    int pkBPMcount = (cellInfo >> 16) & 0xFF;

    if (count > (2 * CC_PROTOCOL_MAX_BPM_PER_CELL))
        count = (2 * CC_PROTOCOL_MAX_BPM_PER_CELL);
    for (i = 0 ; i < count ; i++) {
        *((volatile int32_t *)XPAR_BRAM_BPM_SETPOINTS_S_AXI_BASEADDR + i) =
                                                                setpointArgs[i];
    }
    if (debugFlags & DEBUGFLAG_SETPOINTS) showSP("before");
    cellIndex = pkCellIndex;
    cellCount = pkCellCount;
    bpmCount = pkBPMcount;
    csr = GPIO_READ(GPIO_IDX_BPMLINKS_CSR);
    csr &= ~(BPMLINKS_CSR_RW_CELL_INDEX_MASK | BPMLINKS_CSR_RW_BPM_COUNT_MASK);
    csr |= ((pkCellIndex << BPMLINKS_CSR_CELL_INDEX_SHIFT) &
                                            BPMLINKS_CSR_RW_CELL_INDEX_MASK) |
                                (pkBPMcount & BPMLINKS_CSR_RW_BPM_COUNT_MASK);
    GPIO_WRITE(GPIO_IDX_BPMLINKS_CSR, BPMLINKS_CSR_W_SWAP_BANKS | csr);

    csr = GPIO_READ(GPIO_IDX_CELL_COMM_CSR);
    csr &= ~CELL_COMM_CSR_RW_CELL_COUNT_MASK;
    csr |= pkCellCount & CELL_COMM_CSR_RW_CELL_COUNT_MASK;
    GPIO_WRITE(GPIO_IDX_CELL_COMM_CSR, csr);

    if (debugFlags & DEBUGFLAG_SETPOINTS) showSP("after");
    return 0;
}

void
ffbSetPsBitmap(uint32_t bitmap)
{
    fofbPsBitmap = bitmap;
}

void
showFOFB(int first, int n)
{
    int i;

    printf ("Readout usec: %d\n", (GPIO_READ(GPIO_IDX_CELL_COMM_CSR) &
         CELL_COMM_CSR_R_READOUT_USEC_MASK) >> CELL_COMM_CSR_READOUT_USEC_SHIFT);
    for (i = first ; i < first + n ; i++) {
        GPIO_WRITE(GPIO_IDX_BPM_READOUT_X, i);
        uint32_t s = GPIO_READ(GPIO_IDX_BPM_READOUT_S);
        printf(" %4d%11d%11d%11d%s\n", i, GPIO_READ(GPIO_IDX_BPM_READOUT_X),
                                          GPIO_READ(GPIO_IDX_BPM_READOUT_Y),
                                          s & 0x3FFFFFFF,
                                          s & 0x40000000 ? "  Clip" : "");
    }
}

int
auroraReadoutCount(int link)
{
    int i, s;
    uint32_t m;

    switch (link) {
    case 0:
        i = GPIO_IDX_BPMLINKS_CSR;
        s = BPMLINKS_CSR_CCW_PACKET_COUNT_SHIFT;
        m = BPMLINKS_CSR_R_CCW_PACKET_COUNT_MASK;
        break;
    case 1:
        i = GPIO_IDX_BPMLINKS_CSR;
        s = BPMLINKS_CSR_CW_PACKET_COUNT_SHIFT;
        m = BPMLINKS_CSR_R_CW_PACKET_COUNT_MASK;
        break;
    case 2:
        i = GPIO_IDX_CELL_COMM_CSR;
        s = CELL_COMM_CSR_CCW_PACKET_COUNT_SHIFT;
        m = CELL_COMM_CSR_R_CCW_PACKET_COUNT_MASK;
        break;
    case 3:
        i = GPIO_IDX_CELL_COMM_CSR;
        s = CELL_COMM_CSR_CW_PACKET_COUNT_SHIFT;
        m = CELL_COMM_CSR_R_CW_PACKET_COUNT_MASK;
        break;
    default: return 0;
    }
    return (GPIO_READ(i) & m) >> s;
}

unsigned int
ffbReadoutTime(void)
{
    return (GPIO_READ(GPIO_IDX_CELL_COMM_CSR) &
          CELL_COMM_CSR_R_READOUT_USEC_MASK) >> CELL_COMM_CSR_READOUT_USEC_SHIFT;
}

int
ffbCellIndex(void)
{
    return cellIndex;
}

int
ffbCellCount(void)
{
    return cellCount;
}

int
ffbCellBPMcount(void)
{
    return bpmCount;
}

int
ffbReadoutIsValid(void)
{
    return (GPIO_READ(GPIO_IDX_CELL_COMM_CSR)&CELL_COMM_CSR_R_READOUT_VALID)!=0;
}

/*
 * Allow updates to be inhibited for diagnostic purposes
 */
void bpmInhibit(int inhibitFlags)
{
    uint32_t csr = GPIO_READ(GPIO_IDX_BPMLINKS_CSR);

    csr &= ~(BPMLINKS_CSR_W_SWAP_BANKS   |
             BPMLINKS_CSR_RW_CCW_INHIBIT |
             BPMLINKS_CSR_RW_CW_INHIBIT);
    if (inhibitFlags & 0x1) csr |= BPMLINKS_CSR_RW_CCW_INHIBIT;
    if (inhibitFlags & 0x2) csr |= BPMLINKS_CSR_RW_CW_INHIBIT;
    GPIO_WRITE(GPIO_IDX_BPMLINKS_CSR, csr);
}

void cellInhibit(int inhibitFlags)
{
    uint32_t csr = GPIO_READ(GPIO_IDX_CELL_COMM_CSR);

    csr &= ~(CELL_COMM_CSR_RW_USE_FAKE_DATA | 
             CELL_COMM_CSR_RW_CCW_INHIBIT |
             CELL_COMM_CSR_RW_CW_INHIBIT);
    if (inhibitFlags & 0x1) csr |= CELL_COMM_CSR_RW_CCW_INHIBIT;
    if (inhibitFlags & 0x2) csr |= CELL_COMM_CSR_RW_CW_INHIBIT;
    if (inhibitFlags & 0x4) csr |= CELL_COMM_CSR_RW_USE_FAKE_DATA;
    GPIO_WRITE(GPIO_IDX_CELL_COMM_CSR, csr);
}

void
ffbShowPowerSupplySetpoints(void)
{
    int i, l;
    l = GPIO_READ(GPIO_IDX_FOFB_PS_SETPOINT_STATUS)
                                   & FOFB_PS_SETPOINT_STATUS_FINAL_ADDRESS_MASK;
    for (i = 0 ; i <= l ; i++) {
        union  {
            float    f;
            uint32_t u;
        } v;
        long ua;
        char sign = 1;
        GPIO_WRITE(GPIO_IDX_FOFB_PS_SETPOINT, i);
        v.u = GPIO_READ(GPIO_IDX_FOFB_PS_SETPOINT);
        ua = v.f * (1000 * 1000);
        if (ua < 0) {
            sign = -1;
            ua = -ua;
        }
        printf("%2d: %4d.%06d\n", i, sign * (ua / 1000000), ua % 1000000);
    }
}
