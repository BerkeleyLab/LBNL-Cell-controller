// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VqsfpMarble_top.h for the primary calling header

#ifndef VERILATED_VQSFPMARBLE_TOP___024ROOT_H_
#define VERILATED_VQSFPMARBLE_TOP___024ROOT_H_  // guard

#include "verilated.h"

class VqsfpMarble_top__Syms;

class VqsfpMarble_top___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(GPIO_STROBE,0,0);
    CData/*0:0*/ qsfpMarble_top__DOT__i2c_updated;
    CData/*0:0*/ qsfpMarble_top__DOT__i2c_run_stat;
    CData/*0:0*/ __Vtrigrprev__TOP__clk;
    CData/*0:0*/ __VactContinue;
    SData/*8:0*/ qsfpMarble_top__DOT__readAddress;
    VL_OUT(GPIO_IN,31,0);
    VL_IN(GPIO_OUT,31,0);
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*7:0*/, 4097> qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    VqsfpMarble_top__Syms* const vlSymsp;

    // CONSTRUCTORS
    VqsfpMarble_top___024root(VqsfpMarble_top__Syms* symsp, const char* v__name);
    ~VqsfpMarble_top___024root();
    VL_UNCOPYABLE(VqsfpMarble_top___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard
