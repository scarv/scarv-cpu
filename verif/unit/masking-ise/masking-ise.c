
#include "unit_test.h"

extern uint32_t test_masked_and(uint32_t a, uint32_t b);

void print_result_expectation(
    uint32_t lhs,
    uint32_t rhs,
    uint32_t result,
    uint32_t expected) {
    __putstr("- Expected: "); __puthex32(expected); __putchar('\n');
    __putstr("- Got     : "); __puthex32(result  ); __putchar('\n');
}

int test_main() {
    
    int fail = 0;

    uint32_t lhs = 0xABCD0123;
    uint32_t rhs = 0xDEADBEAD;

    __putstr("# Masking ISE Unit Test\n");

    uint32_t result_and = test_masked_and(lhs, rhs);
    uint32_t expect_and = (lhs & rhs);

    if(result_and != expect_and) {
        __putstr("test_masked_and [FAIL]\n");
        print_result_expectation(lhs,rhs,result_and,expect_and);
        return 1;
    }

    return fail;

}

