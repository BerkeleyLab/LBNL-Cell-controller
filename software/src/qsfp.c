#include <stdio.h>
#include <stdint.h>
#include "gpio.h"
#include "qsfp.h"
#include "util.h"

#define CSR_PRESENCE_BASE  16

#define INFO_STRING_CHARS   16
#define DATE_STRING_CHARS   6

#define MODULE_STATUS_OFFSET    2
#define TEMPERATURE_OFFSET     22
#define VSUPPLY_OFFSET         26
#define RXPOWER_0_OFFSET       34
#define IDENTIFIER_OFFSET     128
#define VENDOR_NAME_OFFSET    148
#define PART_NAME_OFFSET      168
#define REVISION_CODE_OFFSET  184
#define WAVELENGTH_OFFSET     186
#define SERIAL_NUMBER_OFFSET  196
#define DATE_CODE_OFFSET      212
#define DIAG_TYPE_OFFSET      220

static const char *
str(int qsfp, int offset, int length)
{
    int i;
    int lastNonBlank = -1;
    uint16_t v = 0;
    static char cbuf[INFO_STRING_CHARS+1];

    for (i = 0 ; i < length ; i++, offset++) {
        int bidx = offset & 1;
        unsigned char c;
        if (bidx == 0) {
            int qidx = (qsfp * 256 + offset) >> 1;
            GPIO_WRITE(GPIO_IDX_QSFP_IIC, qidx);
            v = GPIO_READ(GPIO_IDX_QSFP_IIC);
        }
        c = v >> (8 * (1 - bidx));
        if (c == 0xFF) return "";
        if (c != ' ') lastNonBlank = i;
        cbuf[i] = c;
    }
    cbuf[lastNonBlank+1] = '\0';
    return cbuf;
}

static const char *
date(int qsfp)
{
    const char *cp = str(qsfp, DATE_CODE_OFFSET, DATE_STRING_CHARS);
    static char cbuf[11]; /* ISO 8601 YYYY-MM-DD */

    if (*cp == '\0') return "";
    cbuf[0] = '2';
    cbuf[1] = '0'; /* No, I am not Y2.1K-compliant */
    cbuf[2] = cp[0];
    cbuf[3] = cp[1];
    cbuf[4] = '-';
    cbuf[5] = cp[2];
    cbuf[6] = cp[3];
    cbuf[7] = '-';
    cbuf[8] = cp[4];
    cbuf[9] = cp[5];
    cbuf[10] = '\0';
    return cbuf;
}

static int
get16(int qsfp, int offset)
{
    int qidx = (qsfp * 256 + offset) >> 1;
    uint16_t v;

    GPIO_WRITE(GPIO_IDX_QSFP_IIC, qidx);
    v = GPIO_READ(GPIO_IDX_QSFP_IIC);
    return v & 0xFFFF;
}

static int
get8(int qsfp, int offset)
{
    uint16_t v = get16(qsfp, offset & ~1);
    return (uint8_t)((offset & 1) ? v : v >> 8);
}

int
qsfpRxPower(int qsfpIndex, int channel)
{
    return get16(qsfpIndex, RXPOWER_0_OFFSET + (2 * channel));
}

int
qsfpVoltage(int qsfpIndex)
{
    return get16(qsfpIndex, VSUPPLY_OFFSET);
}

int
qsfpTemperature(int qsfpIndex)
{
    return ((int16_t)get16(qsfpIndex, TEMPERATURE_OFFSET) * 100) >> 8;
}

void
qsfpDump(void)
{
    int q, a;

    for (q = 0 ; q < QSFP_COUNT ; q++) {
        for (a = 0 ; a < 256 ; a += 2) {
            uint16_t v = get16(q, a);
            printf("  %d:%3d %04X %5d\n", q, a, v, v);
        }
    }
}

static void
showInfo(int idx)
{
    uint32_t csr = GPIO_READ(GPIO_IDX_QSFP_IIC);
    uint16_t idw;
    uint8_t id, ext;
    const char *cp;

    printf("==== QSFP %d ====\n", idx + 1);
    if ((csr & (1 << (CSR_PRESENCE_BASE + idx))) != 0) {
        printf ("   NOT PRESENT!\n");
        return;
    }
    printf("         Vendor: %s\n", str(idx, VENDOR_NAME_OFFSET, INFO_STRING_CHARS));
    printf("      Part name: %s\n", str(idx, PART_NAME_OFFSET, INFO_STRING_CHARS));
    printf("       Revision: %s\n", str(idx, REVISION_CODE_OFFSET, 2));
    printf("  Serial Number: %s\n", str(idx, SERIAL_NUMBER_OFFSET, INFO_STRING_CHARS));
    printf("      Date Code: %s\n", date(idx));
    printf("     Wavelength: %d nm\n", (get16(idx, WAVELENGTH_OFFSET)+10)/20);
    idw = get16(idx, IDENTIFIER_OFFSET);
    id = idw >> 8;
    ext = idw;
    cp = (id == 0xd) ? " (QSFP+)" : "";
    printf("     Identifier: %02x%s\n", id, cp);
    switch ((ext >> 6) & 0x3) {
    case 0x0: cp = "1.5"; break;
    case 0x1: cp = "2.0"; break;
    case 0x2: cp = "2.5"; break;
    default:  cp = "3.5"; break;
    }
    printf(" Ext.Identifier: %02x (%s W)\n", ext, cp);
}

void
showMonitor(int qsfpIndex)
{
    int i;
    int v;

    v = qsfpTemperature(qsfpIndex);
    printf("  T: %d.%02d", v / 100, v % 100);
    v = (qsfpVoltage(qsfpIndex) + 5) / 10;
    printf("  V: %d.%03d", v / 1000, v % 1000);
    printf("  Rx(uW):");
    for (i = 0 ; i < QSFP_RX_COUNT ; i++) {
        v = qsfpRxPower(qsfpIndex, i);
        printf("%4d.%d", v / 10, v % 10);
    }
    printf("\n");
}

void
qsfpShowMonitor(void)
{
    int i;

    for (i = 0 ; i < QSFP_COUNT ; i++) {
        showMonitor(i);
    }
}

void
qsfpShowInfo(void)
{
    int i;

    for (i = 0 ; i < QSFP_COUNT ; i++) {
        showInfo(i);
        showMonitor(i);
    }
}

void
qsfpInit(void)
{
    int i;
    int up = 0;
    int pass = 0;

    while (up != ((1 << QSFP_COUNT) - 1)) {
        if (++pass == 10) {
            warn("Timed out out waiting for QSFP (UP:0x%x)", up);
            break;
        }
        microsecondSpin(500000);
        for (i = 0; i < QSFP_COUNT ; i++) {
            uint8_t v = get8(i, MODULE_STATUS_OFFSET);
            if ((v & 0x1) == 0) up |= (1 << i);
        }
    }
    qsfpShowInfo();
}
