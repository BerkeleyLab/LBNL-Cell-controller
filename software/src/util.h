/*
 * Utility routines
 */

#ifndef _UTIL_H_
#define _UTIL_H_

#define MiB(x) ((x)*1024*1024)
#define KiB(x) ((x)*1024)

#define FLASH_BITSTREAM_A_OFFSET       0 // in MiB
#define FLASH_BITSTREAM_B_OFFSET       8 // in MiB

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
#define DEBUGFLAG_TFTP                      0x40
#define DEBUGFLAG_IIC_PROC                  0x800
#define DEBUGFLAG_SHOW_FREQUENCY_COUNTERS   0x1000
#define DEBUGFLAG_SHOW_PS_SETPOINTS         0x4000
#define DEBUGFLAG_BRINGUP_PS_LINKS          0x8000
#define DEBUGFLAG_IIC_SCAN                  0x10000
#define DEBUGFLAG_SHOW_MGT_RESETS           0x20000
#define DEBUGFLAG_SHOW_RX_ALIGNER           0x40000
#define DEBUGFLAG_SI570_SETTING             0x80000
#define DEBUGFLAG_SHOW_MGT_SWITCH           0x1000000
#define DEBUGFLAG_DUMP_MGT_SWITCH           0x2000000
extern int debugFlags;

void fatal(const char *fmt, ...);
void warn(const char *fmt, ...);
void microsecondSpin(unsigned int us);
void uintPrint(unsigned int n);
void showReg(int i);
void resetFPGA(int bootAlternateImage);
void printDebugFlags();

#define ARRAY_SIZE(array) (sizeof(array) / sizeof(array[0]))

#endif /* _UTIL_H_ */
