
#include <stdint.h>

#include "unit_test.h"

#include "api_sha256.h"

uint32_t H[ 8];
uint32_t M[16];

int test_main(){
    __putstr("Benchmark: SHA-256\n");

    uint32_t cycles, instrs;

    MEASURE_PERF_BEGIN("hash")
    sha256_hash_block(H,M);
    MEASURE_PERF_END("hash", instrs, cycles)

    __putstr("SHA256 Cycles: "); __puthex32(cycles); __putchar('\n');
    __putstr("SHA256 Instrs: "); __puthex32(instrs); __putchar('\n');

    return 0;
}
