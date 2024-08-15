/*
 * Copyright 2020, Lawrence Berkeley National Laboratory
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from this
 * software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS
 * AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
 * BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdio.h>
#include "gpio.h"
#include "mgt.h"
#include "util.h"

// MGT CONTROL BITMASK
#define CSR_W_ENABLE_RESETS     0x80000000
#define CSR_W_RX_BITSLIDE_REQ   0x40000000
#define CSR_W_GT_TX_RESET       0x20000000
#define CSR_W_GT_RX_PMA_RESET   0x10000000
#define CSR_W_GT_RX_RESET       0x08000000
#define CSR_W_CPLL_RESET        0x04000000
#define CSR_W_SOFT_RESET        0x02000000
// MGT DRP BITMASK
#define CSR_W_DRP_WE            0x40000000
#define CSR_W_DRP_ADDR_SHIFT    16
#define CSR_R_DRP_BUSY          0x80000000
#define CSR_DRP_DATA_MASK       0xFFFF
// MGT STATUS BITMASK
#define CSR_R_RX_ALIGNED        0x40000000
#define CSR_R_RX_RESET_DONE     0x20000000
#define CSR_R_CPLL_LOCKED       0x10000000
#define CSR_R_CPLL_FB_CLK_LOST  0x08000000
#define CSR_R_RX_FSM_RESET_DONE 0x04000000
#define CSR_R_TX_FSM_RESET_DONE 0x02000000
#define CSR_R_TX_RESET_DONE     0x01000000
#define CPLL_LOCK_TIMEOUT_US         50000

/*
 * Receiver alignment state machines
 */
struct rxAligner {
    uint16_t csrIdx;
    uint16_t mgtStatusIdx;
    uint32_t whenEntered;
    uint32_t resetCount;
    enum rxState { S_ALIGNED, S_APPLY_RESET, S_HOLD_RESET,
                   S_AWAIT_RESET_COMPLETION, S_POST_RESET_DELAY,
                   S_POST_ALIGNMENT_DELAY } state;
} rxAligners[1] = {
    { .csrIdx       = GPIO_IDX_EVR_GTX_DRP,
      .mgtStatusIdx = GPIO_IDX_GTX_CSR }
};

static void
writeResets(uint32_t resets)
{
    GPIO_WRITE(GPIO_IDX_EVR_GTX_DRP, CSR_W_ENABLE_RESETS | resets);
    if (debugFlags & DEBUGFLAG_SHOW_MGT_RESETS) {
        printf("MGT resets:%08X\n", GPIO_READ(GPIO_IDX_EVR_GTX_DRP));
    }
}

void
mgtRxBitslide(void)
{
    writeResets(CSR_W_RX_BITSLIDE_REQ);
    microsecondSpin(2);
    writeResets(0);
}

/*
 * Receiver can place its recovered clock at 20 different phases relative to
 * the incoming data.  This is not acceptable since it affects the measurement
 * of the round-trip latency so the reciver is configured with automatic
 * bit-slide disabled and manual bit-slide never performed.  Instead the
 * following state machine keeps resetting the receiver until the receiver
 * comes out of reset in the spot that is locked.
 */
