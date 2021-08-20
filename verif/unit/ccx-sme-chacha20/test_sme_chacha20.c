
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"
#include "sme_chacha20.h"

#ifndef SME_SMAX
#define SME_SMAX  3
#endif

uint32_t input              [16] = {
   0x61707865, 0x3320646e, 0x79622d32, 0x6b206574,
   0x03020100, 0x07060504, 0x0b0a0908, 0x0f0e0d0c,
   0x13121110, 0x17161514, 0x1b1a1918, 0x1f1e1d1c,
   0x00000001, 0x09000000, 0x4a000000, 0x00000000
};
uint32_t output             [16];

uint32_t input_m  [SME_SMAX][16];
uint32_t output_m [SME_SMAX][16];


int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(SME_SMAX != smax) {test_fail();}
    
    sme_chacha20_mask(input_m, input);

    //
    // ChaCha20 block
    uint32_t cyc_block_start = scarv_cpu_rdcycle_lo();
    uint32_t ins_block_start = scarv_cpu_rdinstret_lo();
    sme_chacha20_block(output_m, input_m);
    uint32_t cyc_block_end   = scarv_cpu_rdcycle_lo();
    uint32_t ins_block_end   = scarv_cpu_rdinstret_lo();
    uint32_t cyc_block = cyc_block_end - cyc_block_start;
    uint32_t ins_block = ins_block_end - ins_block_start;

    sme_chacha20_unmask(output, output_m);

    __putstr("SMAX:                      : ");
    __puthex32(smax       );__putchar('\n');
    __putstr("ChaCha20 Block cycles/instrs: ");
    __puthex32(cyc_block);__putchar('/');
    __puthex32(ins_block);__putchar('\n');

    return 0;

}
