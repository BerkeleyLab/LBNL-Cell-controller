/*
 * Handle Ethernet links to/from fast orbit feedback power supplies
 */
#include <stdio.h>
#include <stdint.h>
#include "fofbEthernet.h"
#include "gpio.h"
#include "util.h"

#define LINK_COUNT  1

#define ETH_CSR_RESET                   0x1 /* R/W */
#define ETH_CSR_START_AUTONEGOTIATE     0x2 /* Write-only -- Autoclears */
#define ETH_CSR_ENABLE_AUTONEGOTIATE    0x4 /* R/W */
#define ETH_CSR_READBACK_MASK           0xF0
#define ETH_CSR_READBACK_SHIFT          4
# define ETH_CSR_READBACK_SETPOINT      0x00
# define ETH_CSR_READBACK_CURRENT       0x10
# define ETH_CSR_READBACK_VOLTAGE       0x20
#define ETH_CSR_AUTONEGOTIATED      0x8000
#define ETH_CSR_STATUS_WORD_MASK    0xFFFF0000
#define ETH_CSR_STATUS_WORD_SHIFT   16

#define ETH_CSR_STARTUP_MASK (ETH_CSR_RESET               | \
                              ETH_CSR_START_AUTONEGOTIATE | \
                              ETH_CSR_ENABLE_AUTONEGOTIATE)

/* Ethernet PCS/PMA status vector */
#define PCS_SV_PAUSE_MASK   0xC000
#define PCS_SV_PAUSE_SHIFT  14
#define PCS_SV_REMOTE_FAULT 0x2000  /* Unused since MDIO is not present */
#define PCS_SV_FULL_DUPLEX  0x1000
#define PCS_SV_SPEED_MASK   0xC00
#define PCS_SV_SPEED_1000   0x800
#define PCS_SV_SPEED_100    0x400
#define PCS_SV_SPEED_10     0x000
#define PCS_SV_RXNOTINTABLE 0x40
#define PCS_SV_RXDISPERR    0x20
#define PCS_SV_RUDI_INVALID 0x10
#define PCS_SV_RUDI_I       0x8
#define PCS_SV_RUDI_C       0x4
#define PCS_SV_LINK_SYNCED  0x2
#define PCS_SV_LINK_STATUS  0x1

static void
updateCSR(int idx, uint32_t mask, uint32_t new)
{
    uint32_t csr = GPIO_READ(GPIO_IDX_ETHERNET0_CSR+idx);
    csr &= ~mask;
    csr |= new;
    GPIO_WRITE(GPIO_IDX_ETHERNET0_CSR+idx, csr);
}

static void
showStatusVector(int idx, uint32_t sv)
{
    printf("FOFB Ethernet %d PCS/PMA status: %04X\n", idx, sv);
    printf ("  Link %s\n", sv & PCS_SV_LINK_STATUS ? "up" : "down");
    if (sv & PCS_SV_LINK_SYNCED) {
        printf ("  Link synchronized\n");
    }
    if (sv & PCS_SV_LINK_STATUS) {
        if (sv & PCS_SV_PAUSE_MASK)
            printf("  Pause: %x\n", (sv&PCS_SV_PAUSE_MASK)>>PCS_SV_PAUSE_SHIFT);
        printf("  %s duplex\n", sv & PCS_SV_FULL_DUPLEX ? "Full" : "Half");
        printf("  %s Mb/s\n", (sv&PCS_SV_SPEED_MASK)==PCS_SV_SPEED_1000?"1000":
                              (sv&PCS_SV_SPEED_MASK)==PCS_SV_SPEED_100 ?"100" :
                              (sv&PCS_SV_SPEED_MASK)==PCS_SV_SPEED_10  ?"10"  :
                              "??");
    }
}

void
fofbEthernetShowStatus(void)
{
    int idx;
    for (idx = 0 ; idx < 2 ; idx++) {
        uint32_t csr = GPIO_READ(GPIO_IDX_ETHERNET0_CSR+idx);
        showStatusVector(idx, (csr & ETH_CSR_STATUS_WORD_MASK)
                                                  >> ETH_CSR_STATUS_WORD_SHIFT);
        showReg(GPIO_IDX_ETHERNET0_CSR+idx);
    }
}

uint32_t
fofbEthernetGetPCSPMAstatus(void)
{
    return (GPIO_READ(GPIO_IDX_ETHERNET0_CSR+1) & ETH_CSR_STATUS_WORD_MASK) |
           ((GPIO_READ(GPIO_IDX_ETHERNET0_CSR+0) & ETH_CSR_STATUS_WORD_MASK) >> 
                                                   ETH_CSR_STATUS_WORD_SHIFT);

}

void
fofbEthernetSetReadback(int idx, int mode)
{
    updateCSR(idx, ETH_CSR_READBACK_MASK,
                    ((mode << ETH_CSR_READBACK_SHIFT) & ETH_CSR_READBACK_MASK));
}

static void
fofbNegotiate(int idx)
{
    uint32_t csr, autoNegotiate = ETH_CSR_ENABLE_AUTONEGOTIATE;
    int pass;

    for (;;) {
        updateCSR(idx, ETH_CSR_STARTUP_MASK, autoNegotiate | ETH_CSR_RESET);
        microsecondSpin(10);
        updateCSR(idx, ETH_CSR_STARTUP_MASK, autoNegotiate);
        microsecondSpin(1000);
        if (!autoNegotiate) {
            fofbEthernetShowStatus();
            return;
        }
        updateCSR(idx, ETH_CSR_STARTUP_MASK,
                                   autoNegotiate | ETH_CSR_START_AUTONEGOTIATE);
        for (pass = 0 ; ; pass++) {
            microsecondSpin(100);
            csr = GPIO_READ(GPIO_IDX_ETHERNET0_CSR);
            if (csr & ETH_CSR_AUTONEGOTIATED) {
                return;
            }
            if (pass > 10000) {
                if (autoNegotiate == 0) return;
                warn("FOFB Ethernet %d negotiation failed to complete.\n", idx);
                printf("           Will disable negotiation and continue.\n");
                autoNegotiate = 0;
                break;
            }
        }
    }
}

void
fofbEthernetInit(void)
{
    int idx;
    for (idx = 0 ; idx < 2 ; idx++) {
        fofbNegotiate(idx);
    }
    fofbEthernetShowStatus();
}

void
fofbEthernetBringUp(void)
{
    int idx;
    for (idx = 0 ; idx < 2 ; idx++) {
        uint32_t csr = GPIO_READ(GPIO_IDX_ETHERNET0_CSR+idx);
        uint32_t sv = (csr&ETH_CSR_STATUS_WORD_MASK)>>ETH_CSR_STATUS_WORD_SHIFT;
        if (!(sv & PCS_SV_LINK_SYNCED)) {
            fofbNegotiate(idx);
        }
    }
    fofbEthernetShowStatus();
}
