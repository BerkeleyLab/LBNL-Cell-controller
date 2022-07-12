/*
 * Power supply waveform recorder
 */
#include <stdio.h>
#include "cellControllerProtocol.h"
#include "evr.h"
#include "gpio.h"
#include "psWaveformRecorder.h"
#include "util.h"

#if ((GPIO_RECORDER_CAPACITY & (GPIO_RECORDER_CAPACITY - 1)) != 0)
# error "GPIO_RECORDER_CAPACITY must be a power of 2"
#endif

#define CSR_W_ARM            0x80000000
#define CSR_W_ARM_ENABLE     0x40000000
#define CSR_W_CLEAR_FULL     0x20000000
#define CSR_W_SOFT_TRIGGER   0x10000000
#define CSR_R_FULL           0x80000000
#define CSR_R_STATE_MASK     0x30000000
# define STATE_IDLE           0
#define CSR_R_WATCHDOG_SHIFT 8
#define CSR_R_WATCHDOG_MASK  (0x3FFF<<CSR_R_WATCHDOG_SHIFT)
#define CSR_CHAN_COUNT_MASK  0x0000003F

static uint32_t activeChannelBitmap;
static int acqActiveChannelCount;
static int pretriggerCount, acqPretriggerCount;
static int posttriggerCount, acqPosttriggerCount;

void
psRecorderArm(int enable)
{
    uint32_t csr = CSR_W_ARM_ENABLE;
    if (enable) {
        uint32_t bitmap = activeChannelBitmap;
        int activeChannelCount = 0;
        int sampleCapacity;

        while (bitmap) {    /* Kernighan's algorithm for counting ones */
            bitmap &= (bitmap - 1);
            activeChannelCount++;
        }
        if (activeChannelCount == 0) {
            activeChannelBitmap = 1;
            activeChannelCount = 1;
        }
        sampleCapacity = GPIO_RECORDER_CAPACITY / activeChannelCount;
        if (pretriggerCount <= 0) {
            pretriggerCount = 1;
        }
        if (posttriggerCount <= 0) {
            posttriggerCount = 1;
        }
        if ((pretriggerCount > sampleCapacity)
         || (posttriggerCount > sampleCapacity)
         || ((pretriggerCount + posttriggerCount) > sampleCapacity)) {
            pretriggerCount = sampleCapacity / 2;
            posttriggerCount = sampleCapacity - pretriggerCount;
        }
        GPIO_WRITE(GPIO_IDX_WFR_W_CHANNEL_BITMAP, activeChannelBitmap);
        GPIO_WRITE(GPIO_IDX_WFR_W_PRETRIGGER, pretriggerCount - 2);
        GPIO_WRITE(GPIO_IDX_WFR_W_POSTTRIGGER, posttriggerCount - 2);
        if (debugFlags & DEBUGFLAG_PS_WAVEFORM_RECORDER) {
            printf("Bitmap:0x%x count:%d pre:%d post:%d\n", activeChannelBitmap,
                         activeChannelCount, pretriggerCount, posttriggerCount);
        }
        acqActiveChannelCount = activeChannelCount;
        acqPretriggerCount = pretriggerCount;
        acqPosttriggerCount = posttriggerCount;
        csr |= CSR_W_ARM | activeChannelCount;
    }
    GPIO_WRITE(GPIO_IDX_WFR_CSR, csr);
}

int
psRecorderFetch(uint32_t *buf, int capacity, int channel, int offset)
{
    int dataIdx = (channel==0)?GPIO_IDX_WFR_R_TX_DATA:GPIO_IDX_WFR_R_RX_DATA;
    uint32_t csr = GPIO_READ(GPIO_IDX_WFR_CSR);
    int triggerLocation = GPIO_READ(GPIO_IDX_WFR_ADDRESS);
    int dataCount = (acqPretriggerCount + acqPosttriggerCount) * acqActiveChannelCount;
    int n = 0;

    if (((csr & CSR_R_STATE_MASK) == STATE_IDLE) && (capacity >= 3)) {
        if (offset == 0) {
            GPIO_WRITE(GPIO_IDX_WFR_CSR, CSR_W_CLEAR_FULL);
            *buf++ = GPIO_READ(GPIO_IDX_WFR_R_SECONDS);
            *buf++ = GPIO_READ(GPIO_IDX_WFR_R_TICKS);
            n = 2;
            if ((debugFlags & DEBUGFLAG_PS_WAVEFORM_RECORDER) && (channel==0)) {
                printf("Trigger location %d, data count %d, time %u:%u\n", 
                                  triggerLocation, dataCount, buf[-2], buf[-1]);
            }
        }
        while ((n < capacity) && (offset < dataCount)) {
            uint32_t v;
            int dataLocation = (triggerLocation + offset +
                                GPIO_RECORDER_CAPACITY -
                                (acqPretriggerCount * acqActiveChannelCount)) %
                                                         GPIO_RECORDER_CAPACITY;
            GPIO_WRITE(GPIO_IDX_WFR_ADDRESS, dataLocation);
            v = GPIO_READ(dataIdx);
            if ((debugFlags & DEBUGFLAG_PS_WAVEFORM_RECORDER) && (offset < 20)) {
                printf("C%d[%d]@%d: 0x%8.8X\n", channel, offset, dataLocation, v);
            }
            *buf++ = v;
            offset++;
            n++;
        }
    }
    return n;
}

void
psRecorderSetChannelMask(unsigned int bitmap)
{
    activeChannelBitmap = bitmap;
}

void
psRecorderSetPretriggerCount(int n)
{
    pretriggerCount = n;
}

void
psRecorderSetPosttriggerCount(int n)
{
    posttriggerCount = n;
}

void
psRecorderSoftTrigger(void)
{
    GPIO_WRITE(GPIO_IDX_WFR_CSR, CSR_W_SOFT_TRIGGER);
}

void
psRecorderSetTriggerEvent(int n)
{
    static unsigned int oldEventNumber;
    if (oldEventNumber) {
        evrRemoveEventAction(oldEventNumber, EVR_RAM_TRIGGER_3);
        oldEventNumber = 0;
    }
    if ((n > 0) && (n < 256)) {
        evrAddEventAction(n, EVR_RAM_TRIGGER_3);
        oldEventNumber = n;
    }
}
