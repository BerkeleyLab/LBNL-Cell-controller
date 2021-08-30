/*
 * Power supply waveform recorder
 */
#ifndef _PSRECORDER_H_
#define _PSRECORDER_H_

void psRecorderArm(int enable);
int psRecorderFetch(uint32_t *buf, int capacity, int channel, int offset);
void psRecorderSetChannelMask(unsigned int bitmap);
void psRecorderSetPretriggerCount(int n);
void psRecorderSetPosttriggerCount(int n);
void psRecorderSetTriggerEvent(int n);
void psRecorderSoftTrigger(void);

#endif  /* _PSRECORDER_H_ */

