#ifndef _GPIO_VTB_H_
#define _GPIO_VTB_H_

uint32_t vtb_In32(uint32_t addr);
void vtb_Out32(uint32_t val);

#define GPIO_READ(i)    vtb_In32(4*(i))
#define GPIO_WRITE(i,x) vtb_Out32((x))

#endif // _GPIO_VTB_H_
