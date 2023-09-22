/* Verilator device simulator
 */

#include "VqsfpMarble_top.h"
#include "verilated.h"
#include <signal.h>
#include <stdio.h>
#include "qsfp.h"

#define TRAPEXIT
static int toExit = 0;

VqsfpMarble_top *top = new VqsfpMarble_top;

int main(int argc, char** argv, char** env) {
  //VerilatedContext *contextp = new VerilatedContext;
  //contextp->commandArgs(argc, argv);
  Verilated::commandArgs(argc, argv);
  printf("qsfpMarble Top-level Simulator\r\n");
  printf("  Run with +udp_port=NNNN to use an alternate port\r\n");
  // Initialize
  top->clk = 0;
  top->eval();
  // Generic variables to look for changes
  int v = 0;
  int v_0 = 0;
  int w = 0;
  int w_0 = 0;
  int setup_counter = 0;
  while (!toExit) {
    // System clock (125 MHz)
    top->clk = ~top->clk;
    // Logic
    top->GPIO_STROBE = 0;
    top->eval();
    if (setup_counter > 2) {
      //qsfpShowVendor();
      qsfpShowInfo();
      toExit = 1;
    }
    setup_counter++;
  }
  printf("End\n");
  top->final();
  delete top;
  //delete contextp;
  return 0;
}

#ifdef TRAPEXIT
static void _sigHandler(int c) {
  printf("Exiting...\r\n");
  toExit = 1;
  return;
}
#endif

uint32_t vtb_In32(uint32_t addr) {
  top->clk = ~top->clk;
  top->eval();
  top->clk = ~top->clk;
  top->eval();
  return top->GPIO_IN;
}

void vtb_Out32(uint32_t val) {
  top->GPIO_OUT = val;
  top->GPIO_STROBE = 1;
  top->eval();
  top->clk = ~top->clk;
  top->eval();
  top->clk = ~top->clk;
  top->GPIO_STROBE = 0;
  return;
}
