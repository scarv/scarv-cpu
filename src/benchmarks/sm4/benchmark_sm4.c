
#include <stdint.h>

#include "unit_test.h"

#include "api_sm4.h"

uint32_t sm4_rk [32];
uint8_t  sm4_mk [16];
uint8_t  sm4_pt [16];
uint8_t  sm4_ct [16];

int test_main(){
    __putstr("Benchmark: SM4\n");

    uint32_t cycles_ks , instrs_ks ;
    uint32_t cycles_enc, instrs_enc;

    MEASURE_PERF_BEGIN("ks")
    sm4_key_schedule_enc(sm4_rk, sm4_mk);
    MEASURE_PERF_END("ks", instrs_ks, cycles_ks)

    MEASURE_PERF_BEGIN("enc")
    sm4_block_enc_dec(sm4_ct, sm4_pt, sm4_rk);
    MEASURE_PERF_END("enc", instrs_enc, cycles_enc)

    __putstr("Enc Cycles: "); __puthex32(cycles_enc); __putchar('\n');
    __putstr("Enc Instrs: "); __puthex32(instrs_enc); __putchar('\n');
    __putstr("KS  Cycles: "); __puthex32(cycles_ks ); __putchar('\n');
    __putstr("KS  Instrs: "); __puthex32(instrs_ks ); __putchar('\n');

    return 0;
}
