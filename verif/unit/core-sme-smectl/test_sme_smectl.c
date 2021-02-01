
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

int test_main() {

    // This is tied to a hardware parameter.
    const int expected_smax = 3;

    //
    // Testcase - Can SME be turned off correctly?
    __putstr("0\n");

    sme_off();
    int rv = sme_ctlr();
    if(rv != 0){
        test_fail();
    }

    //
    // Testcase - Can we get the max number of shares properly?
    __putstr("1\n");
    int smax = sme_get_smax();
    rv       = sme_ctlr();
    if(smax != expected_smax) {test_fail();}
    if(rv   != 0) {test_fail();}

    //
    // Testcase - Can we turn SME on and use the max number of shares?
    __putstr("2\n");
    sme_on(smax);
    rv       = sme_ctlr();
    if(rv   != expected_smax << 5) {test_fail();}

    //
    // Testcase - Can we turn SME off again?
    __putstr("3\n");
    sme_off();
    rv       = sme_ctlr();
    if(rv   != 0) {test_fail();}

    //
    // Testcase - Can we set arithmetic / boolean masking?
    __putstr("4\n");
    sme_use_boolean();
    rv       = sme_ctlr();
    if(rv   != 0) {test_fail();}
    
    sme_use_arithmetic();
    rv       = sme_ctlr();
    if(rv   != 0x10) {test_fail();}
    
    sme_use_boolean();
    rv       = sme_ctlr();
    if(rv   != 0) {test_fail();}

    //
    // Testcase - Can we iterate over bank numbers?
    __putstr("5\n");
    sme_on(smax);
    rv  = sme_ctlr();
    rv += 1;
    for(int i = 1; i < smax; i ++) {
        sme_ctlw(rv);
        rv += 1;
    }
    rv      = sme_ctlr();
    if(rv != ((expected_smax<<5) | (expected_smax-1))) {test_fail();}

    //
    // Testcase - Can SME be turned off correctly?
    __putstr("6\n");

    sme_off();
    rv = sme_ctlr();
    if(rv != 0){
        test_fail();
    }

    return 0;

}
