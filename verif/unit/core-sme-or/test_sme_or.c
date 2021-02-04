
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

    register int rs1 asm ("x16") = scarv_cpu_pollentropy();
    register int rs2 asm ("x17") = scarv_cpu_pollentropy();
    register int rd  asm ("x18") ;
    expected = rs1 | rs2;

    // Turn on SME with SMAX shares
    sme_on(smax);

    SME_MASK(rs1, rs1);
    SME_MASK(rs2, rs2);

    rd = rs1 | rs2;

    SME_STORE(rd_shares, rd, EXPECTED_SMAX);
    
    // Turn off SME
    sme_off();

    int got = rd_shares[0] ^ rd_shares[1] ^ rd_shares[2];

    if(got != expected) {
        test_fail();
    }

    return 0;

}
