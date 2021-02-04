
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

#define EXPECTED_SMAX  3
#define NREGS         16

uint32_t share_array_in [EXPECTED_SMAX][NREGS];
uint32_t share_array_out[EXPECTED_SMAX][NREGS];

void fill_array_with_randomness(
    uint32_t *  ain ,
    size_t      alen
){
    for(size_t i = 0; i < alen; i++) {
        // Awful hacky way to get some random ish values. Not how
        // pollentropy is supposed to be used!
        uint32_t sample  = scarv_cpu_pollentropy() << 16;
                 sample ^= scarv_cpu_pollentropy()      ;
        ain[i] = sample;
    }
}

extern void sme_move_all_shares(
    uint32_t * sarry,
    const size_t  n ,
    uint32_t * tarry
);

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(EXPECTED_SMAX != smax) {test_fail();}

    // Fill the input array with random values.
    fill_array_with_randomness(&share_array_in[1][0], EXPECTED_SMAX*NREGS);
    
    // Move all of the shares into the SME registers and out agian to mem..
    sme_move_all_shares(&share_array_in[1][0], smax, &share_array_out[1][0]);
    
    sme_off();

    // Check what we coppied out is what we coppied in.
    for(int bank = 1; bank < smax; bank ++) {
        //__putstr("Bank: ");__puthex32(bank);__putchar('\n');
        for(int reg  = 0; reg < 16; reg ++) {
            //__puthex32(reg);__putchar('\n');
            if(share_array_in[bank][reg] != share_array_out[bank][reg]) {
                test_fail();
            }
        }
    }

    return 0;

}
