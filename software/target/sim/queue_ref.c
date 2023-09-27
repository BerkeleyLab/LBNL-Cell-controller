/*  File: queue_ref.c
 *  Desc: Universal Queue Structure
 */

#include "queue_ref.h"

// ============================== Private Macros ===============================
// ============================= Private Typedefs ==============================
// ======================== Static Function Prototypes =========================
static int _queue_bytefill(queue_t *pqueue);
static queue_ret_t _queue_addbyte(queue_t *pqueue, void *item);
static queue_ret_t _queue_getbyte(queue_t *pqueue, volatile void *item);
static queue_ret_t _queue_popbyte(queue_t *pqueue, volatile void *item);

// =========================== Function Definitions ============================

/*
 * void QUEUE_Init(queue_t *pqueue, ssize_t item_size);
 *    Mandatory queue structure initialization
 */
void QUEUE_Init(queue_t *pqueue, ssize_t item_size) {
  pqueue->pIn = 0;
  pqueue->pOut = 0;
  pqueue->full = 0;
  pqueue->item_size = item_size;
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
 * int QUEUE_FillLevel(queue_t *pqueue);
 *    Return the number of items of size pqueue->item_size currently in the queue.
 */
int QUEUE_FillLevel(queue_t *pqueue) {
  int bytefill = _queue_bytefill(pqueue);
  return bytefill/((int)(pqueue->item_size));
}

/*
 * queue_ret_t QUEUE_Add(queue_t *pqueue, void *item);
 *    Copy pqueue->item_size of data from 'item' into the queue. Breaks early if queue fills.
 */
queue_ret_t QUEUE_Add(queue_t *pqueue, void *item) {
  queue_ret_t rval = QUEUE_OK;
  // Copy item into queue
  for (unsigned int n = 0; n < pqueue->item_size; n++) {
    rval = _queue_addbyte(pqueue, ((char *)item + n));
    if (rval == QUEUE_FULL) {
      break;
    }
  }
  return rval;
}

/*
 * queue_ret_t QUEUE_Get(queue_t *pqueue, volatile void *item);
 *    Copy the oldest pqueue->item_size of data from the queue into 'item' and remove from queue
 *    (increment pointer).
 */
queue_ret_t QUEUE_Get(queue_t *pqueue, volatile void *item) {
  queue_ret_t rval = QUEUE_OK;
  // Copy next data from the queue to item
  for (unsigned int n = 0; n < pqueue->item_size; n++) {
    rval = _queue_getbyte(pqueue, ((char *)item + n));
    if (rval == QUEUE_EMPTY) {
      break;
    }
  }
  return rval;
}

/*
 * queue_ret_t QUEUE_Pop(queue_t *pqueue, volatile void *item);
 * Like _Get but removes the newest (last-added) item rather than the oldest item
 */
queue_ret_t QUEUE_Pop(queue_t *pqueue, volatile void *item) {
  queue_ret_t rval = QUEUE_OK;
  // Copy most-recent data from the queue to item
  for (unsigned int n = 0; n < pqueue->item_size; n++) {
    rval = _queue_popbyte(pqueue, ((char *)item + n));
    if (rval == QUEUE_EMPTY) {
      break;
    }
  }
  return rval;
}

/*
 * queue_ret_t QUEUE_Load(queue_t *pqueue, volatile void *item);
 *    Like QUEUE_Get() but does not increment the pointer (data remains in the
 *    queue).  Must call QUEUE_Inc() to manually increment the pointer when
 *    data processing successful.  Otherwise, the item will remain in the queue
 *    to attempt processing again.
 */
queue_ret_t QUEUE_Load(queue_t *pqueue, volatile void *item) {
  // Check for enough data
  int fill = QUEUE_FillLevel(pqueue);
  if (fill == 0) {
    return QUEUE_EMPTY;
  }
  // Copy next data from the queue to item
  for (unsigned int n = 0; n < pqueue->item_size; n++) {
    *((char *)item + n) = *((char *)&(pqueue->queue[pqueue->pOut]) + n);
  }
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Inc(queue_t *pqueue);
 *    Manually increment the queue output pointer by pqueue->item_size.
 *    This can be used on its own to discard the oldest item in the queue
 *    or can be used with QUEUE_Load() for a queue service with retry
 *    capability.
 */
queue_ret_t QUEUE_Inc(queue_t *pqueue) {
  // Check for enough data
  int fill = QUEUE_FillLevel(pqueue);
  if (fill == 0) {
    return QUEUE_EMPTY;
  }
  // Increment and wrap pOut at boundary
  pqueue->pOut = (pqueue->pOut + pqueue->item_size) % QUEUE_MAX_SIZE;
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

/*
 * queue_ret_t QUEUE_Rewind(queue_t *pqueue, int n);
 *    Pop and discard the newest 'n' items of size pqueue->item_size
 */
queue_ret_t QUEUE_Rewind(queue_t *pqueue, int n) {
  // No-op if n=0
  if (n == 0) {
    return QUEUE_OK;
  }
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  // n = min(n, fill-level)
  int fill = QUEUE_FillLevel(pqueue);
  n = n > fill ? fill : n;
  // Rewind pIn and wrap at boundary
  pqueue->pIn = (pqueue->pIn - n*(pqueue->item_size)) % QUEUE_MAX_SIZE;
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

/*
 * int QUEUE_ShiftOut(queue_t *pqueue, volatile void *pData, int len);
 *    Shift up to 'len' elements out of the queue
 */
int QUEUE_ShiftOut(queue_t *pqueue, volatile void *pData, int len) {
  int nShifted = 0;
  char *dest = (char *)pData;
  while (QUEUE_Get(pqueue, (void *)dest) != QUEUE_EMPTY) {
    dest += pqueue->item_size;
    if (++nShifted == len) {
      break;
    }
  }
  return nShifted;
}

/*
 * int QUEUE_ShiftIn(queue_t *pqueue, const void *pData, int len);
 *    Shift up to 'len' elements into the queue
 */
int QUEUE_ShiftIn(queue_t *pqueue, const void *pData, int len) {
  int nShifted = 0;
  char *src = (char *)pData;
  while (QUEUE_Add(pqueue, src) != QUEUE_FULL) {
    src += pqueue->item_size;
    if (++nShifted == len) {
      break;
    }
  }
  return nShifted;
}

// ============================= Static Functions ==============================
/*
 * static int _queue_bytefill(queue_t *pqueue);
 *    Return the number of bytes currently in the queue.
 */
static int _queue_bytefill(queue_t *pqueue) {
  if (pqueue->full) {
    return QUEUE_MAX_SIZE;
  } else if (pqueue->pIn == pqueue->pOut) {
    return 0;
  } else if (pqueue->pIn > pqueue->pOut) {
    return (int)(pqueue->pIn - pqueue->pOut);
  } else {
    return (int)(QUEUE_MAX_SIZE + pqueue->pIn - pqueue->pOut);
  }
}


/*
 * static queue_ret_t _queue_addbyte(queue_t *pqueue, void *item);
 *    Add a single byte of data from 'item' and increment pointer.
 *    Returns QUEUE_FULL if queue is full, otherwise QUEUE_OK
 */
static queue_ret_t _queue_addbyte(queue_t *pqueue, void *item) {
  // If full, return error
  if (pqueue->full) {
    //printf("  QUEUE_Add FULL!\r\n");
    return QUEUE_FULL;
  }
  // Copy item into queue
  *(char *)&(pqueue->queue[pqueue->pIn]) = *(char *)item;
  // Wrap pIn at boundary
  if (pqueue->pIn == QUEUE_MAX_SIZE - 1) {
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

static queue_ret_t _queue_getbyte(queue_t *pqueue, volatile void *item) {
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    //printf("  QUEUE_Get EMPTY!\r\n");
    return QUEUE_EMPTY;
  }
  // Copy next byte from the queue to item
  *(char *)item = *(char *)&(pqueue->queue[pqueue->pOut]);
  // Wrap pOut at boundary
  if (pqueue->pOut == QUEUE_MAX_SIZE - 1) {
    pqueue->pOut = 0;
  } else {
    pqueue->pOut++;
  }
  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}

static queue_ret_t _queue_popbyte(queue_t *pqueue, volatile void *item) {
  // Check for empty queue
  if ((pqueue->pIn == pqueue->pOut) && (pqueue->full == 0)) {
    return QUEUE_EMPTY;
  }
  // Rewind pIn and wrap at boundary
  if (pqueue->pIn == 0) {
    pqueue->pIn = QUEUE_MAX_SIZE - 1;
  } else {
    pqueue->pIn--;
  }
  // Copy newest data from the queue to item
  *(char *)item = *(char *)&(pqueue->queue[pqueue->pIn]);

  // Clear full condition
  pqueue->full = 0;
  return QUEUE_OK;
}
