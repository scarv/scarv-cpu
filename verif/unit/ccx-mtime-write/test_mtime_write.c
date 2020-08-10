
#include "unit_test.h"
#include "scarv_cpu_csp.h"

/*!
@brief Test reading of the standard performance counters/timers.
@note Assumes that all counters are reset to zero and do not roll over during
the test.
*/
int test_main() {


    // We should be able to read/write mtimecmp
    uint64_t new_mtimecmp_value = 0xABCD000012340000;
    scarv_cpu_set_mtimecmp(new_mtimecmp_value);

    if(scarv_cpu_get_mtimecmp() != new_mtimecmp_value) {
        return 6;
    }

    for(int i = 0; i < 10; i ++) {

        new_mtimecmp_value = scarv_cpu_get_mtimecmp() * 20;

        scarv_cpu_set_mtimecmp(new_mtimecmp_value);
    
        if(scarv_cpu_get_mtimecmp() != new_mtimecmp_value) {
            return 7;
        }
    }

    scarv_cpu_set_mtimecmp(-1UL);

    // We should be able to read/write mtime
    uint64_t new_mtime_value = 0xF000000000000000;

    scarv_cpu_set_mtime(new_mtime_value);
    
    uint64_t nxt_mtime_value = scarv_cpu_get_mtime() - new_mtime_value;

    if(nxt_mtime_value > new_mtimecmp_value) {
        return 8;
    }

    return 0;

}
