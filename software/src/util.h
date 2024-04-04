/*
 * Utility routines
 */

#ifndef _UTIL_H_
#define _UTIL_H_

/*
 * UDP port
 */
extern int udpEPICS;

/*
 * Allow code to refer  to printf without actually pulling it in
 */
#define printf(...) xil_printf(__VA_ARGS__)

/*
 * Diagnostics
 */
#define DEBUGFLAG_EPICS                     0x1
#define DEBUGFLAG_AWG                       0x2
#define DEBUGFLAG_PS_WAVEFORM_RECORDER      0x4
#define DEBUGFLAG_SETPOINTS                 0x10
#define DEBUGFLAG_EEBI_CONFIG               0x20
#define DEBUGFLAG_SHOW_FREQUENCY_COUNTERS   0x1000
#define DEBUGFLAG_SHOW_PS_SETPOINTS         0x4000
#define DEBUGFLAG_BRINGUP_PS_LINKS          0x8000
#define DEBUGFLAG_RESET_EEBI_INTERLOCK      0x800000
extern int debugFlags;

void fatal(const char *fmt, ...);
void warn(const char *fmt, ...);
void microsecondSpin(unsigned int us);
void uintPrint(unsigned int n);
void showReg(int i);

#endif /* _UTIL_H_ */
