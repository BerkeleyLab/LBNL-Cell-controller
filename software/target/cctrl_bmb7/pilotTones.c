/*
 * Communicate with pilot tone generator devices
 */

#include <stdio.h>
#include <stdint.h>
#include "fastFeedback.h"
#include "gpio.h"
#include "pilotTones.h"
#include "util.h"

/*
 * 7 bit I2C addresses
 */
#define TCA6416_ADDRESS     0x21
#define ADT7410_ADDRESS     0x48
#define AD9520A_ADDRESS     0x58
#define AD9520B_ADDRESS     0x59
#define LTC2945A_ADDRESS    0x6B
#define LTC2945B_ADDRESS    0x6E

#define ADT7410_TCHAN  0x00
#define ADT7410_CONFIG 0x03
#define LTC2945_CSR    0x00
#define LTC2945_ICHAN  0x14
#define LTC2945_VCHAN  0x1E
#define LTC2945_ADCHAN 0x28

#define WR_CSR(v) GPIO_WRITE(GPIO_IDX_PILOT_TONE_I2C,(v))
#define RD_CSR() GPIO_READ(GPIO_IDX_PILOT_TONE_I2C)

#define COMMAND_ADDRESS_SHIFT   25
#define COMMAND_ADDRESS_MASK    0xFE000000
#define COMMAND_READBACK      0x1000000

#define CSR_R_BUSY         0x80000000
#define CSR_R_AD9520_VALUE_MASK  0xFF

#define WRITE_QUEUE_SIZE    1024
static uint32_t ioRequests[WRITE_QUEUE_SIZE];
static unsigned int ioQueueHead, ioQueueTail;

/*
 * Queue a request to write to a pilot tone generator device
 * Blocks if necessary!
 */
static void
queue(uint32_t command)
{
    unsigned int nextIoQueueHead = (ioQueueHead + 1) % WRITE_QUEUE_SIZE;

    while (nextIoQueueHead == ioQueueTail) {
        ptCrank();
    }
    ioRequests[ioQueueHead] = command;
    ioQueueHead = nextIoQueueHead;
}

static void
queueWriteRequest(int deviceAddress, int registerAddress, int value)
{
    uint32_t command;

    if ((deviceAddress & 0x70) == (AD9520A_ADDRESS & 0x70)) {
        command = (deviceAddress << COMMAND_ADDRESS_SHIFT) |
                  ((value << 16) & 0xFF0000)               |
                  ((registerAddress << 8) & 0xFF00)        |
                  ((registerAddress >> 8) & 0x000F);
    }
    else {
        command = (deviceAddress << COMMAND_ADDRESS_SHIFT) |
                  ((value << 8) & 0xFFFF00)                |
                  (registerAddress & 0xFF);
    }
    queue(command);
}

static void
queueReadRequest(int deviceAddress, int registerAddress)
{
    uint32_t command;

    if ((deviceAddress & 0x70) == (AD9520A_ADDRESS & 0x70)) {
        command = (deviceAddress << COMMAND_ADDRESS_SHIFT) |
                  COMMAND_READBACK                         |
                  ((registerAddress << 8) & 0xFF00)        |
                  ((registerAddress >> 8) & 0x00FF);
    }
    else {
        command = (deviceAddress << COMMAND_ADDRESS_SHIFT) |
                  COMMAND_READBACK                         |
                  (registerAddress & 0xFF);
    }
    queue(command);
}

static void
queuePLLscan(int pllAddress)
{
    int i;

    queueReadRequest(pllAddress, 0x1F); // Read lock detect status
    for (i = 0 ; i < 12 ; i++)
        queueReadRequest(pllAddress, 0xF0+i); // Read output control detect status
}

/*
 * Initiate a readback monitor scan
 */
