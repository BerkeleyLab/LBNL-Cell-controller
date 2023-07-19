// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "VqsfpMarble_top__Syms.h"
#include "VqsfpMarble_top.h"
#include "VqsfpMarble_top___024root.h"

// FUNCTIONS
VqsfpMarble_top__Syms::~VqsfpMarble_top__Syms()
{
}

VqsfpMarble_top__Syms::VqsfpMarble_top__Syms(VerilatedContext* contextp, const char* namep, VqsfpMarble_top* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-9);
    _vm_contextp__->timeprecision(-9);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
}
