
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
) {

    for(int i = 0; i < 16; i+=4) {
        out[i+0] = in[0][i+0];
        out[i+1] = in[0][i+1];
        out[i+2] = in[0][i+2];
        out[i+3] = in[0][i+3];
    }
    
    for(int j = 1; j < SME_SMAX; j++) {
        for(int i = 0; i < 16; i+=4) {
            out[i+0] ^= in[j][i+0];
            out[i+1] ^= in[j][i+1];
            out[i+2] ^= in[j][i+2];
            out[i+3] ^= in[j][i+3];
        }
    }

}

#endif


