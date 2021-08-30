/*
 * Deal with front panel/interlock devices
 */

#ifndef _FRONT_PANEL_H_
#define _FRONT_PANEL_H_

#define FRONT_PANEL_TEMPERATURE_COUNT 1
#define FRONT_PANEL_ADC_COUNT         6

int fpModuleRelayStatus(void);
void fpModuleRelayControl(int enable);

#endif /* _FRONT_PANEL_H_ */
