
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

#define EXPECTED_SMAX  3
#define NREGS         16

#define FUNC(A,B) (A&B)

uint32_t rs1;
uint32_t rd [EXPECTED_SMAX];

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    const int smax = sme_get_smax();

    if(smax != EXPECTED_SMAX) {
        test_fail(); // Quit if we don't get the expected number of shares.
    }

    rs1 = scarv_cpu_pollentropy();

    register int tmp  asm("x16");
    register int tmp2 asm("x17");

    // Turn on SME with SMAX shares
    sme_on(smax);
    
    // En-mask the variable.
    SME_MASK(tmp,rs1);

    // Re-mask the variable
    SME_REMASK(tmp2, tmp);

    SME_STORE(rd, tmp2, EXPECTED_SMAX);

    // Turn off SME.
    sme_off();

    int unmasked = rd[0] ^ rd[1] ^ rd[2];
    if(unmasked != rs1) {
        test_fail();
    }

    return 0;

}
