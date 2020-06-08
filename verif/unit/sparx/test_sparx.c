
#include "unit_test.h"
#include "sparx_64_128.h"
#include "bmsk_sparx_64_128.h"
    
uint16_t key[]          = {0x0011, 0x2233, 0x4455, 0x6677,
                           0x8899, 0xaabb, 0xccdd, 0xeeff};
uint16_t plaintext[]    = {0x0123, 0x4567, 0x89ab, 0xcdef};
uint16_t ciphertext[]   = {0x2bbe, 0xf152, 0x01f5, 0x5f98};

uint16_t c_key    [8      *2]; // vanilla cipher key.
uint16_t c_subkey [SK_LEN   ]; // vanilla expanded key.
uint16_t c_ptxt   [        4]; // plaintext
uint16_t c_ctxt   [        4]; // ciphertext

uint16_t m_key    [8      *2]; // Masked ASM cipher key.
uint16_t m_subkey [SK_LEN *2]; // Masked ASM expanded key.
uint16_t m_ptxt   [      2*4]; // plaintext
uint16_t m_ctxt   [      2*4]; // ciphertext

uint16_t mask = 0x0000;

int test_main() {

    //
    // Key Expansion
    
    for(int i = 0; i < 8; i ++){
        c_key[i  ] = key[i]       ;
        m_key[i  ] = key[i] ^ mask;
        m_key[i+8] =          mask;
    }
    
    // Expand key under normal C code implementation.
    MEASURE_PERF_BEGIN(SPARX_EXP)
    sparx_64_128_key_exp_asm     (c_subkey, c_key);
    MEASURE_PERF_END(SPARX_EXP)

    // Expand key under masked asm implementation.
    MEASURE_PERF_BEGIN(SPARX_MSK_EXP)
    bmsk_sparx_64_128_key_exp_asm(m_subkey, m_key);
    MEASURE_PERF_END(SPARX_MSK_EXP)

    for(int i = 0; i < SK_LEN; i ++) {
        uint32_t c_elem = c_subkey[i];
        uint32_t m_elem = m_subkey[i] ^ m_subkey[i+SK_LEN];
        
        //__puthex16(m_elem); __putchar(' ' );
        //__puthex16(c_elem); __putchar('\n');

        if(c_elem != m_elem) {
            //__putstr("Bad key schedule\n");
            return 1;
        }
    }


    //
    // Encrypt.

    for(int i = 0; i < 4; i ++) {
        c_ptxt[i  ] = plaintext[i]       ;
        m_ptxt[i  ] = plaintext[i] ^ mask;
        m_ptxt[i+4] =                mask;
    }

    // Encrypt under un-masked implementation.
    MEASURE_PERF_BEGIN(SPARX_ENC)
    sparx_64_128_encrypt_asm (c_ptxt, c_subkey);
    MEASURE_PERF_END(SPARX_ENC)

    // Encrypt under masked implementation.
    MEASURE_PERF_BEGIN(SPARX_MSK_ENC)
    bmsk_sparx_64_128_encrypt_asm (m_ptxt, m_subkey);
    MEASURE_PERF_END(SPARX_MSK_ENC)

    for(int i = 0; i < 4; i ++) {
        uint32_t c_elem = c_ptxt[i];
        uint32_t m_elem = m_ptxt[i] ^ m_ptxt[i+4];
        uint32_t g_elem = ciphertext[i];

        //__puthex16(g_elem); __putchar(' ' );
        //__puthex16(c_elem); __putchar(' ' );
        //__puthex16(m_elem); __putchar('\n');

        if(g_elem != c_elem) {
            __putstr("GRM != unmasked model\n");
            return 1;
        }
        if(c_elem != m_elem) {
            __putstr("Masked != unmasked model\n");
            return 2;
        }
    }

    // Encrypt under un-masked implementation.
    MEASURE_PERF_BEGIN(SPARX_DEC)
    sparx_64_128_decrypt_asm (c_ptxt, c_subkey);
    MEASURE_PERF_END(SPARX_DEC)

    // Encrypt under masked implementation.
    MEASURE_PERF_BEGIN(SPARX_MSK_DEC)
    bmsk_sparx_64_128_decrypt_asm (m_ptxt, m_subkey);
    MEASURE_PERF_END(SPARX_MSK_DEC)

    return 0;

}
