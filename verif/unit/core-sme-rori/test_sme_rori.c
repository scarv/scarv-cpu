
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

#ifndef SME_SMAX
#define SME_SMAX  3
#endif

#define FUNC(A,B) ((A>>B) | (A<<(32-B)))

uint32_t expected;
uint32_t rd_shares [SME_SMAX];

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(SME_SMAX != smax) {test_fail();}

    register unsigned int rs1 asm ("x16") = scarv_cpu_pollentropy();
    const    unsigned int sh              = 8;
    register unsigned int rd  asm ("x18") ;
    expected = FUNC(rs1,sh);

    // Turn on SME with SMAX shares
    sme_on(smax);

    SME_MASK(rs1, rs1);

    SME_RORI(rd, rs1, sh);

    SME_STORE(rd_shares, rd, SME_SMAX);
    
    // Turn off SME
    sme_off();

    int got = 0;
    for( int i =0; i < smax; i++) {
        got ^= rd_shares[i];
    }

    if(got != expected) {
        test_fail();
    }

    return 0;

}
