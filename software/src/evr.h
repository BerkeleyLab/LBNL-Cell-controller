/*
 * Embedded Event Receiver support
 */

#ifndef _EVR_H_
#define _EVR_H_

#include <stdint.h>

#define EVR_EVENT_COUNT     255
#define EVR_TRIGGER_COUNT   8

#define EVR_STATUS_UNLOCKED 0x8000

#define EVR_RAM_TRIGGER_0   0x1
#define EVR_RAM_TRIGGER_1   0x2
#define EVR_RAM_TRIGGER_2   0x4
#define EVR_RAM_TRIGGER_3   0x8
#define EVR_RAM_TRIGGER_4   0x10
#define EVR_RAM_TRIGGER_5   0x20
#define EVR_RAM_TRIGGER_6   0x40
#define EVR_RAM_TRIGGER_7   0x80
#define EVR_RAM_WRITE_FIFO  0x2000
#define EVR_RAM_LATCH_TIME  0x4000
#define EVR_RAM_ASSERT_IRQ  0x4800

typedef struct evrTimestamp {
    uint32_t secPastEpoch;
    uint32_t ticks;
} evrTimestamp;

void evrInit(void);
void evrShow(void);

uint32_t evrStatus(void);
void evrCurrentTime(evrTimestamp *);
uint32_t evrSecondsAtBoot(void);

void evrSetTriggerDelay(unsigned int triggerNumber, int ticks);
int  evrGetTriggerDelay(unsigned int triggerNumber);
void evrSetTriggerWidth(unsigned int triggerNumber, int ticks);

void evrSetEventAction(unsigned int eventNumber, int action);
void evrAddEventAction(unsigned int eventNumber, int action);
void evrRemoveEventAction(unsigned int eventNumber, int action);
int  evrGetEventAction(unsigned int eventNumber);

unsigned int evrNoutOfSequenceSeconds(void);
unsigned int evrNtooFewSecondEvents(void);
unsigned int evrNtooManySecondEvents(void);

void drp_evr_write(uint32_t csrIdx, int regOffset, int value);
int drp_evr_read(uint32_t csrIdx, int regOffset);

#endif
