/*
 * File: dbg.h
 * Desc: Various debug print statements that can be switched on/off at the file level
 */

#ifndef __DBG_H
#define __DBG_H

// printd() will be silenced completely by undefining DEBUG_PRINT
#ifdef DEBUG_PRINT
#define printd(...)      printf(__FILE__ " [" S__LINE__ "] " __VA_ARGS__)
#else
#define printd(...)
#endif /* DEBUG_PRINT */

// printv() will toggle from "file.c [lineNum] msg..." to "msg..." with VERBOSE_PRINT
#ifdef VERBOSE_PRINT
#define printv(...)      printf(__FILE__ " [" S__LINE__ "] " __VA_ARGS__)
#else
#define printv(...)      printf(__VA_ARGS__)
#endif /* VERBOSE_PRINT */

// Print the compiled date/time
#define printt()            printf("Compiled on " __DATE__ " at " __TIME__ "\r\n");

#ifdef __cplusplus
}
#endif

#endif // __DBG_H

