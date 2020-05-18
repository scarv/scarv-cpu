
#include "unit_test.h"
#include "sparx_64_128.h"
#include "bmsk_sparx_64_128.h"
    
uint16_t key[]          = {0x0011, 0x2233, 0x4455, 0x6677,
                           0x8899, 0xaabb, 0xccdd, 0xeeff};
uint16_t plaintext[]    = {0x0123, 0x4567, 0x89ab, 0xcdef};
uint16_t ciphertext[]   = {0x2bbe, 0xf152, 0x01f5, 0x5f98};

uint16_t c_key    [8      *2]; // C code cipher key.
uint16_t c_subkey [SK_LEN   ]; // C code expanded key.

uint16_t m_key    [8      *2]; // ASM cipher key.
uint16_t m_subkey [SK_LEN *2]; // ASM expanded key.

uint16_t mask = 0x0000;

int test_main() {
    
    for(int i = 0; i < 8; i ++){
        c_key[i  ] = key[i]       ;
        m_key[i  ] = key[i] ^ mask;
        m_key[i+8] =          mask;
    }
    
    // Expand key under normal C code implementation.
    sparx_64_128_key_exp         (c_subkey, c_key);

    // Expand key under masked asm implementation.
    bmsk_sparx_64_128_key_exp_asm(m_subkey, m_key);

    for(int i = 0; i < SK_LEN; i ++) {
        uint32_t c_elem = c_subkey[i];
        uint32_t m_elem = m_subkey[i] ^ m_subkey[i+SK_LEN];
        if(c_elem != m_elem) {
            return 1;
        }
    }


    return 0;

}
