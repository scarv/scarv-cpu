
#include "unit_test.h"

extern uint32_t test_masked_not(uint32_t a);
extern uint32_t test_masked_and(uint32_t a, uint32_t b);
extern uint32_t test_masked_ior(uint32_t a, uint32_t b);
extern uint32_t test_masked_xor(uint32_t a, uint32_t b);
extern uint32_t test_masked_add(uint32_t a, uint32_t b);
extern uint32_t test_masked_sub(uint32_t a, uint32_t b);
extern uint32_t test_masked_srli(uint32_t a);
extern uint32_t test_masked_slli(uint32_t a);
extern uint32_t test_masked_rori(uint32_t a);
extern uint32_t test_masked_rori16(uint32_t a);
extern uint32_t test_masked_brm(uint32_t a);   //boolean remask
extern uint32_t test_masked_b2a(uint32_t a);
extern uint32_t test_masked_arm(uint32_t a);   //arithmetic remask
extern uint32_t test_masked_a2b(uint32_t a);


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

    uint32_t result_not = test_masked_not(lhs);
    uint32_t expect_not = (~lhs);

    if(result_not != expect_not) {
        __putstr("test_masked_not [FAIL]\n");
        print_result_expectation(lhs,rhs,result_not,expect_not);
        fail = 1;
    }

    uint32_t result_and = test_masked_and(lhs, rhs);
    uint32_t expect_and = (lhs & rhs);

    if(result_and != expect_and) {
        __putstr("test_masked_and [FAIL]\n");
        print_result_expectation(lhs,rhs,result_and,expect_and);
        fail = 1;
    }

    uint32_t result_ior = test_masked_ior(lhs, rhs);
    uint32_t expect_ior = (lhs | rhs);

    if(result_ior != expect_ior) {
        __putstr("test_masked_ior [FAIL]\n");
        print_result_expectation(lhs,rhs,result_ior,expect_ior);
        fail = 1;
    }

    uint32_t result_xor = test_masked_xor(lhs, rhs);
    uint32_t expect_xor = (lhs ^ rhs);

    if(result_xor != expect_xor) {
        __putstr("test_masked_xor [FAIL]\n");
        print_result_expectation(lhs,rhs,result_xor,expect_xor);
        fail = 1;
    }

    uint32_t result_add = test_masked_add(lhs, rhs);
    uint32_t expect_add = (lhs + rhs);

    if(result_add != expect_add) {
        __putstr("test_masked_add [FAIL]\n");
        print_result_expectation(lhs,rhs,result_add,expect_add);
        fail = 1;
    }

    uint32_t result_sub = test_masked_sub(lhs, rhs);
    uint32_t expect_sub = (lhs - rhs);

    if(result_sub != expect_sub) {
        __putstr("test_masked_sub [FAIL]\n");
        print_result_expectation(lhs,rhs,result_sub,expect_sub);
        fail = 1;
    }

    uint32_t result_srli= test_masked_srli(lhs);
    uint32_t expect_srli= (lhs >> 8);

    if(result_srli!= expect_srli) {
        __putstr("test_masked_srli [FAIL]\n");
        print_result_expectation(lhs,rhs,result_srli,expect_srli);
        fail = 1;
    }

    uint32_t result_slli= test_masked_slli(lhs);
    uint32_t expect_slli= (lhs << 8);

    if(result_slli!= expect_slli) {
        __putstr("test_masked_slli [FAIL]\n");
        print_result_expectation(lhs,rhs,result_slli,expect_slli);
        fail = 1;
    }

    uint32_t result_rori= test_masked_rori(lhs);
    uint32_t expect_rori= (lhs >> 8) | (lhs << (32-8));

    if(result_rori!= expect_rori) {
        __putstr("test_masked_rori [FAIL]\n");
        print_result_expectation(lhs,rhs,result_rori,expect_rori);
        fail = 1;
    }

    uint32_t result_brm = test_masked_brm(lhs); //boolean remask
    uint32_t expect_brm = (lhs);

    if(result_brm != expect_brm) {
        __putstr("test_masked_brm [FAIL]\n");
        print_result_expectation(lhs,rhs,result_brm,expect_brm);
        fail = 1;
    }

    // FIXME
    //uint32_t result_b2a = test_masked_b2a(lhs);
    //uint32_t expect_b2a = (lhs);

    //if(result_b2a != expect_b2a) {
    //    __putstr("test_masked_b2a [FAIL]\n");
    //    print_result_expectation(lhs,rhs,result_b2a,expect_b2a);
    //    fail = 1;
    //}

    uint32_t result_arm = test_masked_arm(lhs); //arithmetic remask
    uint32_t expect_arm = (lhs);

    if(result_arm != expect_arm) {
        __putstr("test_masked_arm [FAIL]\n");
        print_result_expectation(lhs,rhs,result_arm,expect_arm);
        fail = 1;
    }

    uint32_t result_a2b = test_masked_a2b(lhs);
    uint32_t expect_a2b = (lhs);

    if(result_a2b != expect_a2b) {
        __putstr("test_masked_a2b [FAIL]\n");
        print_result_expectation(lhs,rhs,result_a2b,expect_a2b);
        fail = 1;
    }

    return fail;

}

