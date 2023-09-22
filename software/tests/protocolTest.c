/*
 * Cell-Controller protocol test with
 * UDP client
 */

#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>   // For nanosleep()

#include "ipcfg.h"
#include "cellControllerProtocol.h"
#include "xadc.h"
#include "qsfp.h"
#include "pilotTones.h"

//Note: CC_PROTOCOL_ARG_COUNT_TO_SIZE(nargs) returns packet (payload) size in bytes
#define OUTPUT_ALL

// =========================== Private Macros =================================
#define INDENT            ""
#ifdef OUTPUT_ALL
#define PRINTOK(...)      printf(INDENT __VA_ARGS__)
#else
#define PRINTOK(...)
#endif
#define PRINTERR(...)     printf(INDENT "ERROR: " __VA_ARGS__)

const uint8_t defaultIP[] = {127, 0, 0, 1};
#define DEFAULT_PORT        CC_PROTOCOL_UDP_PORT
#define PACK_IP32(ip)       (uint32_t)((ip[3] << 24) | (ip[2] << 16) | (ip[1] << 8) | ip[0])
#define PRINT_IP32(ip32)    printf("%d.%d.%d.%d", ip32 & 0xff, ((ip32 >> 8) & 0xff), ((ip32 >> 16) & 0xff), ((ip32 >> 24) & 0xff));

#define CCPACKET_SIZE     (sizeof(struct ccProtocolPacket)/sizeof(char))
#define EXPECTED_ARGS_SYSMON   ((XADC_CHANNEL_COUNT+1)/2 + QSFP_COUNT*(1 + (QSFP_RX_COUNT+1)/2) + 1 + (PILOT_TONE_ADC_COUNT+1)/2 \
                                + PILOT_TONE_TEMPERATURE_COUNT + 2*(1 + (PILOT_TONE_PLL_OUTPUT_COUNT+1)/2) + 5)
#define XADC_TO_DEGC_DOUBLE(val) (503.975*(double)(val)/(0x10000) - 273.15)


// ====================== Static Function Prototypes ==========================
//static int getIpPort(const char *inStr, uint32_t *pIp32, uint16_t *pPort);
static int buildTestPacket(void *pkt);
static int doTests(void);
static int receiveReply(void);
static void printResponse(int nargs);
static void waitms(int nms);
static int clientInit(unsigned short port, uint32_t ipAddr);
static int argValidatorSYSMON(struct ccProtocolPacket *cpkt, int nargs);

// =========================== Static Variables ===============================
unsigned short udpSendPort = 0;
//unsigned short udpRecvPort = 0;
int udpfd;
int initialized = 0;
struct ccProtocolPacket testPacket;
struct ccProtocolPacket responsePacket;

int main(int argc, char *argv[]) {
  printf("Usage: protocolTest [IP:PORT|IP|PORT]\r\n");
  unsigned short port = DEFAULT_PORT;
  uint32_t ip32 = PACK_IP32(defaultIP);
  if (argc > 1) {
    getIpPort(argv[1], &ip32, &port, ip32, DEFAULT_PORT);
  }
  udpSendPort = port;
  printf("Sending to IP:PORT ");
  PRINT_IP32(ip32);
  printf(":%d\r\n", udpSendPort);

  int rc = clientInit(udpSendPort, ip32);
  if (rc < 0) {
    printf("Exiting\r\n");
    return 0;
  }
  int errs = doTests();
  if (errs != 0) {
    printf("Tests failed: %d\r\n", errs);
    return 1;
  } else {
    printf("Tests passed\r\n");
  }
  return 0;
}

// ============================ Static Functions ==============================
static int buildTestPacket(void *pkt) {
  struct ccProtocolPacket *cpkt = (struct ccProtocolPacket *)pkt;
  cpkt->magic = CC_PROTOCOL_MAGIC;
  cpkt->identifier = 0xcafe;
  cpkt->command = CC_PROTOCOL_CMD_HI_SYSMON;
  cpkt->cellInfo = 0;
  return 0;
}

