
#include <stdint.h>

#ifndef __SME_AES_H__
#define __SME_AES_H__

#ifndef SME_SMAX
#define SME_SMAX 3
#endif

#define AES128_RK_WORDS 44
#define AES_STATE_WORDS  4

typedef struct {
    uint32_t rk [SME_SMAX][AES128_RK_WORDS];
    uint32_t s            [AES_STATE_WORDS];
} sme_aes128_ctx_t;

void sme_aes128_enc_key_exp (
    uint32_t rk[SME_SMAX][AES128_RK_WORDS],
    uint32_t ck[4]
);

void sme_aes128_enc_block (
    uint32_t ct[4],
    uint32_t pt[4],
    uint32_t rk[SME_SMAX][AES128_RK_WORDS]
);

#endif

