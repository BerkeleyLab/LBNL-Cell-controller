/*
 * Monitor Fast MPS system
 */
#include <stdio.h>
#include <stdint.h>
#include "cellControllerProtocol.h"
#include "fastMPS.h"
#include "gpio.h"
#include "util.h"

#define FMPS_COMM_CSR_R_READOUT_ACTIVE           0x80000000
#define FMPS_COMM_CSR_R_READOUT_VALID            0x40000000
#define FMPS_COMM_CSR_R_READOUT_USEC_MASK        0x3E000000
#define FMPS_COMM_CSR_READOUT_USEC_SHIFT         25
#define FMPS_COMM_CSR_R_SEQNO_MASK               0x1C00000
#define FMPS_COMM_CSR_READOUT_SEQNO_SHIFT        22
#define FMPS_COMM_CSR_RW_CW_INHIBIT              0x80000
#define FMPS_COMM_CSR_RW_CCW_INHIBIT             0x40000
#define FMPS_COMM_CSR_R_CCW_PACKET_COUNT_MASK    0x3F000
#define FMPS_COMM_CSR_CCW_PACKET_COUNT_SHIFT     12
#define FMPS_COMM_CSR_R_CW_PACKET_COUNT_MASK     0xFC0
#define FMPS_COMM_CSR_CW_PACKET_COUNT_SHIFT      6
#define FMPS_COMM_CSR_RW_FMPS_COUNT_MASK         0x3F

#define FMPS_CSR_FMPS_INDEX_SHIFT                24
#define FMPS_CSR_RW_FMPS_INDEX_MASK              0x1F000000

static int fmpsIndex = -1;
static int fmpsCount = -1;

void
showFMPS(int first, int n)
{
    int i;
    const char *fmt;

    if (DEBUGFLAG_SHOW_FMPS_HEX) {
        fmt = " %2d  0x%08X\n";
    }
    else {
        fmt = " %2d%11d\n";
    }

    printf ("Readout usec: %d\n", (GPIO_READ(GPIO_IDX_FMPS_COMM_CSR) &
         FMPS_COMM_CSR_R_READOUT_USEC_MASK) >> FMPS_COMM_CSR_READOUT_USEC_SHIFT);
    for (i = first ; i < first + n ; i++) {
        GPIO_WRITE(GPIO_IDX_FMPS_READOUT, i);
        uint32_t data = GPIO_READ(GPIO_IDX_FMPS_READOUT);
        printf(fmt, i, data & 0x3FFFFFFF);
    }
}

int
fmpsConfig(int fmpsInfo)
{
    uint32_t csr;
    int pkFMPSIndex = fmpsInfo & 0xFF;
    int pkFMPSCount = (fmpsInfo >> 8) & 0xFF;

    fmpsIndex = pkFMPSIndex;
    fmpsCount = pkFMPSCount;

    csr = GPIO_READ(GPIO_IDX_FMPS_CSR);
    csr &= ~FMPS_CSR_RW_FMPS_INDEX_MASK;
    csr |= (pkFMPSIndex << FMPS_CSR_FMPS_INDEX_SHIFT) &
        FMPS_CSR_RW_FMPS_INDEX_MASK;
    GPIO_WRITE(GPIO_IDX_FMPS_CSR, csr);

    csr = GPIO_READ(GPIO_IDX_FMPS_COMM_CSR);
    csr &= ~FMPS_COMM_CSR_RW_FMPS_COUNT_MASK;
    csr |= pkFMPSCount & FMPS_COMM_CSR_RW_FMPS_COUNT_MASK;
    GPIO_WRITE(GPIO_IDX_FMPS_COMM_CSR, csr);

    return 0;
}
