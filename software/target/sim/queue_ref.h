/*  File: queue_ref.h
 *  Desc: Universal Queue Structure
 *        * Functions as FIFO or Stack
 *        * Supports retry mechanism
 *        * Multiple queues are handled by reference.
 *  Usage:
 *    Initialize
 *    ----------
 *      typdef myQueueItem_t;
 *      queue_t myQueue;
 *      QUEUE_Init(&myQueue, sizeof(myQueueItem_t));
 *
 *    Add Item
 *    --------
 *      myQueueItem_t foo = ...;
 *      QUEUE_Add(&myQueue, &foo);
 *
 *    Get Oldest Item (FIFO-style)
 *    ----------------------------
 *      myQueueItem_t foo;
 *      QUEUE_Get(&myQueue, &foo);
 *
 *    Get Newest Item (stack-style)
 *    ----------------------------
 *      myQueueItem_t foo;
 *      QUEUE_Pop(&myQueue, &foo);
 *
 *    Get Oldest Item with Retry
 *    --------------------------
 *      myQueueItem_t foo;
 *      if (QUEUE_Load(&myQueue, &foo) == QUEUE_OK) {
 *        if handleItem(&foo) {
 *          QUEUE_Inc(&myQueue);
 *        } else {
 *          printf("handleItem() failed. Item will remain in queue for retry\n");
 *        }
 *      }
 *
 *  Other Notes:
 *    QUEUE_Rewind() is useful when you want to remove items from the queue (pretend
 *    like you didn't add them in the first place).  This is helpful when processing
 *    user input in that it supports the "backspace" or "delete" characters.
 *
 *    Multiple queue items can be added or fetched at once via QUEUE_ShiftIn() and
 *    QUEUE_ShiftOut(), respectively.  This is only for FIFO-mode (QUEUE_ShiftOut()
 *    gets the oldest items first, not the newest).  Perhaps in the future I'll add
 *    a QUEUE_PopOut() function.  Then QUEUE_Rewind() would be just like QUEUE_PopOut()
 *    but would avoid copying the data.
 *
 */

#ifndef ___QUEUE_REF_H
#define ___QUEUE_REF_H

#ifdef __cplusplus
extern "C" {
#endif

// ================================= Includes ==================================
#include <stdio.h>
#include <stdint.h>

// ============================== Exported Macros ==============================
#define QUEUE_MAX_SIZE                        (2000)
#define QUEUE_OK                              (0x00)
#define QUEUE_FULL                            (0x01)
#define QUEUE_EMPTY                           (0x02)

// Handy alias
#define QUEUE_Clear                       QUEUE_Init
// ============================= Exported Typedefs =============================
typedef unsigned char queue_ret_t;

typedef struct {
  int pIn;
  int pOut;
  queue_ret_t full;
  ssize_t item_size;
  char queue[QUEUE_MAX_SIZE];
} queue_t;

// ======================= Exported Function Prototypes ========================
void QUEUE_Init(queue_t *pqueue, ssize_t item_size);
queue_ret_t QUEUE_Status(queue_t *pqueue);
int QUEUE_FillLevel(queue_t *pqueue);
queue_ret_t QUEUE_Add(queue_t *pqueue, void *item);
queue_ret_t QUEUE_Pop(queue_t *pqueue, volatile void *item);
queue_ret_t QUEUE_Get(queue_t *pqueue, volatile void *item);
queue_ret_t QUEUE_Load(queue_t *pqueue, volatile void *item);
queue_ret_t QUEUE_Inc(queue_t *pqueue);
queue_ret_t QUEUE_Rewind(queue_t *pqueue, int n);
int QUEUE_ShiftOut(queue_t *pqueue, volatile void *pData, int len);
int QUEUE_ShiftIn(queue_t *pqueue, const void *pData, int len);

#ifdef __cplusplus
}
#endif

#endif // ___QUEUE_REF_H

