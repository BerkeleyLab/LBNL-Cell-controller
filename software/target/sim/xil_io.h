// A fake xil_io.h for simulation
#ifndef _XIL_IO_H_
#define _XIL_IO_H_

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <stdio.h>

uint32_t Xil_In32(uint32_t addrEnc);
void Xil_Out32(uint32_t addrEnc, uint32_t val);

#define xil_printf  printf

#ifdef __cplusplus
}
#endif

#endif /* _XIL_IO_H_ */