static int
mgtCrankRxAlignerFor(struct rxAligner *rxp)
{
    uint32_t csr = GPIO_READ(rxp->csrIdx);
    enum rxState oldState = rxp->state;
    switch (rxp->state) {
    case S_ALIGNED:
        rxp->resetCount = 0;
        if (!(csr & CSR_R_RX_ALIGNED)) {
            if (debugFlags & DEBUGFLAG_SHOW_RX_ALIGNER) {
                printf("EVR CSR %d misaligned after %u us.\n", rxp->csrIdx,
                                  MICROSECONDS_SINCE_BOOT() - rxp->whenEntered);
            }
            rxp->state = S_APPLY_RESET;
        }
        break;

    case S_APPLY_RESET:
        rxp->resetCount++;
        if ((debugFlags & DEBUGFLAG_SHOW_RX_ALIGNER)
         && ((rxp->resetCount % 1000000) == 0)) {
            printf("EVR CSR %d reset count %d\n", rxp->csrIdx, rxp->resetCount);
        }
        GPIO_WRITE(rxp->csrIdx, CSR_W_ENABLE_RESETS | CSR_W_SOFT_RESET);
        rxp->state = S_HOLD_RESET;
        break;

    case S_HOLD_RESET:
        if ((MICROSECONDS_SINCE_BOOT() - rxp->whenEntered) > 10) {
            GPIO_WRITE(rxp->csrIdx, CSR_W_ENABLE_RESETS);
            rxp->state = S_AWAIT_RESET_COMPLETION;
        }
        break;

    case S_AWAIT_RESET_COMPLETION:
        /*
         * Large timeout is to limit message rate to a reasonable value.
         * No problem since the timeout is very unlikely to ever be reached.
         */
        if (csr & CSR_R_RX_RESET_DONE) {
            rxp->state = S_POST_RESET_DELAY;
        }
        else if ((MICROSECONDS_SINCE_BOOT() - rxp->whenEntered) > 250000) {
            printf("Reg %d (0x%X) Rx reset not done\n", rxp->csrIdx, csr);
            rxp->state = S_APPLY_RESET;
        }
        break;

    case S_POST_RESET_DELAY:
        if (csr & CSR_R_RX_ALIGNED) {
            rxp->state = S_POST_ALIGNMENT_DELAY;
        }
        else if ((MICROSECONDS_SINCE_BOOT() - rxp->whenEntered) > 1000) {
            rxp->state = S_APPLY_RESET;
        }
        break;

    case S_POST_ALIGNMENT_DELAY:
        if ((MICROSECONDS_SINCE_BOOT() - rxp->whenEntered) > 250000) {
            if (csr & CSR_R_RX_ALIGNED) {
                if (debugFlags & DEBUGFLAG_SHOW_RX_ALIGNER) {
                    printf("EVR CSR %d aligned after %d resets.\n",
                                                  rxp->csrIdx, rxp->resetCount);
                }
                rxp->state = S_ALIGNED;
            }
            else {
                rxp->state = S_APPLY_RESET;
            }
        }
        break;
    }
    if (rxp->state != oldState) {
        rxp->whenEntered = MICROSECONDS_SINCE_BOOT();
    }
    return (rxp->state == S_ALIGNED);
}

void
mgtInit(void)
{
    uint32_t then;
    uint32_t resets = CSR_W_GT_TX_RESET | CSR_W_GT_RX_PMA_RESET |
                      CSR_W_GT_RX_RESET | CSR_W_CPLL_RESET | CSR_W_SOFT_RESET;
    writeResets(resets);
    microsecondSpin(10);
    resets &= ~CSR_W_CPLL_RESET;
    writeResets(resets);
    microsecondSpin(10);
    if (!(GPIO_READ(GPIO_IDX_EVR_GTX_DRP) & CSR_R_CPLL_LOCKED)) {
        warn("Warning -- EVR CPLL didn't lock.");
    }
    writeResets(0);
    then = MICROSECONDS_SINCE_BOOT();
    while (!(GPIO_READ(GPIO_IDX_EVR_GTX_DRP) & CSR_R_RX_RESET_DONE)) {
        if ((MICROSECONDS_SINCE_BOOT() - then) > 100000) {
            warn("EVR MGT Rx reset not done: %X", GPIO_READ(GPIO_IDX_EVR_GTX_DRP));
            break;
        }
    }
    then = MICROSECONDS_SINCE_BOOT();
    while (!(mgtCrankRxAlignerFor(&rxAligners[0]))) {
        if ((MICROSECONDS_SINCE_BOOT() - then) > 5000000) {
            warn("Can't align MGT receiver -- will keep trying in background");
            break;
        }
    }
}

void
mgtCrankRxAligner(void)
{
    mgtCrankRxAlignerFor(&rxAligners[0]);
}

void
mgtShowRxAligners(void)
{
    int i;
    for (i = 0 ; i < sizeof rxAligners / sizeof rxAligners[0] ; i++) {
        struct rxAligner *rxp = &rxAligners[i];
        printf("RX %d: %3d  %08X  %08X\n", i, rxp->state,
                          GPIO_READ(rxp->csrIdx), GPIO_READ(rxp->mgtStatusIdx));
    }
}
