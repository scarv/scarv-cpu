
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

#ifndef SME_SMAX
#define SME_SMAX  3
#endif

#define FUNC(A,B) (A^B)

uint32_t lhs[SME_SMAX];
uint32_t rhs[SME_SMAX];
uint32_t rd [SME_SMAX];

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

extern void sme_xor(
    uint32_t * lhs,
    uint32_t * rhs,
    uint32_t * rd ,
    const size_t  n
);

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(SME_SMAX != smax) {test_fail();}

    // Fill the input arrays with random values.
    fill_array_with_randomness(&lhs[0], SME_SMAX);
    fill_array_with_randomness(&rhs[0], SME_SMAX);

    // Turn on SME with SMAX shares
    sme_on(smax);
    
    // Do the secure XOR
    sme_xor(lhs, rhs, rd, smax);
    
    // Turn off SME
    sme_off();

    // Check the results are all correct.
    for(int i = 0; i < smax; i ++) {
        if(rd[i] != FUNC(lhs[i] , rhs[i])) {
            __puthex32(    i );
            __putchar(' ');
            __puthex32(lhs[i]);
            __putchar('^');
            __puthex32(rhs[i]);
            __putchar(' ' );
            __puthex32(rd [i]);
            test_fail();
        }
    }


    return 0;

}
