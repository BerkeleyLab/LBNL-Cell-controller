/*
 * Communicate with pilot tone generator devices
 */

#ifndef _PILOT_TONE_I2C_H_
#define _PILOT_TONE_I2C_H_

#define PILOT_TONE_TEMPERATURE_COUNT 1
#define PILOT_TONE_ADC_COUNT         6
#define PILOT_TONE_PLL_OUTPUT_COUNT  12
#define PILOT_TONE_PLL_VALUE_COUNT   (PILOT_TONE_PLL_OUTPUT_COUNT+1)

void ptInit(void);
int setPilotToneReference(int rfClockDivider);
void ptCrank(void);
void ptSync(void);

unsigned int ptADC(int idx);
unsigned int ptTemperature(int idx);
unsigned int ptPLLvalue(int pllIndex, int idx);
unsigned int ptPLLtable(int pllIndex);

void ptPLLoutputControl(int pllIndex, int outputIndex, int value);
void ptAttenWrite(int attnIndex, int value);

void ad9520init(void);
void ad9520SetTable(int pllIndex, int tableIndex);
void ad9520show(void);
int ad9520RegIO(int idx, unsigned int value);

void max5802write(int select, int value);


#endif /* _PILOT_TONE_I2C_H_ */
