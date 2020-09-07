
#include <stdint.h>

#include "unit_test.h"

#include "api_sm3.h"

uint32_t S[16];

int test_main(){
    __putstr("Benchmark: SM3\n");

    uint32_t cycles, instrs;

    MEASURE_PERF_BEGIN("hash")
    rv32_sm3_compress(S);
    MEASURE_PERF_END("hash", instrs, cycles)

    __putstr("SM3 Cycles: "); __puthex32(cycles); __putchar('\n');
    __putstr("SM3 Instrs: "); __puthex32(instrs); __putchar('\n');

    return 0;
}
