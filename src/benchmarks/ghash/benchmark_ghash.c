

#include <stdint.h>

#include "unit_test.h"

#include "ghash.h"

gf128_t z;
gf128_t x;
gf128_t h;

int test_main(){
    __putstr("Benchmark: ghash\n");

    uint32_t cycles_enc, instrs_enc;

    MEASURE_PERF_BEGIN("ghash_mul")
    ghash_mul(&z, &x, &h);
    MEASURE_PERF_END("ghash_mul", instrs_enc, cycles_enc)

    __putstr("Cycles: "); __puthex32(cycles_enc); __putchar('\n');
    __putstr("Instrs: "); __puthex32(instrs_enc); __putchar('\n');

    return 0;
}
