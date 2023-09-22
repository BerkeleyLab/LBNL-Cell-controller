/*  File: queue_ref.c
 *  Desc: Universal Queue Structure; Static reference
 */

#include "queue_ref.h"

// ============================== Private Macros ===============================
#define SIZEOF_QUEUE_ITEM                 (sizeof(queue_item_t)/sizeof(char))

// ============================= Private Typedefs ==============================

// =========================== Function Definitions ============================

/*
 * void QUEUE_Init(queue_t *pqueue);
 *    Mandatory queue structure initialization
 */
void QUEUE_Init(queue_t *pqueue) {
  pqueue->pIn = 0;
  pqueue->pOut = 0;
  pqueue->full = 0;
  return;
}

/*
 * queue_ret_t QUEUE_Status(queue_t *pqueue);
 *    Return either QUEUE_EMTPY, QUEUE_FULL, or QUEUE_OK if not full or empty.
 */
queue_ret_t QUEUE_Status(queue_t *pqueue) {
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  if (pqueue->full) {
    return QUEUE_FULL;
  }
  // If not full or empty, it is non-empty (at least one item in queue)
  return QUEUE_OK;
}

/*
 * queue_index_t QUEUE_FillLevel(queue_t *pqueue);
 *    Return the number of items currently in the queue.
 */
queue_index_t QUEUE_FillLevel(queue_t *pqueue) {
  if (pqueue->full) {
    return QUEUE_MAX_ITEMS;
  } else if (pqueue->pIn == pqueue->pOut) {
    return 0;
  } else if (pqueue->pIn > pqueue->pOut) {
    return (int)(pqueue->pIn - pqueue->pOut);
  } else {
    return (int)(QUEUE_MAX_ITEMS + pqueue->pIn - pqueue->pOut);
  }
}

/*
 * queue_ret_t QUEUE_Add(queue_t *pqueue, queue_item_t *item);
 *    Copy data from 'item' into the queue (if not full) and increment pointer.
 */
queue_ret_t QUEUE_Add(queue_t *pqueue, queue_item_t *item) {
  // If full, return error
  if (pqueue->full) {
    //printf("  QUEUE_Add FULL!\r\n");
    return QUEUE_FULL;
  }
  // Copy item into queue
  for (unsigned int n = 0; n < SIZEOF_QUEUE_ITEM; n++) {
    *((char *)&(pqueue->queue[pqueue->pIn]) + n) = *((char *)item + n);
  }
  // Wrap pIn at boundary
  if (pqueue->pIn == QUEUE_MAX_ITEMS - 1) {
    pqueue->pIn = 0;
  } else {
    pqueue->pIn++;
  }
  // Check for full condition
  if (pqueue->pIn == pqueue->pOut) {
    pqueue->full = 1;
  }
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Get(queue_t *pqueue, volatile queue_item_t *item);
 *    Copy the oldest item from the queue into 'item' and remove from queue
 *    (increment pointer).
 */
queue_ret_t QUEUE_Get(queue_t *pqueue, volatile queue_item_t *item) {
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    //printf("  QUEUE_Get EMPTY!\r\n");
    return QUEUE_EMPTY;
  }
  // Copy next data from the queue to item
  for (unsigned int n = 0; n < SIZEOF_QUEUE_ITEM; n++) {
    *((char *)item + n) = *((char *)&(pqueue->queue[pqueue->pOut]) + n);
  }
  // Wrap pOut at boundary
  if (pqueue->pOut == QUEUE_MAX_ITEMS - 1) {
    pqueue->pOut = 0;
  } else {
    pqueue->pOut++;
  }
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Pop(queue_t *pqueue, volatile queue_item_t *item);
 * Like _Get but removes the newest (last-added) item rather than the oldest item
 */
queue_ret_t QUEUE_Pop(queue_t *pqueue, volatile queue_item_t *item) {
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  // Rewind pIn and wrap at boundary
  if (pqueue->pIn == 0) {
    pqueue->pIn = QUEUE_MAX_ITEMS - 1;
  } else {
    pqueue->pIn--;
  }
  // Copy newest data from the queue to item
  for (unsigned int n = 0; n < SIZEOF_QUEUE_ITEM; n++) {
    *((char *)item + n) = *((char *)&(pqueue->queue[pqueue->pIn]) + n);
  }
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Load(queue_t *pqueue, volatile queue_item_t *item);
 *    Like QUEUE_Get() but does not increment the pointer (data remains in the
 *    queue).  Must call QUEUE_Inc() to manually increment the pointer when
 *    data processing successful.  Otherwise, the item will remain in the queue
 *    to attempt processing again.
 */
queue_ret_t QUEUE_Load(queue_t *pqueue, volatile queue_item_t *item) {
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  // Copy next data from the queue to item
  for (unsigned int n = 0; n < SIZEOF_QUEUE_ITEM; n++) {
    *((char *)item + n) = *((char *)&(pqueue->queue[pqueue->pOut]) + n);
  }
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Inc(queue_t *pqueue);
 *    Manually increment the queue.  This can be used on its own to discard the
 *    oldest item in the queue or can be used with QUEUE_Load() for a queue
 *    service with retry capability.
 */
queue_ret_t QUEUE_Inc(queue_t *pqueue) {
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  // Increment and wrap pOut at boundary
  if (pqueue->pOut == QUEUE_MAX_ITEMS - 1) {
    pqueue->pOut = 0;
  } else {
    pqueue->pOut++;
  }
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Rewind(queue_t *pqueue, queue_index_t n);
 * Pop and discard the newest 'n' entries
 */
queue_ret_t QUEUE_Rewind(queue_t *pqueue, queue_index_t n) {
  // No-op if n=0
  if (n == 0) {
    return QUEUE_OK;
  }
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  // n = min(n, fill-level)
  queue_index_t fill = QUEUE_FillLevel(pqueue);
  n = n > fill ? fill : n;
  // Rewind pIn and wrap at boundary
  if ((queue_index_t)n > pqueue->pIn) {
    pqueue->pIn = QUEUE_MAX_ITEMS - ((queue_index_t)n - pqueue->pIn);
  } else {
    pqueue->pIn -= (queue_index_t)n;
  }
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

/*
 * queue_index_t QUEUE_ShiftOut(queue_t *pqueue, queue_item_t *pData, queue_index_t len);
 *  Shift up to 'len'
 */
queue_index_t QUEUE_ShiftOut(queue_t *pqueue, queue_item_t *pData, queue_index_t len) {
  queue_index_t nShifted = 0;
  queue_item_t dataOut;
  while (QUEUE_Get(pqueue, &dataOut) != QUEUE_EMPTY) {
    *(pData++) = dataOut;
    if (++nShifted == len) {
      break;
    }
  }
  return nShifted;
}



