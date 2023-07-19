// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VqsfpMarble_top.h for the primary calling header

#include "verilated.h"

#include "VqsfpMarble_top___024root.h"

void VqsfpMarble_top___024root___eval_act(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_act\n"); );
}

VL_INLINE_OPT void VqsfpMarble_top___024root___nba_sequent__TOP__0(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*7:0*/ qsfpMarble_top__DOT__readData;
    qsfpMarble_top__DOT__readData = 0;
    // Body
    if (vlSelf->GPIO_STROBE) {
        vlSelf->qsfpMarble_top__DOT__readAddress = 
            (0x1ffU & vlSelf->GPIO_OUT);
    }
    qsfpMarble_top__DOT__readData = vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram
        [(0x800U | ((IData)((0x10U == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                     ? 0x80U : ((IData)((2U == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                 ? 0x84U : ((IData)(
                                                    (0x16U 
                                                     == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                             ? 0x85U
                                             : ((IData)(
                                                        (0x1aU 
                                                         == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                 ? 0x87U
                                                 : 
                                                ((IData)(
                                                         (0x22U 
                                                          == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                  ? 0x89U
                                                  : 
                                                 ((IData)(
                                                          (0x80U 
                                                           == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                   ? 0x91U
                                                   : 
                                                  ((IData)(
                                                           (0x94U 
                                                            == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                    ? 0U
                                                    : 
                                                   ((IData)(
                                                            (0xa8U 
                                                             == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                     ? 0x10U
                                                     : 
                                                    ((IData)(
                                                             (0xb8U 
                                                              == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                      ? 0x20U
                                                      : 
                                                     ((IData)(
                                                              (0xbaU 
                                                               == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                       ? 0x22U
                                                       : 
                                                      ((IData)(
                                                               (0xc4U 
                                                                == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                        ? 0x24U
                                                        : 
                                                       ((IData)(
                                                                (0xd4U 
                                                                 == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                         ? 0x34U
                                                         : 
                                                        ((IData)(
                                                                 (0x110U 
                                                                  == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                          ? 0x81U
                                                          : 
                                                         ((IData)(
                                                                  (0x102U 
                                                                   == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                           ? 0x93U
                                                           : 
                                                          ((IData)(
                                                                   (0x116U 
                                                                    == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                            ? 0x94U
                                                            : 
                                                           ((IData)(
                                                                    (0x11aU 
                                                                     == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                             ? 0x96U
                                                             : 
                                                            ((IData)(
                                                                     (0x122U 
                                                                      == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                              ? 0x98U
                                                              : 
                                                             ((IData)(
                                                                      (0x180U 
                                                                       == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                               ? 0xa0U
                                                               : 
                                                              ((IData)(
                                                                       (0x194U 
                                                                        == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                                ? 0x3cU
                                                                : 
                                                               ((IData)(
                                                                        (0x1a8U 
                                                                         == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                                 ? 0x4cU
                                                                 : 
                                                                ((IData)(
                                                                         (0x1b8U 
                                                                          == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                                  ? 0x5cU
                                                                  : 
                                                                 ((IData)(
                                                                          (0x1baU 
                                                                           == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                                   ? 0x5eU
                                                                   : 
                                                                  ((IData)(
                                                                           (0x1c4U 
                                                                            == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                                    ? 0x60U
                                                                    : 
                                                                   ((IData)(
                                                                            (0x1d4U 
                                                                             == (IData)(vlSelf->qsfpMarble_top__DOT__readAddress)))
                                                                     ? 0x70U
                                                                     : 0U)))))))))))))))))))))))))];
    vlSelf->GPIO_IN = (((IData)(vlSelf->qsfpMarble_top__DOT__i2c_updated) 
                        << 9U) | (((IData)(vlSelf->qsfpMarble_top__DOT__i2c_run_stat) 
                                   << 8U) | (IData)(qsfpMarble_top__DOT__readData)));
}

void VqsfpMarble_top___024root___eval_nba(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_nba\n"); );
    // Body
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VqsfpMarble_top___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void VqsfpMarble_top___024root___eval_triggers__act(VqsfpMarble_top___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___dump_triggers__act(VqsfpMarble_top___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___dump_triggers__nba(VqsfpMarble_top___024root* vlSelf);
#endif  // VL_DEBUG

void VqsfpMarble_top___024root___eval(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        __VnbaContinue = 0U;
        vlSelf->__VnbaTriggered.clear();
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            vlSelf->__VactContinue = 0U;
            VqsfpMarble_top___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    VqsfpMarble_top___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("./qsfpMarble_top.v", 5, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                VqsfpMarble_top___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                VqsfpMarble_top___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("./qsfpMarble_top.v", 5, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            VqsfpMarble_top___024root___eval_nba(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
void VqsfpMarble_top___024root___eval_debug_assertions(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->GPIO_STROBE & 0xfeU))) {
        Verilated::overWidthError("GPIO_STROBE");}
}
#endif  // VL_DEBUG
