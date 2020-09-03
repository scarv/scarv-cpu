
#include <stdint.h>

#include "unit_test.h"

#include "api_aes.h"

uint8_t  aes128_pt [AES_BLOCK_BYTES  ];
uint8_t  aes128_ct [AES_BLOCK_BYTES  ];
uint8_t  aes128_ck [AES_128_KEY_BYTES];
uint32_t aes128_rk [AES_128_RK_WORDS ];

int test_main(){
    __putstr("Benchmark: AES 128\n");

    uint32_t cycles_ks , instrs_ks ;
    uint32_t cycles_enc, instrs_enc;

    MEASURE_PERF_BEGIN("ks")
    aes_128_enc_key_schedule(aes128_rk, aes128_ck);
    MEASURE_PERF_END("ks", instrs_ks, cycles_ks)

    MEASURE_PERF_BEGIN("enc")
    aes_128_ecb_encrypt(aes128_ct, aes128_pt, aes128_rk);
    MEASURE_PERF_END("enc", instrs_enc, cycles_enc)

    __putstr("Enc Cycles: "); __puthex32(cycles_enc); __putchar('\n');
    __putstr("Enc Instrs: "); __puthex32(instrs_enc); __putchar('\n');
    __putstr("Enc KS    : "); __puthex32(cycles_ks ); __putchar('\n');
    __putstr("Enc KS    : "); __puthex32(instrs_ks ); __putchar('\n');

    return 0;
}
