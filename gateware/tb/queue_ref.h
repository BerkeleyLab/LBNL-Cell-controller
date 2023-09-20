/*  file: queue_ref.h
 *  Desc: Universal Queue Structure; Static reference
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
#define QUEUE_MAX_ITEMS                       (2000)
#define QUEUE_OK                              (0x00)
#define QUEUE_FULL                            (0x01)
#define QUEUE_EMPTY                           (0x02)

// Handy alias
#define QUEUE_Clear                       QUEUE_Init
// ============================= Exported Typedefs =============================
typedef unsigned char queue_item_t;   // Re-define as needed
typedef int queue_index_t;  // Re-define if needed for larger/smaller QUEUE_MAX_ITEMS
typedef unsigned char queue_ret_t;

typedef struct {
  queue_index_t pIn;
  queue_index_t pOut;
  queue_ret_t full;
  queue_item_t queue[QUEUE_MAX_ITEMS];
} queue_t;

// ======================= Exported Function Prototypes ========================
void QUEUE_Init(queue_t *pqueue);
queue_ret_t QUEUE_Status(queue_t *pqueue);
queue_index_t QUEUE_FillLevel(queue_t *pqueue);
queue_ret_t QUEUE_Add(queue_t *pqueue, queue_item_t *item);
queue_ret_t QUEUE_Get(queue_t *pqueue, volatile queue_item_t *item);
queue_ret_t QUEUE_Load(queue_t *pqueue, volatile queue_item_t *item);
queue_ret_t QUEUE_Inc(queue_t *pqueue);
queue_ret_t QUEUE_Pop(queue_t *pqueue, volatile queue_item_t *item);
queue_ret_t QUEUE_Rewind(queue_t *pqueue, queue_index_t n);
queue_index_t QUEUE_ShiftOut(queue_t *pqueue, queue_item_t *pData, queue_index_t len);

#ifdef __cplusplus
}
#endif

#endif // ___QUEUE_REF_H

