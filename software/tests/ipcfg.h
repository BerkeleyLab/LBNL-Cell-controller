#ifndef _IPCFG_H_
#define _IPCFG_H_

#include <stdio.h>
#include <string.h>
#include <stdint.h>

#define UNPACK_IP32(ip32, ip_dest)     do {\
  ip_dest[3] = (ip32 >> 24) & 0xff;\
  ip_dest[2] = (ip32 >> 16) & 0xff;\
  ip_dest[1] = (ip32 >> 8) & 0xff;\
  ip_dest[0] = ip32 & 0xff;\
} while (0)
#define PACK_IP32(ip)       (uint32_t)((ip[3] << 24) | (ip[2] << 16) | (ip[1] << 8) | ip[0])
#define PRINT_IP32(ip32)    printf("%d.%d.%d.%d", ip32 & 0xff, ((ip32 >> 8) & 0xff), ((ip32 >> 16) & 0xff), ((ip32 >> 24) & 0xff));

int getIpPort(const char *inStr, volatile uint32_t *pIp32, volatile uint16_t *pPort,
              uint32_t defaultIp32, uint16_t defaultPort);

#endif // _IPCFG_H_
