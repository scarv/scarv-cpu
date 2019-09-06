
#include <stdio.h>

#include "embench.h"

//! Main entry point, called from boot.S
int main() {

    int i;
    volatile int result;
    int correct;

    __putstr("Initialise Bechmark...\n");

    initialise_benchmark ();
    
    __putstr("Run Bechmark...\n");

    uint64_t i_start = __rdinstret();
    uint64_t c_start = __rdcycle();
    
    result = benchmark ();
    
    uint64_t i_end   = __rdinstret();
    uint64_t c_end   = __rdcycle();

    uint64_t count_instrs = i_end - i_start;
    uint64_t count_cycles = c_end - c_start;

    char buf[255];
    sprintf(buf, "%lu", count_cycles);
    __putstr("Cycles: "); __putstr(buf); __putchar('\n');

    sprintf(buf, "%lu", count_instrs);
    __putstr("Instrs: "); __putstr(buf); __putchar('\n');
    
    __putstr("Verify Bechmark...\n");

    correct = verify_benchmark (result);
    
    __putstr("--- Finished --- \n");

    return (!correct);

}
