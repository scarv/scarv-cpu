
#include "unit_test.h"
#include "scarv_cpu_csp.h"

/*!
@brief Test reading of the standard performance counters/timers.
@note Assumes that all counters are reset to zero and do not roll over during
the test.
*/
int test_main() {

    uint64_t fst_mtime      = scarv_cpu_get_mtime();
    uint64_t fst_mtimecmp   = scarv_cpu_get_mtimecmp();

    uint64_t snd_mtime      = scarv_cpu_get_mtime();
    uint64_t snd_mtimecmp   = scarv_cpu_get_mtimecmp();

    if(fst_mtime > snd_mtime) {
        // Second reading of mtime should be a larger value.
        return 1;
    }
    
    if(fst_mtimecmp != snd_mtimecmp) {
        // mtimecmp should not have changed
        return 2;
    }
    
    return 0;

}