static void
scanReadbacks(void)
{
    queueReadRequest(LTC2945A_ADDRESS, LTC2945_CSR);
    queueReadRequest(LTC2945B_ADDRESS, LTC2945_CSR);
    queueReadRequest(LTC2945A_ADDRESS, LTC2945_VCHAN);
    queueReadRequest(LTC2945A_ADDRESS, LTC2945_ICHAN);
    queueReadRequest(LTC2945A_ADDRESS, LTC2945_ADCHAN);
    queueReadRequest(LTC2945B_ADDRESS, LTC2945_VCHAN);
    queueReadRequest(LTC2945B_ADDRESS, LTC2945_ICHAN);
    queueReadRequest(LTC2945B_ADDRESS, LTC2945_ADCHAN);
    queueReadRequest(ADT7410_ADDRESS, ADT7410_TCHAN);
    queuePLLscan(AD9520B_ADDRESS);
    queuePLLscan(AD9520A_ADDRESS);
}

/*
 * Save a power monitor readback
 */
static uint16_t ltc2945[PILOT_TONE_ADC_COUNT];
static void
stashLTC2945(int idx, uint32_t csr)
{
    ltc2945[idx] = ((csr << 8) & 0xFF00) | ((csr >> 8) & 0xFF);
}

/*
 * Get most recent power monitor ADC reading
 */
unsigned int
ptADC(int idx)
{
    if ((unsigned int)idx >= PILOT_TONE_ADC_COUNT) return 0;
    return ltc2945[idx];
}

/*
 * Configure power monitor if necessary
 */
static void
checkLTC2945(uint32_t command, uint32_t csr)
{
    if ((csr & 0xFF) != 0x5) {
        int devAddr = (command & COMMAND_ADDRESS_MASK) >> COMMAND_ADDRESS_SHIFT;
        static int errorCount;
        if (errorCount < 10) {
            printf("LTC2945 %2.2X -- CSR:%2.2X\n", devAddr, csr & 0xFF);
            errorCount++;
        }
        queueWriteRequest(devAddr, LTC2945_CSR, 0x05);
        /*
         * We can't read back the 8-bit control register from the
         * ADT7410 to see if it needs to be written, so just keep
         * hitting it every time that we see that the LTC2945 needs
         * to be configured.
         */
        queueWriteRequest(ADT7410_ADDRESS, ADT7410_CONFIG, 0x80);
    }
}

/*
 * Save a temperature monitor readback
 */
static uint16_t adt7410[PILOT_TONE_TEMPERATURE_COUNT];
static void
stashADT7410(int idx, uint32_t csr)
{
    adt7410[idx] = ((csr << 8) & 0xFF00) | ((csr >> 8) & 0xFF);
}

/*
 * Get most recent temperature reading
 */
unsigned int
ptTemperature(int idx)
{
    if ((unsigned int)idx >= PILOT_TONE_TEMPERATURE_COUNT) return 0;
    return adt7410[idx];
}

/*
 * Save a PLL reading
 */
static uint8_t ad9520[2][PILOT_TONE_PLL_VALUE_COUNT];
static void
stashAD9520(uint32_t command, uint32_t csr)
{
    int pll;
    int reg;
    int idx;

    switch ((command & COMMAND_ADDRESS_MASK) >> COMMAND_ADDRESS_SHIFT) {
    case AD9520A_ADDRESS: pll = 0; break;
    case AD9520B_ADDRESS: pll = 1; break;
    default: return;
    }
    reg = ((command << 8) & 0xFF00) | ((command >> 8) & 0x00FF);
    if (reg == 0x1F) idx = PILOT_TONE_PLL_OUTPUT_COUNT;
    else if ((reg >= 0xF0)
          && (reg < (0xF0 + PILOT_TONE_PLL_OUTPUT_COUNT))) idx = reg - 0xF0;
    else return;
    ad9520[pll][idx] = csr & CSR_R_AD9520_VALUE_MASK;
}

/*
 * Get a PLL reading
 */
unsigned int
ptPLLvalue(int pllIndex, int idx)
{
    if (((unsigned int)pllIndex >= 2)
     || ((unsigned int)idx >= PILOT_TONE_PLL_VALUE_COUNT)) return 0;
    return ad9520[pllIndex][idx];
}

/*
 * Write a PLL register
 */
static void
ptPLLwrite(int pllIndex, int registerAddress, int value)
{
    int address = pllIndex ? AD9520B_ADDRESS : AD9520A_ADDRESS;
    queueWriteRequest(address, registerAddress, value);
    queueWriteRequest(address, 0x232, 1);
}

