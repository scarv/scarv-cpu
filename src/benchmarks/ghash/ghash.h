
#include <stdint.h>

#ifndef __GHASH_H__
#define __GHASH_H__

typedef union {
	uint8_t b[16];
	uint32_t w[4];
	uint64_t d[2];
} gf128_t;

//  32-bit compact version (rv32_ghash.c)
void ghash_mul(gf128_t * z, const gf128_t * x, const gf128_t * h);

//  32-bit karatsuba version (rv32_ghash.c)
void ghash_mul_kar(gf128_t * z, const gf128_t * x, const gf128_t * h);


#endif

