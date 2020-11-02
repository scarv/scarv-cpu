
#include <stdint.h>

#include "unit_test.h"

#include "scarv_cpu_csp.h"

#define TEST_N 10

uint32_t pollentropy_samples [TEST_N];

int test_main() {

    // Read mentropy a few times.
    for(int i  = 0 ; i < TEST_N; i ++) {
        pollentropy_samples[i] = scarv_cpu_pollentropy();
    }

    // Set NOISE_TEST, check pollentropy always returns BIST.
    uint32_t mnoise = scarv_cpu_getnoise_rd();
    if(mnoise != 0) {
        // after reset, expect 0.
        test_fail();
    }

    // Put us in noise test mode.
    scarv_cpu_getnoise_wr(SCARV_CPU_MNOISE_NOISETEST);
    mnoise = scarv_cpu_getnoise_rd();
    if(mnoise >> 31 != 1) {
        // We should now be in noise test mode.
        test_fail();
    }

    // Read mentropy a few times.
    for(int i  = 0 ; i < TEST_N; i ++) {
        uint32_t mentropy = scarv_cpu_pollentropy();

        uint32_t opst     = mentropy >> 30;
        uint32_t seed     = mentropy & 0xFFFF;

        if(opst != SCARV_CPU_POLLENTROPY_BIST) {
            // Should always return BIST when in noise test mode.
            test_fail();
        }

        if(seed != 0) {
            // Seed should be zero when not returning ES16.
            test_fail();
        }
    }
    
    // Clear noise test mode.
    scarv_cpu_getnoise_wr(0x0);
    mnoise = scarv_cpu_getnoise_rd();
    if(mnoise != 0) {
        test_fail();
    }
    
    // Read mentropy a few more times.
    for(int i  = 0 ; i < TEST_N; i ++) {
        uint32_t mentropy = scarv_cpu_pollentropy();

        uint32_t opst     = mentropy >> 30;
        uint32_t seed     = mentropy & 0xFFFF;

        if(opst != SCARV_CPU_POLLENTROPY_ES16) {
            if(seed != 0) {
                // Seed should be zero when not returning ES16.
                test_fail();
            }
        }

    }
    
    return 0;

}
