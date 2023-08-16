/* Stand-in only, not (yet?) intended to map to real hardware */
#define GPIO_IDX_NET_RX_DATA     0xfeed0001
#define GPIO_IDX_NET_CONFIG_CSR  0xfeed0002
#define GPIO_IDX_NET_TX_CSR      0xfeed0003
#define GPIO_IDX_NET_RX_CSR      0xfeed0004

static unsigned int GPIO_READ(unsigned long a) {return *(volatile unsigned int *) a;}
static void GPIO_WRITE(unsigned long a, unsigned int d) {*(volatile unsigned int *)a = d;}

#warning "Using dummy gpio.h header for bantamweightUDP library. This is inteded for testing purposes only!!!"
