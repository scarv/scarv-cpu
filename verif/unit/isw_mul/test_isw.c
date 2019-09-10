
#include <stdint.h>

#include "unit_test.h"

/*!
@brief Return a random value.
*/
#define get_random(rd) __asm__ volatile ("xc.rngsamp %0" : "=r"(rd) :)

/*!
@brief Declaration of the ISW-4 multiplication function
@param input  a - Operand A shares
@param input  b - Operand B shares
@param input  d - Degree of masking
@param output c - Result shares
*/
extern void mul_isw(uint32_t * a, uint32_t * b, uint32_t d, uint32_t * c);

#define NSHARES 2

int test_main() {

    uint32_t a;
    uint32_t b;

    uint32_t shares_a[  NSHARES]; //!< Split shares of input variable A
    uint32_t shares_b[  NSHARES]; //!< Split shares of input variable B
    uint32_t shares_c[  NSHARES]; //!< Split shares of output variable C

    // Load A/B from the input data arrays
    a = 0x12340567;
    b = 0x76504321;

    //
    // Compute the shares of a and b

    shares_a[NSHARES-1] = 0;
    shares_b[NSHARES-1] = 0;

    // Create shares of A and B.
    for(int i = 0; i < (NSHARES-1); i ++) {

        uint32_t r1 = 0;
        uint32_t r2 = 0;
         
        get_random(r1);
        get_random(r2);
        
        shares_a[i] = r1;
        shares_b[i] = r2;
        
        shares_a[NSHARES-1] ^= r1;
        shares_b[NSHARES-1] ^= r2;

    }

    shares_a[NSHARES-1] ^= a;
    shares_b[NSHARES-1] ^= b;

    // Perform the multiplication inside the trigger region.
    mul_isw(shares_a, shares_b, NSHARES, shares_c);

    uint32_t actual_result = 0;
    uint32_t expect_result = a & b;

    for(int i = 0; i < NSHARES; i ++) {
        actual_result ^= shares_c[i];
    }
    
    __putstr("A: "); __puthex32(a); __putchar('\n');
    __putstr("B: "); __puthex32(b); __putchar('\n');

    __putstr("SHARES: A, B, C\n");
    for(int i = 0; i < NSHARES; i ++) {
        __puthex32(shares_a[i]);
        __putstr(", ");
        __puthex32(shares_b[i]);
        __putstr(", ");
        __puthex32(shares_c[i]);
        __putchar('\n');
    }

    __putstr("Expected: "); __puthex32(expect_result); __putchar('\n');
    __putstr("Got     : "); __puthex32(actual_result); __putchar('\n');

    if(actual_result == expect_result) {
        return 0;
    }
    else {
        __putstr("Wrong result");
        return 1;
    }

}