void
ptPLLoutputControl(int pllIndex, int outputIndex, int value)
{
    if ((unsigned int)outputIndex >= PILOT_TONE_PLL_OUTPUT_COUNT) return;
    switch(value) {
    default:    value = 0x01;   break;  // Output off
    case 1:     value = 0xF0;   break;  // CMOS, A noniverting, B inverting
    case 2:     value = 0x06;   break;  // LVPECL, 960 mV, A noninverting
    case 3:     value = 0x04;   break;  // LVPECL, 780 mV, A noninverting
    case 4:     value = 0x02;   break;  // LVPECL, 600 mV, A noninverting
    case 5:     value = 0x00;   break;  // LVPECL, 400 mV, A noninverting
    }
    ptPLLwrite(pllIndex, 0xF0 + outputIndex, value);
}

/*
 * Attenuator control
 * Sending the values takes quite a while so ensure
 * that transfers are separated by at least 100 ms.
 */
static uint8_t attenuators[PILOT_TONE_PLL_OUTPUT_COUNT];
static int attenFlushNeeded;
void
ptAttenWrite(int attnIndex, int value)
{
    if ((unsigned int)attnIndex >= PILOT_TONE_PLL_OUTPUT_COUNT)
        return;
    attenuators[attnIndex] = value;
    attenFlushNeeded = 1;
}

static void
attenFlush(void)
{
    int i, j, d;
    static int firstTime = 1;

    if (firstTime) {
        /* Set all lines as non-inverted outputs */
        queueWriteRequest(TCA6416_ADDRESS, 0x4, 0x0000);
        queueWriteRequest(TCA6416_ADDRESS, 0x6, 0x0000);
        firstTime = 0;
    }
    for (i = 0 ; i < 16 ; i++) {
        d = 0x2000;  // PLL Sync Line High
        if (i <= 7) {
            for (j = 0 ; j < PILOT_TONE_PLL_OUTPUT_COUNT ; j++) {
                if (attenuators[j] & (1 << i)) {
                    d |= (1 << j);
                }
            }
        }
        queueWriteRequest(TCA6416_ADDRESS, 0x2, d);
        queueWriteRequest(TCA6416_ADDRESS, 0x2, 0x8000 | d);
    }
    queueWriteRequest(TCA6416_ADDRESS, 0x2, 0x2000);
    queueWriteRequest(TCA6416_ADDRESS, 0x2, 0x6000);
    queueWriteRequest(TCA6416_ADDRESS, 0x2, 0x2000);
    attenFlushNeeded = 0;
}

/*
 * Finish off I/O transaction
 */
