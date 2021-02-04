
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

#define EXPECTED_SMAX  3
#define NREGS         16

#define FUNC(A,B) (A^B)

uint32_t expected;
uint32_t rd_shares [EXPECTED_SMAX];

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(EXPECTED_SMAX != smax) {test_fail();}

    register unsigned int rs1 asm ("x16") = scarv_cpu_pollentropy();
             unsigned int sh              = 8;
    register unsigned int rd  asm ("x18") ;
    expected = rs1 >> sh;

    // Turn on SME with SMAX shares
    sme_on(smax);

    SME_MASK(rs1, rs1);

    rd = rs1 >> sh;

    SME_STORE(rd_shares, rd, EXPECTED_SMAX);
    
    // Turn off SME
    sme_off();

    int got = rd_shares[0] ^ rd_shares[1] ^ rd_shares[2];

    if(got != expected) {
        test_fail();
    }

    return 0;

}
