
#include <stdint.h>

#ifndef __SME_CHACHA20_H__
#define __SME_CHACHA20_H__

#ifndef SME_SMAX
#define SME_SMAX 3
#endif

void sme_chacha20_block(
    uint32_t out[SME_SMAX][16],
    uint32_t in [SME_SMAX][16]
);

void sme_chacha20_mask (
    uint32_t out[SME_SMAX][16],
    uint32_t in           [16]
);

void sme_chacha20_unmask (
    uint32_t out          [16],
    uint32_t in [SME_SMAX][16]
);

#endif


