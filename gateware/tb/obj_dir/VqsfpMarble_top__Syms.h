// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VQSFPMARBLE_TOP__SYMS_H_
#define VERILATED_VQSFPMARBLE_TOP__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "VqsfpMarble_top.h"

// INCLUDE MODULE CLASSES
#include "VqsfpMarble_top___024root.h"

// SYMS CLASS (contains all model state)
class VqsfpMarble_top__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    VqsfpMarble_top* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    VqsfpMarble_top___024root      TOP;

    // CONSTRUCTORS
    VqsfpMarble_top__Syms(VerilatedContext* contextp, const char* namep, VqsfpMarble_top* modelp);
    ~VqsfpMarble_top__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard
