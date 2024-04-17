#ifndef _SYSTEM_PARAMETERS_H_
#define _SYSTEM_PARAMETERS_H_

typedef struct ethernetMAC {
    uint8_t  a[6];
} ethernetMAC;

typedef struct ipv4Address {
    uint8_t  a[4];
} ipv4Address;

struct sysNetParms {
    ipv4Address address;
    ipv4Address netmask;
    ipv4Address gateway;
};
struct sysNetConfig {
    ethernetMAC        ethernetMAC;
    struct sysNetParms np;
};

extern struct systemParameters {
    struct sysNetConfig netConfig;
    uint32_t            startupDebugFlags;
    uint32_t            checksum;
} systemParameters;

void systemParametersInit(void);
void systemParametersStash(void);

char *formatIP(const void *val);
int   parseIP(const char *str, void *val);
char *formatMAC(const void *val);
int   parseMAC(const char *str, void *val);

void showNetworkConfig(const struct sysNetParms *np);

#endif