static int
checkStatus(void)
{
    uint32_t csr = RD_CSR();
    static uint32_t activeCommand;

    /*
     * Bail out if transaction is still active
     */
    if (csr & CSR_R_BUSY) return 1;

    /*
     * Transaction complete.  Handle readbacks
     */
    if (activeCommand & COMMAND_READBACK) {
      switch(activeCommand & ~COMMAND_READBACK) {
      case (LTC2945A_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_CSR:
      case (LTC2945B_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_CSR:
        checkLTC2945(activeCommand, csr);
        break;
      case (LTC2945A_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_VCHAN:
        stashLTC2945(0, csr);
        break;
      case (LTC2945A_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_ICHAN:
        stashLTC2945(1, csr);
        break;
      case (LTC2945B_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_VCHAN:
        stashLTC2945(2, csr);
        break;
      case (LTC2945B_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_ICHAN:
        stashLTC2945(3, csr);
        break;
      case (LTC2945A_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_ADCHAN:
        stashLTC2945(4, csr);
        break;
      case (LTC2945B_ADDRESS<<COMMAND_ADDRESS_SHIFT) | LTC2945_ADCHAN:
        stashLTC2945(5, csr);
        break;
      case (ADT7410_ADDRESS<<COMMAND_ADDRESS_SHIFT) | ADT7410_TCHAN:
        stashADT7410(0, csr);
        break;
      default:
        stashAD9520(activeCommand, csr);
        break;
      }
    }

    /*
     * Send next command if one pending
     */
    if (ioQueueTail == ioQueueHead) {
        activeCommand = 0;
        return 0;
    }
    activeCommand = ioRequests[ioQueueTail];
    WR_CSR(activeCommand);
    ioQueueTail = (ioQueueTail + 1) % WRITE_QUEUE_SIZE;
    return 1;
}

/*
 * Crank the I/O state machine
 */
void
ptCrank(void)
{
    uint32_t now = MICROSECONDS_SINCE_BOOT();
    static uint32_t whenReadbacksScanned, whenAttenFlushed;

    /*
     * Perform timed operations
     */
    if ((now - whenReadbacksScanned) >= 500000) {
        whenReadbacksScanned = now;
        scanReadbacks();
    }
    else if (attenFlushNeeded && ((now - whenAttenFlushed) > 100000)) {
        whenAttenFlushed = now;
        attenFlush();
    }
    checkStatus();
}

/*
 * Write an AD9520 register
 */
static void
ptAD9520set(int pllIndex, unsigned int reg, int value)
{
    queueWriteRequest(pllIndex ? AD9520B_ADDRESS : AD9520A_ADDRESS, reg, value);
}

/*
 * Read an AD9520 register
 * This routine busy-waits, but does try to keep fast feedback active.
 */
static int
ptAD9520get(int pllIndex, unsigned int registerAddress)
{
    uint32_t csr;
    int deviceAddress = pllIndex ? AD9520B_ADDRESS : AD9520A_ADDRESS;
    uint32_t command = (deviceAddress << COMMAND_ADDRESS_SHIFT) |
                        COMMAND_READBACK                        |
                        ((registerAddress << 8) & 0xFF00)       |
                        ((registerAddress >> 8) & 0x3);

    /*
     * Wait for outstanding transactions to complete
     */
    while (checkStatus()) continue;

    /*
     * Send high bits of register number first, then low bits
     */
    WR_CSR(command);
    while ((csr = RD_CSR()) & CSR_R_BUSY) continue;
    return csr & CSR_R_AD9520_VALUE_MASK;
}

void
ad9520show(void)
{
    int pllIndex;
    int r;
    int v;

    printf("Pilot tone PLL (AD9520) configuration:\n");
    printf("Reg   LO  HI\n");
    for (r = 0 ; r <= 0x232 ; r++) {
        if (((r >= 0x001) && (r <= 0x002))
         || ((r >= 0x007) && (r <= 0x00F))
         || ((r >= 0x020) && (r <= 0x0EF))
         || ((r >= 0x0FE) && (r <= 0x18F))
         || ((r >= 0x19C) && (r <= 0x1DF))
         || ((r >= 0x1E2) && (r <= 0x22F))
         || (r == 0x231))
            continue;
        printf("%03X:", r);
        for (pllIndex = 0 ; pllIndex < 2 ; pllIndex++) {
            v = ptAD9520get(pllIndex, r);
            printf("  %02X", v);
        }
        printf("\n");
    }
}

int
ad9520RegIO(int idx, unsigned int value)
{
    static int pllIndex, registerIndex;

    if (idx) {
        ptAD9520set(pllIndex, registerIndex, value);
    }
    else {
        pllIndex = value >> 12;
        registerIndex = value & 0xFFF;
        value = ptAD9520get(pllIndex, registerIndex);
    }
    return value;
}

static int currentTable[2];
static void
ad9520Table(int init, int pllIndex, int tableIndex)
{
    int i, regCount, reg0x018 = 0;
    const uint16_t *sp;
    #include "ad9520Tables.h"
    static const struct ptTables {
        const uint16_t *table;
        int             size;
    } ptTables[] = { { pt0table, sizeof pt0table },
                     { pt1table, sizeof pt1table },
                     { pt2table, sizeof pt2table },
                     { pt3table, sizeof pt3table },
                     { pt4table, sizeof pt4table },
                     { pt5table, sizeof pt5table },
                     { pt6table, sizeof pt6table } };

    if ((pllIndex < 0)
     || (pllIndex > 1)
     || (tableIndex < 0)
     || (tableIndex >= sizeof ptTables/sizeof ptTables[0])) return;

    /*
     * Load registers
     */
    if (init || (currentTable[pllIndex] != tableIndex)) {
        sp = ptTables[tableIndex].table;
        regCount = ptTables[tableIndex].size / (2 * sizeof(*sp));
        currentTable[pllIndex] = tableIndex;
        for (i = 0 ; i < regCount ; i++) {
            int reg = *sp++;
            int value = *sp++;
            if (reg == 0x018) {
                /*
                 * VCO calibration requires a 0->1 transition
                 * of the least-signficant bit of this register
                 * so make sure it's a 0 here
                 */
                value &= ~0x01;
                reg0x018 = value;
            }
            ptAD9520set(pllIndex, reg, value);
        }
        if (init) {
            for (i = 0 ; i < PILOT_TONE_PLL_OUTPUT_COUNT ; i++) {
                ptAD9520set(pllIndex, 0xF0+i, 0x98); // CMOS, Tri-state
            }
        }
        ptAD9520set(pllIndex, 0x232, 0x01);

        /*
         * If PLL is active:
         *   Set reference clock.
         *   Perform VCO calibration.
         *   Pulse SYNC line.
         */
        if (tableIndex != 0) {
            if (tableIndex >= 4) {
                setPilotToneReference(6232);
            }
            else {
                setPilotToneReference(656);
            }
            ptAD9520set(pllIndex, 0x18, reg0x018 | 0x01);
            ptAD9520set(pllIndex, 0x232, 0x01);
            microsecondSpin(1000);
            ptSync();
        }
    }

}

/*
 * Change table on IOC request
 */
void
ad9520SetTable(int pllIndex, int tableIndex)
{
    ad9520Table(0, pllIndex, tableIndex);
}

/*
 * Return active table index
 */
unsigned int
ptPLLtable(int pllIndex)
{
    if ((pllIndex < 0) || (pllIndex > 1)) return 0;
    return currentTable[pllIndex];
}

/*
 * Write to MAX5802 DAC
 */
void
max5802write(int select, int value) {
    queueWriteRequest(0x0E, 0x75, 0); // Vref = 2.5V, always ON
    queueWriteRequest(0x0E, 0x30 | (select & 0xF), value);
}

/*
 * Set pilot tone reference clock
 */
#define PT_CSR_ENABLE_DIRECT 0x80000000
int
setPilotToneReference(int rfClockDivider)
{
    uint32_t csr;
    int loCount, hiCount;

    csr = GPIO_READ(GPIO_IDX_PILOT_TONE_REFERENCE);
    if ((rfClockDivider > 0) && ((rfClockDivider % 4) == 0)) {
        int evrClockDivider = rfClockDivider / 4;
        hiCount = evrClockDivider / 2;
        loCount = evrClockDivider - hiCount;
        if ((((hiCount != 0) && (loCount!= 0)) || (csr & PT_CSR_ENABLE_DIRECT))
         && (hiCount < 1024)
         && (loCount < 1024)) {
            GPIO_WRITE(GPIO_IDX_PILOT_TONE_REFERENCE,((hiCount<<10)|loCount));
        }
    }
    csr = GPIO_READ(GPIO_IDX_PILOT_TONE_REFERENCE);
    loCount = csr & 0x3FF;
    hiCount = (csr >> 10) & 0x3FF;
    if ((loCount == 0) || (hiCount == 0)) {
        loCount = 1;
        hiCount = 0;
    }
    return (loCount + hiCount) * 4;
}

/*
 * Initialize pilot tone generator devices on startup
 */
void
ptInit(void)
{
    int i;

    for (i = 0 ; i < PILOT_TONE_PLL_OUTPUT_COUNT ; i++) {
        ptAttenWrite(i, 0x7F);
    }
    ad9520Table(1, 0, 0);
    ad9520Table(1, 1, 0);
    queueWriteRequest(ADT7410_ADDRESS, ADT7410_CONFIG, 0x80);
}

/*
 * Pulse pilot tone PLL SYNC line low
 */
void
ptSync(void)
{
    queueWriteRequest(TCA6416_ADDRESS, 0x2, 0x0000);
    queueWriteRequest(TCA6416_ADDRESS, 0x2, 0x2000);
}
