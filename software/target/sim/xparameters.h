// A fake xparameters.h for simulation
#ifndef _XPARAMETERS_H_
#define _XPARAMETERS_H_

#ifdef __cplusplus
extern "C" {
#endif

#define XPAR_EPICS_UDP_BASEADDR 0x44A00000
#define XPAR_AURORA_DRP_BRIDGE_0_BASEADDR 0x44A10000
#define XPAR_AXI_LITE_GENERIC_REG_BASEADDR 0x44A30000
#define XPAR_EVR_AXI_0_BASEADDR 0x44A40000
#define XPAR_XADC_WIZ_0_BASEADDR 0x44A50000U
#define XPAR_BRAM_BPM_SETPOINTS_S_AXI_BASEADDR 0xC0000000U

#define XPAR_CPU_CORE_CLOCK_FREQ_HZ 100000000

#ifdef __cplusplus
}
#endif

#endif /* _XPARAMETERS_H_ */
