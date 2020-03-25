
#include "unit_test.h"

#include "aes.h"

int test_aes_128() {

    int         tr  = 0               ;

    uint8_t     pt  [16              ];
    uint8_t     ct  [16              ];
    uint8_t     fi  [16              ];
    uint8_t     ck  [AES_128_CK_BYTES];
    uint32_t    erk [AES_128_RK_WORDS];
    uint32_t    drk [AES_128_RK_WORDS];

    aes_128_enc_key_schedule(erk, ck);
    aes_128_enc_block(ct, pt, erk);
    
    aes_128_dec_key_schedule(drk, ck);
    aes_128_dec_block(fi, ct, drk);

    for(int i = 0; i < 16; i ++){
        if(pt[i] != fi[i]) {
            tr |= 1;
        }
    }

    __putstr("pt: "); __puthexstr(pt, 16); __putchar('\n');
    __putstr("ct: "); __puthexstr(ct, 16); __putchar('\n');
    __putstr("fi: "); __puthexstr(fi, 16); __putchar('\n');
    __putstr("ck: "); __puthexstr(ck, 16); __putchar('\n');

    return tr;
}

int test_main() {

    __putstr("--- Test AES 128 ---\n");

    int result_aes_128 = test_aes_128();

    return result_aes_128;

}