static int doTests(void) {
  int rc;
  rc = buildTestPacket((void *)&testPacket);
  printf("SENDING: %d bytes\r\n", (int)CC_PROTOCOL_ARG_COUNT_TO_SIZE(0));
  ssize_t x = send(udpfd, (const void *)&testPacket, (int)CC_PROTOCOL_ARG_COUNT_TO_SIZE(0), 0);
  rc = receiveReply();
  int errs = 0;
  if (rc > 0) {
    printf("Received response of payload size %d\r\n", rc);
    //printResponse(CC_PROTOCOL_SIZE_TO_ARG_COUNT(rc));
    errs = argValidatorSYSMON(&responsePacket, CC_PROTOCOL_SIZE_TO_ARG_COUNT(rc));
  } else {
    printf("rc = %d\r\n", rc);
    errs = -1;
  }
  //waitms(500);
  return errs;
}

static int receiveReply(void) {
  size_t x = 0;
  int attempts = 5;
  while (attempts > 0) {
    x = recv(udpfd, (void *)&responsePacket, (size_t)CCPACKET_SIZE, MSG_DONTWAIT);
    if ((int)x > 0) {
      printf("Breaking x = %ld\r\n", x);
      break;
    }
    waitms(100);
    attempts--;
  }
  if (attempts == 0) {
    printf("Did not receive reply in 5 attempts\r\n");
    return -1;
  }
  return (int)x;
}

/*
struct ccProtocolPacket {
    uint32_t        magic;
    uint32_t        identifier;
    uint32_t        command;
    uint32_t        cellInfo; // Cell BPM count, Cell count, Cell index
    uint32_t        args[CC_PROTOCOL_ARG_CAPACITY];
};
 */
static void printResponse(int nargs) {
  printf("Response: (%d args)\r\n", nargs);
  printf("  magic = 0x%x\r\n", responsePacket.magic);
  printf("  identifier = 0x%x\r\n", responsePacket.identifier);
  printf("  command = 0x%x\r\n", responsePacket.command);
  printf("  cellInfo = 0x%x\r\n", responsePacket.cellInfo);
  for (int n = 0; n < nargs; n++) {
    printf("    arg[%d] = 0x%x\r\n", n, responsePacket.args[n]);
  }
  return;
}

static void waitms(int nms) {
  struct timespec minsleep = {1*(nms / 1000), 1000000*(nms % 1000)};
  nanosleep(&minsleep, NULL);
  return;
}

