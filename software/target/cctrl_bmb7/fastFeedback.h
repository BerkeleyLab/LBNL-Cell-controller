#ifndef _FAST_FEEDBACK_H_
#define _FAST_FEEDBACK_H_

int  ffbStashSetpoints(int count, const uint32_t *setpointArgs, int cellInfo);
int  ffbStashFOFBlist(int count, const uint32_t *bpmList);
void ffbSetPsBitmap(uint32_t bitmap);
unsigned int ffbReadoutTime(void);
int          auroraReadoutCount(int link);
int          ffbCellIndex(void);
int          ffbCellCount(void);
int          ffbCellBPMcount(void);
int          ffbReadoutIsValid(void);
void         bpmInhibit(int inhibitFlags);
void         cellInhibit(int inhibitFlags);
void         ffbShowPowerSupplySetpoints(void);
void         showFOFB(int first, int n);

#endif /* _FAST_FEEDBACK_H_ */
