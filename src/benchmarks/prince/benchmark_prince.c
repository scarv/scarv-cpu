

#include <stdint.h>

#include "unit_test.h"

#include "prince.h"

const int num_prince_vectors = 5;

uint64_t prince_test_vectors[5][4] = {
// plaintext       ,  k0              ,  k1              ,  cipher
{0x0000000000000000,0x0000000000000000,0x0000000000000000,0x818665aa0d02dfda},
{0xffffffffffffffff,0x0000000000000000,0x0000000000000000,0x604ae6ca03c20ada},
{0x0000000000000000,0xffffffffffffffff,0x0000000000000000,0x9fb51935fc3df524},
{0x0000000000000000,0x0000000000000000,0xffffffffffffffff,0x78a54cbe737bb7ef},
{0x0123456789abcdef,0x0000000000000000,0xfedcba9876543210,0xae25ad3ca8fa9ccf},
};

int test_main(){
    __putstr("Benchmark: Prince\n");

    uint32_t cycles_enc, instrs_enc;

     for(int i = 0; i < num_prince_vectors; i++) {

        uint64_t ct        ;
        uint64_t plaintext = prince_test_vectors[i][0];
        uint64_t k0        = prince_test_vectors[i][1];
        uint64_t k1        = prince_test_vectors[i][2];
        uint64_t ciphertext= prince_test_vectors[i][3];

        uint64_t enc_result= 0;
        uint64_t dec_result= 0;

        MEASURE_PERF_BEGIN("enc")
        ct = prince_enc(plaintext, k0, k1);
        MEASURE_PERF_END("enc", instrs_enc, cycles_enc)

        if(ct != ciphertext) {
            test_fail();
        }

        __putstr("\n");
        __putstr("Enc Cycles: "); __puthex32(cycles_enc); __putchar('\n');
        __putstr("Enc Instrs: "); __puthex32(instrs_enc); __putchar('\n');
    }

    return 0;
}
