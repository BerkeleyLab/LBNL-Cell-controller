/* Generate traffic for cell controller tests
 */

#include <stdio.h>
#include <stdlib.h>
#include "udp_io.h"
#include "ipcfg.h"
#include "aurora_mux.h"

#define DEFAULT_UDP_PORT        (50007)

const uint8_t defaultIP[] = {127, 0, 0, 1};
//const uint8_t defaultIP[] = {1, 0, 0, 127};

static int conn = -1;

stream_mux_pkt_t testpkt;

uint8_t inpkt[1508];

int main(int argc, char *argv[]) {
  unsigned short udp_port = DEFAULT_UDP_PORT;
  uint32_t ip32 = PACK_IP32(defaultIP);
  if (argc > 1) {
    getIpPort(argv[1], &ip32, &udp_port, ip32, DEFAULT_UDP_PORT);
  }
  printf("Generating traffic on ");
  PRINT_IP32(ip32);
  printf(":%d\r\n", udp_port);
  conn = udp_client_init(udp_port, ip32);
  if (conn < 0) {
    printf("UDP initialization failed\r\n");
    return -1;
  }
  testpkt.muxinfo = PACK_MUXINFO(NSTREAM_BPM_CCW);
  testpkt.auHeader = PACK_AUHEADER(1, 4, 5);
  testpkt.auDataX = 0x123456;
  testpkt.auDataY = 0x789abc;
  testpkt.auDataS = PACK_AUDATAS(0, 0, 0xdef000);
  udp_send(conn, (const void *)&testpkt, sizeof(stream_mux_pkt_t));
  int rc;
  for (int n = 0; n < 10; n++) {
    rc = udp_receive(conn, (void *)inpkt, 1508);
    if (rc > 0) {
      break;
    }
  }
  printf("rc = %d\r\n", rc);
  if (rc > 0) {
    printf("First 4: 0x%x, 0x%x, 0x%x, 0x%x\r\n", inpkt[0], inpkt[1], inpkt[2], inpkt[3]);
  }
  return 0;
}
