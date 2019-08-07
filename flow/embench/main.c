
#include "embench.h"

//! Main entry point, called from boot.S
int main() {

    int i;
    volatile int result;
    int correct;

    initialise_benchmark ();

    uint64_t i_start = __rdinstret();
    uint64_t c_start = __rdinstret();
    
    result = benchmark ();
    
    uint64_t i_end   = __rdinstret();
    uint64_t c_end   = __rdinstret();

    uint64_t count_instrs = i_end - i_start;
    uint64_t count_cycles = c_end - c_start;

    correct = verify_benchmark (result);

    return (!correct);

}
