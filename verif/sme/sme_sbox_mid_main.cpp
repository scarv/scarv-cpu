
#include <verilated.h>          // Defines common routines
#include "verilated_vcd_c.h"
#include <iostream>             // Need std::cout
#include "Vtb_sme_sboxes_sbox_inv_mid.h" 

using namespace std;

Vtb_sme_sboxes_sbox_inv_mid *top; // Instantiation of module

vluint64_t main_time = 0;       // Current simulation time
// This is a 64-bit integer to reduce wrap over issues and
// allow modulus.  This is in units of the timeprecision
// used in Verilog (or from --timescale-override)

double sc_time_stamp () {       // Called by $time in Verilog
    return main_time;           // converts to double, to match
                                // what SystemC does
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);   // Remember args
    Verilated::traceEverOn(true);

    top = new Vtb_sme_sboxes_sbox_inv_mid; 

    top->g_resetn= 0;           // Set some inputs

    while (!Verilated::gotFinish() and main_time <= 10000) {
        if (main_time > 10) {
            top->g_resetn= 1;   // Deassert reset
        }
        if ((main_time % 10) == 1) {
            top->g_clk = 1;       // Toggle clock - posedge
        }
        if ((main_time % 10) == 6) {
            top->g_clk = 0;
        }
        top->eval();            // Evaluate model
        main_time++;            // Time passes...
    }

    top->final();               // Done simulating
    //    // (Though this example doesn't get here)
    delete top;
}