static int clientInit(unsigned short port, uint32_t ipAddr) {
  if ((udpfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
    printf("socket error\r\n");
    return -1;
  }
  struct sockaddr_in sa_client;
  memset(&sa_client, 0, sizeof(sa_client));
  sa_client.sin_family=AF_INET;
  sa_client.sin_addr.s_addr=ipAddr; // Already in network-byte-order uint32_t //inet_addr(ipAddr);
  sa_client.sin_port=htons(port);

  socklen_t sa_clientlen = sizeof(sa_client);
  int rc = connect(udpfd, (const struct sockaddr *)&sa_client, sa_clientlen);
  if (rc != 0) {
    printf("connect failed. rc = %d\r\n", rc);
    return -1;
  }
  printf("Connected to port %d\r\n", port);
  initialized = 1;
  return 0;
}

/*
static int getIpPort(const char *inStr, uint32_t *pIp32, uint16_t *pPort) {
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
    memcpy(ip, defaultIP, sizeof(ip)/sizeof(uint8_t));
  }
  if (useDefaultPort) {
    *pPort = DEFAULT_PORT;
  }
  *pIp32 = PACK_IP32(ip);
  //printf("IP = %d.%d.%d.%d\r\n", ip[0], ip[1], ip[2], ip[3]);
  return 0;
}
*/

static int argValidatorSYSMON(struct ccProtocolPacket *cpkt, int nargs) {
  int errs = 0;
  printf("SYSMON expects %d args\r\n", EXPECTED_ARGS_SYSMON);
  if (nargs != EXPECTED_ARGS_SYSMON) { errs++; };
  int n = 0;
  int m = 0;
  int narg = 0;
  uint32_t arg;
  uint16_t halfarg;
  // XADC value (ignore for now)
#undef INDENT
#define INDENT  "    "
  for (n = 0; n < XADC_CHANNEL_COUNT; n++) {
    // TODO - Not all of these are temperature.  Which are voltage?  What's the conversion?
    if (n % 2 == 0) { // two args packed into 1
      arg = cpkt->args[narg++];
    }
    halfarg = (arg >> (n%2)*16) & 0xFFFF;
    switch (n) {
      case 0: // Temperature
        PRINTOK("XADC[%d] = %.2f degC\r\n", n, XADC_TO_DEGC_DOUBLE((arg & 0xFFFF)));
        break;
      case 1:
      case 2:
      case 3:
        break;
    }
  }
  // QSFP
  for (n = 0; n < QSFP_COUNT; n++) {
    // Temperature and voltage
    arg = cpkt->args[narg++];
    for (m = 0; m < QSFP_RX_COUNT; m++) {
      // RX power (16bit hi; 16bit lo)
      arg = cpkt->args[narg++];
      PRINTOK("QSFP %d RX PWR %d = 0x%x\r\n", n, m, arg & 0xFFFF);
      if (++m < QSFP_RX_COUNT) {  // NOTE! Incrementing m again here!
        PRINTOK("QSFP %d RX PWR %d = 0x%x\r\n", n, m, (arg >> 16));
      }
    }
  }
  // GPIO_IDX_EVENT_STATUS
  arg = cpkt->args[narg++];
  PRINTOK("GPIO_IDX_EVENT_STATUS = 0x%x\r\n", arg);
  // PILOT_TONE_ADC
  for (n = 0; n < PILOT_TONE_ADC_COUNT; n++) {
    // 16bit hi; 16bit lo
    arg = cpkt->args[narg++];
    PRINTOK("PT %d ADC = 0x%x\r\n", n, arg & 0xFFFF);
    if (++n < PILOT_TONE_ADC_COUNT) { // NOTE! Incrementing n again here!
      PRINTOK("PT %d ADC = 0x%x\r\n", n, (arg >> 16));
    }
  }
  // PILOT_TONE_TEMPERATURE
  for (n = 0; n < PILOT_TONE_TEMPERATURE_COUNT; n++) {
    arg = cpkt->args[narg++];
    PRINTOK("PT %d temperature = %d\r\n", n, arg);
  }
  // PLL
  for (n = 0; n < 2; n++) {
    for (m = 0; m < PILOT_TONE_PLL_OUTPUT_COUNT; m++) {
      arg = cpkt->args[narg++];
      PRINTOK("PLL %d OUTPUT %d = 0x%x\r\n", n, m, arg & 0xFFFF);
      if (++m < PILOT_TONE_PLL_OUTPUT_COUNT) {  // NOTE! Incrementing m again here!
        PRINTOK("PLL %d OUTPUT %d = 0x%x\r\n", n, m, (arg >> 16));
      }
    }
    arg = cpkt->args[narg++];
    PRINTOK("PLL %d table = %d; value = %d\r\n", n, (arg >> 16), arg & 0xFFFF);
  }
  // EVR
  arg = cpkt->args[narg++];
  PRINTOK("EVR: TooManySeconds = %d; TooFewSeconds = %d\r\n", (arg >> 16), arg & 0xFFFF);
  arg = cpkt->args[narg++];
  PRINTOK("EVR: OutOfSequenceSeconds = %d\r\n", arg);
  // GPIO_IDX_AWG_CSR
  arg = cpkt->args[narg++];
  PRINTOK("GPIO_IDX_AWG_CSR = 0x%x\r\n", arg);
  // GPIO_IDX_WFR_CSR
  arg = cpkt->args[narg++];
  PRINTOK("GPIO_IDX_WFR_CSR = 0x%x\r\n", arg);
  // FOFB PCSPMA status
  arg = cpkt->args[narg++];
  PRINTOK("FOFB PCSPMA = 0x%x\r\n", arg);
  PRINTOK("narg = %d\r\n", narg);
#undef INDENT
#define INDENT ""
  return errs;
}

