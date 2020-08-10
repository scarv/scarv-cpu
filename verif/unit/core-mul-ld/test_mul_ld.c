
#include "unit_test.h"

int load_value;

extern int test_mul_ld(int a, int b, int * c);

//
// Checks that a load immediately after a multiply loads the correct
// value into the GPR.
//
int test_main() {

    load_value = 0xfeedbeef;

    int mul_a = 0xfa5ce;
    int mul_b = 0x24576;
    
    // Returns (a*b)+c
    int dut_result = test_mul_ld(mul_a, mul_b, &load_value);

    int grm_result = (mul_a * mul_b) + load_value;

    if(dut_result != grm_result) {
        test_fail();
    }

    return 0;

}
