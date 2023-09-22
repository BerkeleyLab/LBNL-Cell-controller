/* Common helper tools to get network config params at runtime via argv
 */

#include "ipcfg.h"

int getIpPort(const char *inStr, volatile uint32_t *pIp32, volatile uint16_t *pPort,
              uint32_t defaultIp32, uint16_t defaultPort)
{
  uint8_t ip[4];
  int rc;
  int useDefaultIP = 1;
  int useDefaultPort = 1;
  if (inStr) {
    const char *colon = strchr(inStr, ':');
    if (colon) {
      // Found IP:port
      rc = sscanf(inStr, "%hhu.%hhu.%hhu.%hhu", &ip[0], &ip[1], &ip[2], &ip[3]);
      if (rc == 4) {
        useDefaultIP = 0;
      }
      rc = sscanf(colon+1, "%hu", pPort);
      if (rc > 0) {
        useDefaultPort = 0;
      }
    } else {
      // Try as IP address
      rc = sscanf(inStr, "%hhu.%hhu.%hhu.%hhu", &ip[0], &ip[1], &ip[2], &ip[3]);
      if (rc == 4) {
        useDefaultIP = 0;
      }
      if (useDefaultIP == 1) {
        // Try as port
        rc = sscanf(inStr, "%hu", pPort);
        if (rc > 0) {
          useDefaultPort = 0;
        }
      }
    }
  }
  if (useDefaultIP) {
    *pIp32 = defaultIp32;
  } else {
    *pIp32 = PACK_IP32(ip);
  }
  if (useDefaultPort) {
    *pPort = defaultPort;
  }
  return 0;
}
