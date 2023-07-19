// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VqsfpMarble_top.h for the primary calling header

#include "verilated.h"

#include "VqsfpMarble_top___024root.h"

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_static(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_static\n"); );
}

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_initial__TOP(VqsfpMarble_top___024root* vlSelf);

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_initial(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_initial\n"); );
    // Body
    VqsfpMarble_top___024root___eval_initial__TOP(vlSelf);
    vlSelf->__Vtrigrprev__TOP__clk = vlSelf->clk;
}

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_initial__TOP(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_initial__TOP\n"); );
    // Body
    vlSelf->qsfpMarble_top__DOT__i2c_updated = 0U;
    vlSelf->qsfpMarble_top__DOT__i2c_run_stat = 0U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0U] = 0x71U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[1U] = 0x73U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[2U] = 0x66U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[3U] = 0x70U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[4U] = 0x2eU;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[5U] = 0x63U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[6U] = 0x6fU;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[7U] = 0x6dU;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[8U] = 0x20U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[9U] = 0x70U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0xaU] = 0x61U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0xbU] = 0x72U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0xcU] = 0x74U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0xdU] = 0x79U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0xeU] = 0U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0xfU] = 0U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x80U] = 0x47U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x81U] = 0x77U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x10U] = 0x54U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x11U] = 0x48U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x12U] = 0x41U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x13U] = 0x54U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x14U] = 0x2dU;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x15U] = 0x4fU;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x16U] = 0x4cU;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x17U] = 0x20U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x18U] = 0x51U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x19U] = 0x53U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x1aU] = 0x46U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x1bU] = 0x50U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x1cU] = 0U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x1dU] = 0U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x1eU] = 0U;
    vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[0x1fU] = 0U;
}

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_final(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_final\n"); );
}

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_triggers__stl(VqsfpMarble_top___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___dump_triggers__stl(VqsfpMarble_top___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___eval_stl(VqsfpMarble_top___024root* vlSelf);

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_settle(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_settle\n"); );
    // Init
    CData/*0:0*/ __VstlContinue;
    // Body
    vlSelf->__VstlIterCount = 0U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        __VstlContinue = 0U;
        VqsfpMarble_top___024root___eval_triggers__stl(vlSelf);
        if (vlSelf->__VstlTriggered.any()) {
            __VstlContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VstlIterCount))) {
#ifdef VL_DEBUG
                VqsfpMarble_top___024root___dump_triggers__stl(vlSelf);
#endif
                VL_FATAL_MT("./qsfpMarble_top.v", 5, "", "Settle region did not converge.");
            }
            vlSelf->__VstlIterCount = ((IData)(1U) 
                                       + vlSelf->__VstlIterCount);
            VqsfpMarble_top___024root___eval_stl(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___dump_triggers__stl(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VstlTriggered.at(0U)) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void VqsfpMarble_top___024root___stl_sequent__TOP__0(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___stl_sequent__TOP__0\n"); );
    // Init
    CData/*7:0*/ qsfpMarble_top__DOT__readData;
    qsfpMarble_top__DOT__readData = 0;
    // Body
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

VL_ATTR_COLD void VqsfpMarble_top___024root___eval_stl(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___eval_stl\n"); );
    // Body
    if (vlSelf->__VstlTriggered.at(0U)) {
        VqsfpMarble_top___024root___stl_sequent__TOP__0(vlSelf);
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___dump_triggers__act(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VactTriggered.at(0U)) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void VqsfpMarble_top___024root___dump_triggers__nba(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void VqsfpMarble_top___024root___ctor_var_reset(VqsfpMarble_top___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VqsfpMarble_top__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VqsfpMarble_top___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->GPIO_IN = VL_RAND_RESET_I(32);
    vlSelf->GPIO_OUT = VL_RAND_RESET_I(32);
    vlSelf->GPIO_STROBE = VL_RAND_RESET_I(1);
    vlSelf->qsfpMarble_top__DOT__readAddress = VL_RAND_RESET_I(9);
    vlSelf->qsfpMarble_top__DOT__i2c_updated = VL_RAND_RESET_I(1);
    vlSelf->qsfpMarble_top__DOT__i2c_run_stat = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 4097; ++__Vi0) {
        vlSelf->qsfpMarble_top__DOT__qsfpMarble_i__DOT__ram[__Vi0] = VL_RAND_RESET_I(8);
    }
    vlSelf->__Vtrigrprev__TOP__clk = VL_RAND_RESET_I(1);
}
