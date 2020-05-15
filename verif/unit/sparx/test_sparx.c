
#include "unit_test.h"
#include "sparx_64_128.h"
    
uint16_t key[]          = {0x0011, 0x2233, 0x4455, 0x6677,
                           0x8899, 0xaabb, 0xccdd, 0xeeff};
uint16_t plaintext[]    = {0x0123, 0x4567, 0x89ab, 0xcdef};
uint16_t ciphertext[]   = {0x2bbe, 0xf152, 0x01f5, 0x5f98};

uint16_t mkey    [2*8];
uint16_t msubkey [2*SK_LEN];

uint16_t mask = 0x0000;

int test_main() {
    
	uint16_t m[4];      
	uint16_t c[4];
    
    for(int i = 0; i < 8; i ++){
        mkey[i  ] = key[i] ^ mask;
        mkey[i+8] =          mask;
    }

    for(int i = 0; i < 4; i ++){
        c[i] = ciphertext[i];
        m[i] = plaintext [i];
    }

    bmsk_sparx_64_128_key_exp_asm(msubkey, mkey);
    
    for(int i  =0; i < SK_LEN; i+=2) {
        __puthex16(msubkey[i+1]); __putchar(' ');
        __puthex16(msubkey[i  ]); __putchar('\n');
    }

    return 1;

    bmsk_sparx_64_128_encrypt_asm(m, msubkey);

    for(int i  =0; i < 4; i++) {
        __puthex16(m[i]); __putchar(' ');
        __puthex16(ciphertext[i]); __putchar('\n');
        if(m[i] != ciphertext[i]) {
            __putstr("Sparx Encrypt Fail\n.");
            return 1;
        }
    }
    
    bmsk_sparx_64_128_decrypt_asm(c, msubkey);
    for(int i  =0; i < 4; i++) {
        if(c[i] != plaintext[i]) {
            __putstr("Sparx Decrypt Fail\n.");
            return 1;
        }
    }

    __putstr("Sparx Pass");

    return 0;

}
