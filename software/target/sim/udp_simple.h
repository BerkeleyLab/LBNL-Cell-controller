#ifndef UDP_SIMPLE_H
#define UDP_SIMPLE_H

#ifdef __cplusplus
extern "C" {
#endif

#include <sys/socket.h>
#include <unistd.h>   /* socklen_t read() and write() */

#define ETH_MAXLEN 1500   /* maximum line nchars */

#define PROTOCOL_IPV4 0x0800

typedef struct ipv4Address {
    uint8_t  a[4];
} ipv4Address;  // size 4

#define IPV4_TYPE_UDP   17
struct ipv4Header {
    uint8_t         type_len;
    uint8_t         dscp_ecn;
    uint16_t        length;
    uint16_t        identification;
    uint16_t        flags_offset;
    uint8_t         ttl;
    uint8_t         protocol;
    uint16_t        checksum;
    ipv4Address     source;
    ipv4Address     destination;
};  // size 20

/*****************************************************************************
 * UDP header
 */
struct udpHeader {
    uint16_t    sourcePort;
    uint16_t    destinationPort;
    uint16_t    length;
    uint16_t    checksum;
};  // size 8

#define ETH_PACKET_MIN                      (14 + sizeof(struct ipv4Header)-sizeof(struct udpHeader))
#define ETH_PAYLOAD_MAX   (ETH_MAXLEN-sizeof(struct ipv4Header)-sizeof(struct udpHeader))
#define ETH_PACKET_LENGTH(payloadLength)    (payloadLength + ETH_PACKET_MIN)
#define ETH_PAYLOAD_LENGTH(frameLength)     ((int)(frameLength - 42))
#define IPV4_ADDR_FROM_U32(ad)              {(ad & 0xFF000000) >> 24, (ad & 0xFF0000) >> 16, (ad & 0xFF00) >> 8, (ad & 0xFF)}

typedef struct {
  uint8_t           destinationMAC[6];
  uint8_t           sourceMAC[6];
  uint8_t           protocol[2];
  struct ipv4Header ipv4; // size 20
  struct udpHeader  udp;  // size 8
  char              payload[ETH_PAYLOAD_MAX]; // offset = 6 + 6 + 2 + 20 + 8 = 42
} eth_packet_t;

typedef union {
  eth_packet_t pkt;
  uint32_t words[sizeof(eth_packet_t)/sizeof(uint32_t)];
  uint16_t shorts[sizeof(eth_packet_t)/sizeof(uint16_t)];
} eth_union_t;

int udp_init(unsigned short port);
int udp_receive(void *dest, int nchars);
int udp_receive_meta(eth_packet_t *pkt);
int udp_reply(const void *src, int nchars);
int udp_send(const void *src, int nchars, struct sockaddr *dest_addr, socklen_t dest_len);

#ifdef __cplusplus
}
#endif

#endif  /* UDP_SIMPLE_H */
