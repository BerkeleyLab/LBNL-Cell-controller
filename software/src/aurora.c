#include <stdio.h>
#include "aurora.h"
#include "cellControllerProtocol.h"
#include "fastFeedback.h"
#include "gpio.h"
#include "util.h"

/* Read/write bits */
#define CSR_GTX_RESET       0x1
#define CSR_AURORA_RESET    0x2
#define CSR_FA_ENABLE       0x4

/* Read-only bits */
#define CSR_GTX_RESET_OUT         0x100
#define CSR_GT0_QPLL_REFCLKLOST   0x200
#define CSR_GT0_QPLL_LOCK         0x400
#define CSR_PLL_NOT_LOCKED        0x800

#define LINK_UP_SHIFT             12
#define CSR_BPM_CCW_LINK_UP       0x1000
#define CSR_BPM_CW_LINK_UP        0x2000
#define CSR_CELL_CCW_LINK_UP      0x4000
#define CSR_CELL_CW_LINK_UP       0x8000
#define CSR_BPM_TEST_LINK_UP      0x10000

#define SOFT_ERR_SHIFT            17
#define CSR_BPM_CCW_SOFT_ERR      0x20000
#define CSR_BPM_CW_SOFT_ERR       0x40000
#define CSR_CELL_CCW_SOFT_ERR     0x80000
#define CSR_CELL_CW_SOFT_ERR      0x100000
#define CSR_BPM_TEST_SOFT_ERR     0x200000

#define HARD_ERR_SHIFT            22
#define CSR_BPM_CCW_HARD_ERR      0x400000
#define CSR_BPM_CW_HARD_ERR       0x800000
#define CSR_CELL_CCW_HARD_ERR     0x1000000
#define CSR_CELL_CW_HARD_ERR      0x2000000
#define CSR_BPM_TEST_HARD_ERR     0x4000000


#define RD_CSR()     GPIO_READ(GPIO_IDX_AURORA_CSR)
#define WR_CSR(v)    GPIO_WRITE(GPIO_IDX_AURORA_CSR,(v))

void
auroraResetGTX(void)
{
    uint32_t csr;

    WR_CSR(CSR_AURORA_RESET);
    microsecondSpin(2);
    WR_CSR(CSR_AURORA_RESET | CSR_GTX_RESET);
    microsecondSpin(2);
    csr = RD_CSR();
    if (csr & (CSR_CELL_CW_LINK_UP  |
               CSR_CELL_CCW_LINK_UP |
               CSR_BPM_CW_LINK_UP   |
               CSR_BPM_CCW_LINK_UP)) warn("AURORA ACTIVE");
    WR_CSR(CSR_AURORA_RESET);
    microsecondSpin(100);
    WR_CSR(0);
    microsecondSpin(10);
    csr = RD_CSR();
    if (csr & CSR_GTX_RESET_OUT) warn("GTX STILL IN RESET");
    if (csr & CSR_PLL_NOT_LOCKED) warn("GT0 PLL NOT LOCKED");
    WR_CSR(CSR_FA_ENABLE);
}

void
auroraInit(void)
{
    auroraResetGTX();
    auroraReadoutShowStats(0);
}

int
auroraReadoutIsUp(unsigned int link)
{
    if(link > AURORA_LINK_COUNT-1)
        return 0;

    uint32_t csr = RD_CSR();
    return (csr & (1 << (LINK_UP_SHIFT + link))) != 0;
}

/*
 * Read link statistic histogram value
 * Four bins per link.  Eight 'links', four true links.
 * final value in the final link histogram is used to count the number of
 * times that the cell controller failed to get a full set of values.
 */
static void
auroraFetchStats(int addrLo, unsigned int *hi, unsigned int *lo)
{
    GPIO_WRITE(GPIO_IDX_LINK_STATISTICS_CSR, addrLo + 1);
    *hi = GPIO_READ(GPIO_IDX_LINK_STATISTICS_CSR);
    GPIO_WRITE(GPIO_IDX_LINK_STATISTICS_CSR, addrLo);
    *lo = GPIO_READ(GPIO_IDX_LINK_STATISTICS_CSR);
}

int
auroraReadoutStats(unsigned int link, int idx, unsigned int *hi, unsigned int *lo)
{
    // BPM Test link doesn't have stats
    if(link > AURORA_LINK_READOUT_COUNT-1)
        return 0;

    unsigned int h, l;
    int addrLo = (((link & 0x7) << 2) | (idx & 0x3)) << 1;

    auroraFetchStats(addrLo, &h, &l);
    for (;;) {
        auroraFetchStats(addrLo, hi, lo);
        if ((h == *hi) && (l == *lo)) return 1;
        h = *hi;
        l = *lo;
    }
}

void
auroraReadoutShowStats(int showTimeout)
{
    unsigned int link, i;
    unsigned int hi, lo;
    uint32_t csr = RD_CSR();

    printf("AURORA CSR: %04x:%04X", csr >> 16, csr & 0xFFFF);
    if (csr & CSR_GTX_RESET_OUT) printf( "  GTX RESET OUT");
    if (csr & CSR_AURORA_RESET) printf("   Aurora Reset");
    if (csr & CSR_GTX_RESET) printf("   GTX Reset");
    printf("\n");
    for (link = 0 ; link < AURORA_LINK_COUNT ; link++) {
        printf("Link %d %s%s%s   RxCount:%d\n", link,
                                csr & (1 << (LINK_UP_SHIFT + link)) ? "UP" : "DOWN",
                                csr & (1 << (SOFT_ERR_SHIFT + link)) ? ", SOFT ERROR" : "",
                                csr & (1 << (HARD_ERR_SHIFT + link)) ? ", HARD ERROR" : "",
                                auroraReadoutCount(link));
        if (showTimeout) {
            for (i = 0 ; i < AURORA_LINK_READOUT_COUNT ; i++) {
                auroraReadoutStats(link, i, &hi, &lo);
                printf("Link %d[%d] = %08X:%08X\n", link, i, hi, lo);
            }
        }
    }
    auroraReadoutStats(AUSTATS_TIMEOUT_COUNTER_LINK,
                       AUSTATS_TIMEOUT_COUNTER_IDX, &hi, &lo);
    printf(" Timeouts = %08X:%08X\n", hi, lo);
}

void
auroraWriteCSR(unsigned int csr)
{
    WR_CSR(csr);
}

void
auroraReadoutClearStats(void)
{
     GPIO_WRITE(GPIO_IDX_LINK_STATISTICS_CSR, 0x80000000);
}
