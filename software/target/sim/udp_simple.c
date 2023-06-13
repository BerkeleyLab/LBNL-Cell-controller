/*  File: udp_simple.c
 *  Desc: Simplified version of udp_model.c/h for use outside of verilator
 *        context.
 */

#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <unistd.h>   /* socklen_t read() and write() */
#include <fcntl.h>
#include <stdint.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>

#include "udp_simple.h"


typedef struct {
  unsigned char buf[ETH_MAXLEN];
} pkt_t;

struct sockaddr_in src_addr;  /* Global */
socklen_t src_addrlen;
int udpfd;
int initialized = 0;
static unsigned short udp_port;

static pkt_t pkt;

int udp_init(unsigned short port) {
  if ((udpfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
    printf("socket error\r\n");
    return -1;
  }
  struct sockaddr_in sa_rcvr;
  memset(&sa_rcvr, 0, sizeof(sa_rcvr));
  sa_rcvr.sin_family=AF_INET;
  sa_rcvr.sin_addr.s_addr=htonl(INADDR_ANY);
  sa_rcvr.sin_port=htons(port);
  if (bind(udpfd, (struct sockaddr *)&sa_rcvr, sizeof(sa_rcvr)) == -1) {
    printf("could not bind to udp port %u\r\n", port);
    return -1;
  }
  fcntl(udpfd, F_SETFL, O_NONBLOCK);
  udp_port = port;
  initialized = 1;
  return 0;
}

int udp_receive(void *dest, int nchars) {
  if (!initialized) {
    return -1;
  }
  int rc;
  src_addrlen = sizeof(src_addr);
  rc = recvfrom(udpfd, pkt.buf, ETH_MAXLEN, 0, (struct sockaddr *)&src_addr, &src_addrlen);
  int nmax = nchars > rc ? rc : nchars; // min(rc, nchars)
  if (rc < 0) {
    if (errno == EAGAIN) {
      return 0;
    } else {
      printf("Error; errno = %s (%d)\r\n", strerror(errno), errno);
      return (int)(-errno);
    }
  } else {
    for (int n = 0; n < nmax; n++) {
      *((char *)dest + n) = pkt.buf[n];
    }
  }
  return nmax;
}

int udp_receive_meta(eth_packet_t *pkt) {
  int rc = udp_receive((void *)pkt->payload, ETH_PAYLOAD_MAX);
  if (rc > 0) {
    //pkt->destinationMAC = {0, 0, 0, 0, 0, 0};
    //pkt->sourceMAC = {0, 0, 0, 0, 0, 0};
    pkt->protocol[0] = 0x08;
    pkt->protocol[1] = 0x00; // PROTOCOL_IPV4. Network byte order?
    pkt->ipv4.type_len = 0;
    pkt->ipv4.dscp_ecn = 0;
    pkt->ipv4.length = ETH_PACKET_LENGTH(rc);
    pkt->ipv4.identification = 0;
    pkt->ipv4.flags_offset = 0;
    pkt->ipv4.ttl = 255;
    pkt->ipv4.protocol = IPV4_TYPE_UDP;
    pkt->ipv4.checksum = 0;
    *(uint32_t *)&(pkt->ipv4.source) = src_addr.sin_addr.s_addr;
    //pkt->ipv4.destination = {0, 0, 0, 0};
    printf("rc = 0x%x\r\n", rc);
    pkt->udp.length = htons(rc);
    printf("udp.length = 0x%x\r\n", pkt->udp.length);
    pkt->udp.destinationPort = udp_port;
    pkt->udp.sourcePort = src_addr.sin_port;
    return ETH_PACKET_LENGTH(rc);
  }
  return 0;
}

int udp_reply(const void *src, int nchars) {
  printf("udp_reply\r\n");
  if (!initialized) {
    printf("Not initialized\r\n");
    return -1;
  }
  int rc = sendto(udpfd, (char *)src, nchars, 0, (struct sockaddr *)&src_addr, src_addrlen);
  printf("rc = %d\r\n", rc);
  return rc;
}

int udp_send(const void *src, int nchars, struct sockaddr *dest_addr, socklen_t dest_len) {
  printf("udp_send\r\n");
  int rc = sendto(udpfd, (char *)src, nchars, 0, dest_addr, dest_len);
  return rc;
}
