
#include "unit_test.h"
#include "chacha20.h"

// Constant mask to make debugging easier.
uint32_t mask = 0x0;

uint32_t block_in_c     [16] = {
   0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
   0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c,
   0x13121110, 0x17161514, 0x1b1a1918, 0x1f1e1d1c,
   0x00000001, 0x09000000, 0x4a000000, 0x00000000
};
uint32_t block_in_asm   [32] ;

uint32_t block_out_c    [16]  ;
uint32_t block_out_asm  [32]  ;

int test_main() {

    int fail = 0;

    // Setup input block for asm function.
    for(int i = 0; i < 16; i++) {
        block_in_asm[i     ] = block_in_c[i] ^ mask;
        block_in_asm[i + 16] =                 mask;
    }

    // Plain C block function.
    MEASURE_PERF_BEGIN(CHACHA20)
    chacha20_block(block_out_c, block_in_c);
    MEASURE_PERF_END(CHACHA20)

    // Boolean masked block function.
    MEASURE_PERF_BEGIN(CHACHA20_MSK)
    bmsk_chacha20_block_asm(block_out_asm, block_in_asm);
    MEASURE_PERF_END(CHACHA20_MSK)

    for(int i = 0; i < 16; i ++) {
        uint32_t out_c  = block_out_c[i];
        uint32_t out_asm= block_out_asm[i] ^ block_out_asm[i+16];

        if(out_c != out_asm) {
            fail |= 1;
            __puthex32(out_c  ); __putchar(' ');
            __puthex32(out_asm); __putchar(' ');
            __putchar('!');
            __putchar('\n');
        }
    }

    return fail;

}

