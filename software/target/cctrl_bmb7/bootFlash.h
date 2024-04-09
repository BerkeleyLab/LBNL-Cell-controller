/*
 * Bootstrap flash memory
 */

#ifndef _BOOT_FLASH_H_
#define _BOOT_FLASH_H_

#include <stdint.h>

void bootFlashInit(void);
int bootFlashRead(uint32_t address, uint32_t length, void *buf);
int bootFlashWrite(uint32_t address, uint32_t length, const void *buf);

#endif /* _BOOT_FLASH_H_ */
