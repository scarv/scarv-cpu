
#include "unit_test.h"
#include "scarv_cpu_csp.h"

/*!
@brief Test reading of the standard performance counters/timers.
@note Assumes that all counters are reset to zero and do not roll over during
the test.
*/
int test_main() {

    // The counters are enabled
    uint32_t enabled = scarv_cpu_get_mcountinhibit();
    
    if((enabled&0x7) != 0x0) {
        scarv_cpu_wr_mcountinhibit(0x0);
    }


    uint64_t a_cycle      = scarv_cpu_rdcycle();
    uint64_t a_time       = scarv_cpu_get_mtime();
    uint64_t a_instret    = scarv_cpu_rdinstret();

    uint64_t b_cycle      = scarv_cpu_rdcycle();
    uint64_t b_time       = scarv_cpu_get_mtime();
    uint64_t b_instret    = scarv_cpu_rdinstret();


    if(a_cycle >= b_cycle) {
        // Second reading of cycle should be larger
        return 1;
    }

    if(a_time >= b_time) {
        // Second reading of time should be larger
        return 2;
    }

    if(a_instret >= b_instret) {
        // Second reading of instret should be larger.
        return 3;
    }

    // Disable the cycle counter register
    scarv_cpu_wr_mcountinhibit(0x1);
    
    a_cycle      = scarv_cpu_rdcycle();
    a_time       = scarv_cpu_get_mtime();
    a_instret    = scarv_cpu_rdinstret();

    b_cycle      = scarv_cpu_rdcycle();
    b_time       = scarv_cpu_get_mtime();
    b_instret    = scarv_cpu_rdinstret();


    if(a_cycle != b_cycle) {
        // Cycle disabled, should be identical.
        return 4;
    }

    if(a_time >= b_time) {
        // Second reading of time should be larger
        return 5;
    }

    if(a_instret >= b_instret) {
        // Second reading of instret should be larger.
        return 6;
    }
    
    // Disable the time counter register, re-enable the cycle register.
    scarv_cpu_wr_mcountinhibit(0x2);
    
    a_cycle      = scarv_cpu_rdcycle();
    a_time       = scarv_cpu_get_mtime();
    a_instret    = scarv_cpu_rdinstret();

    b_cycle      = scarv_cpu_rdcycle();
    b_time       = scarv_cpu_get_mtime();
    b_instret    = scarv_cpu_rdinstret();

    if(a_cycle >= b_cycle) {
        // Cycle enabled, first reading should be smaller.
        return 7;
    }

    if(a_time == b_time) {
        // time register cannot be disabled.
        return 8;
    }

    if(a_instret >= b_instret) {
        // Second reading of instret should be larger.
        return 9;
    }
    
    // Disable the instr ret register, re-enable the time register.
    scarv_cpu_wr_mcountinhibit(0x4);
    
    a_cycle      = scarv_cpu_rdcycle();
    a_time       = scarv_cpu_get_mtime();
    a_instret    = scarv_cpu_rdinstret();

    b_cycle      = scarv_cpu_rdcycle();
    b_time       = scarv_cpu_get_mtime();
    b_instret    = scarv_cpu_rdinstret();

    if(a_cycle >= b_cycle) {
        // Cycle enabled, first reading should be smaller.
        return 10;
    }

    if(a_time >= b_time) {
        // time register enabled . first reading should be smaller.
        return 11;
    }

    if(a_instret != b_instret) {
        // instrret disabled, should not change.
        return 12;
    }
    
    scarv_cpu_wr_mcountinhibit(0x0);

    return 0;

}
