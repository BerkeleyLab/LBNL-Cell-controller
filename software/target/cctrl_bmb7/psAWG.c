#include <stdio.h>
#include "cellControllerProtocol.h"
#include "evr.h"
#include "gpio.h"
#include "util.h"

#define CSR_AWG_ENABLE          0x80000000
#define CSR_AWG_ENABLED         0x40000000
#define CSR_AWG_STATE_MASK      0x30000000
#define CSR_AWG_STATE_SHIFT     28
#define CSR_AWG_SOFT_TRIGGER    0x08000000
#define CSR_AWG_USE_FA_MARKER   0x04000000
#define CSR_AWG_MODE_MASK       0x03000000
#define CSR_AWG_MODE_SHIFT      24
#define CSR_AWG_INTERVAL_MASK   0x000FFFFF

// Ensure that range is between 10 us and 1 ms
#define MINIMUM_INTERVAL  (XPAR_CPU_CORE_CLOCK_FREQ_HZ / 100000)
#define MAXIMUM_INTERVAL  (XPAR_CPU_CORE_CLOCK_FREQ_HZ / 1000)

void
psAWGstashSamples(uint32_t *samples, unsigned int base, unsigned int count)
{
    if (debugFlags & DEBUGFLAG_AWG) {
        int i;
        printf("AWG %d@%d", count, base);
        for (i = 0 ; i < 6 && i < count ; i++) {
            printf(" %08X", samples[i]);
        }
        printf("\n");
    }
    if ((base < GPIO_AWG_CAPACITY) && (base <= (GPIO_AWG_CAPACITY - count))) {
        while (count--) {
            GPIO_WRITE(GPIO_IDX_AWG_ADDRESS, base);
            GPIO_WRITE(GPIO_IDX_AWG_DATA, *samples);
            base++;
            samples++;
        }
    }
}

static void
psAWGsetTriggerEvent(int eventNumber)
{
    static unsigned int oldEventNumber;

    if (oldEventNumber) {
        evrRemoveEventAction(oldEventNumber, EVR_RAM_TRIGGER_2);
        oldEventNumber = 0;
    }
    if ((eventNumber > 0) && (eventNumber < 256)) {
        evrAddEventAction(eventNumber, EVR_RAM_TRIGGER_2);
        oldEventNumber = eventNumber;
    }
}

int
psAWGcommand(int addrIdx, uint32_t value)
{
    uint32_t csr = GPIO_READ(GPIO_IDX_AWG_CSR);

    if (debugFlags & DEBUGFLAG_AWG)
        printf("AWG IDX:0x%x  v:%04X:%04X  CSR:%04X:%04X\n", addrIdx,
                                                   value >> 16, value & 0xFFFF,
                                                   csr >> 16, csr & 0xFFFF);
    switch (addrIdx) {
    case CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_ENABLE:
        if (value)
            csr |= CSR_AWG_ENABLE;
        else
            csr &= ~CSR_AWG_ENABLE;
        break;

    case CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_SOFT_TRIGGER:
        csr |= CSR_AWG_SOFT_TRIGGER;
        break;

    case CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_CONTROL:
        csr &= ~CSR_AWG_MODE_MASK;
        csr |= (value << CSR_AWG_MODE_SHIFT) & CSR_AWG_MODE_MASK;
        break;

    case CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_INTERVAL:
        if (value == 0) {
            csr |= CSR_AWG_USE_FA_MARKER;
        }
        else {
            if (value < MINIMUM_INTERVAL) value = MINIMUM_INTERVAL;
            else if (value > MAXIMUM_INTERVAL) value = MAXIMUM_INTERVAL;
            csr &= ~(CSR_AWG_USE_FA_MARKER | CSR_AWG_INTERVAL_MASK);
            csr |= value - 2;
        }
        break;

    case CC_PROTOCOL_CMD_LONGOUT_IDX_AWG_EVENT:
        psAWGsetTriggerEvent(value);
        return 1;

    default: return 0;
    }
    if (debugFlags & DEBUGFLAG_AWG) {
        printf("AWG CSR:%04X:%04X\n", csr >> 16, csr & 0xFFFF);
    }
    GPIO_WRITE(GPIO_IDX_AWG_CSR, csr);
    if (debugFlags & DEBUGFLAG_AWG) {
        microsecondSpin(1);
        csr = GPIO_READ(GPIO_IDX_AWG_CSR);
        printf("AWG CSR:%04X:%04X\n", csr >> 16, csr & 0xFFFF);
    }
    return 1;
}
