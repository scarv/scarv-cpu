
#include <stdint.h>

#include "unit_test.h"

#include "api_chacha20.h"

uint32_t blk_in [16];
uint32_t blk_out[16];

int test_main(){
    __putstr("Benchmark: ChaCha20\n");

    uint32_t cycles, instrs;

    MEASURE_PERF_BEGIN("block")
    chacha20_block(blk_out, blk_in);
    MEASURE_PERF_END("block", instrs, cycles)

    __putstr("ChaCha20 Cycles: "); __puthex32(cycles); __putchar('\n');
    __putstr("ChaCha20 Instrs: "); __puthex32(instrs); __putchar('\n');

    return 0;
}
