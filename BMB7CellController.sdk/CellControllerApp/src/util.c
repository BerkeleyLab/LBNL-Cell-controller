#include <math.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <xil_io.h>
#include <xparameters.h>
#include "console.h"
#include "gpio.h"
#include "util.h"

int debugFlags;

/*
 * Employ some gross hacks to avoid using vprintf (and thereby
 * bloating the text size by about 60 kB).
 */
void
fatal(const char *fmt, ...)
{
    va_list args;
    unsigned int now, then = MICROSECONDS_SINCE_BOOT();
    unsigned int limit = 0;
    static int enterCount = 0;
    unsigned int a[4];

    enterCount++;
    for (;;) {
        if (((now = MICROSECONDS_SINCE_BOOT()) - then) >= limit) {
            printf("*** Fatal error:  ");
            va_start(args, fmt);
            a[0] = va_arg(args, unsigned int);
            a[1] = va_arg(args, unsigned int);
            a[2] = va_arg(args, unsigned int);
            a[3] = va_arg(args, unsigned int);
            printf(fmt, a[0], a[1], a[2], a[3]);
            va_end(args);
            printf("\n");
            then = now;
            limit = 10000000;
        }
        if (enterCount == 1) consoleCheck();
    }
}

void
warn(const char *fmt, ...)
{
    va_list args;
    unsigned int a[4];

    printf("*** Warning: ");
    va_start(args, fmt);
    a[0] = va_arg(args, unsigned int);
    a[1] = va_arg(args, unsigned int);
    a[2] = va_arg(args, unsigned int);
    a[3] = va_arg(args, unsigned int);
    printf(fmt, a[0], a[1], a[2], a[3]);
    va_end(args);
    printf("\n");
}

void
microsecondSpin(unsigned int us)
{
    unsigned int now, then = MICROSECONDS_SINCE_BOOT();
    while (((now = MICROSECONDS_SINCE_BOOT()) - then) < us) continue;
}

/*
 * Pretty-print an unsigned integer value
 */
void
uintPrint(unsigned int n)
{
    int i;
    int t[4];
    for (i = 0 ; i < 4 ; i++) {
        t[i] = n % 1000;
        n /= 1000;
    }
    if (t[3])      printf("%d,%03d,%03d,%03d", t[3], t[2], t[1], t[0]) ;
    else if (t[2]) printf("%5d,%03d,%03d", t[2], t[1], t[0]) ;
    else if (t[1]) printf("%9d,%03d", t[1], t[0]) ;
    else           printf("%13d", t[0]) ;
}

/*
 * Show register contents
 */
void
showReg(int i)
{
    int r;

    i &= 0x3F;
    r = GPIO_READ(i);
    printf("  R%d = %04X:%04X %11d\n", i, (r>>16)&0xFFFF, r&0xFFFF, r);
}
