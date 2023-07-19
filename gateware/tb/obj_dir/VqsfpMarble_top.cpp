// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VqsfpMarble_top.h"
#include "VqsfpMarble_top__Syms.h"

//============================================================
// Constructors

VqsfpMarble_top::VqsfpMarble_top(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VqsfpMarble_top__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , GPIO_STROBE{vlSymsp->TOP.GPIO_STROBE}
    , GPIO_IN{vlSymsp->TOP.GPIO_IN}
    , GPIO_OUT{vlSymsp->TOP.GPIO_OUT}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VqsfpMarble_top::VqsfpMarble_top(const char* _vcname__)
    : VqsfpMarble_top(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VqsfpMarble_top::~VqsfpMarble_top() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VqsfpMarble_top___024root___eval_debug_assertions(VqsfpMarble_top___024root* vlSelf);
#endif  // VL_DEBUG
void VqsfpMarble_top___024root___eval_static(VqsfpMarble_top___024root* vlSelf);
void VqsfpMarble_top___024root___eval_initial(VqsfpMarble_top___024root* vlSelf);
void VqsfpMarble_top___024root___eval_settle(VqsfpMarble_top___024root* vlSelf);
void VqsfpMarble_top___024root___eval(VqsfpMarble_top___024root* vlSelf);

void VqsfpMarble_top::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VqsfpMarble_top::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VqsfpMarble_top___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VqsfpMarble_top___024root___eval_static(&(vlSymsp->TOP));
        VqsfpMarble_top___024root___eval_initial(&(vlSymsp->TOP));
        VqsfpMarble_top___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VqsfpMarble_top___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VqsfpMarble_top::eventsPending() { return false; }

uint64_t VqsfpMarble_top::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VqsfpMarble_top::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VqsfpMarble_top___024root___eval_final(VqsfpMarble_top___024root* vlSelf);

VL_ATTR_COLD void VqsfpMarble_top::final() {
    VqsfpMarble_top___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VqsfpMarble_top::hierName() const { return vlSymsp->name(); }
const char* VqsfpMarble_top::modelName() const { return "VqsfpMarble_top"; }
unsigned VqsfpMarble_top::threads() const { return 1; }
