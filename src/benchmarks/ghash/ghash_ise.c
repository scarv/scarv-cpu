
//  ghash_baseline.c
//  2020-03-23  Markku-Juhani O. Saarinen <mjos@pqshield.com>
//  Copyright (c) 2020, PQShield Ltd. All rights reserved.

//  32-bit GHASH bit-reverse and multiplication for GCM

#include "ghash.h"

//  disable shift reduction
#define NO_SHIFTRED

// Reverse bits in bytes
static inline uint32_t grev_7(uint32_t x) {
    uint32_t rd;
    asm("grev %0, %1, 7": "=r"(rd) :"r"(x));
    return rd;
}

static inline uint32_t clmul (uint32_t x, uint32_t y) {
    uint32_t rd = 0;
    asm("clmul %0, %1, %2": "=r"(rd) :"r"(x), "r"(y));
    return rd;
}

static inline uint32_t clmulh(uint32_t x, uint32_t y) {
    uint32_t rd = 0;
    asm("clmulh %0, %1, %2": "=r"(rd) :"r"(x), "r"(y));
    return rd;
}

//  multiply z = ( z ^ rev(x) ) * h
//  32-bit compact loop version

void ghash_mul(gf128_t * z, const gf128_t * x, const gf128_t * h)
{
	int i;
	uint32_t x0, x1, x2, x3, y;
	uint32_t z0, z1, z2, z3, z4;
	uint32_t t0, t1, t2;

	x0 = x->w[0];							//  new data
	x1 = x->w[1];
	x2 = x->w[2];
	x3 = x->w[3];

	z0 = z->w[0];							//  inline to avoid these loads
	z1 = z->w[1];
	z2 = z->w[2];
	z3 = z->w[3];

	//  4 x GREV
	x0 = grev_7(x0);					//  reverse input x only
	x1 = grev_7(x1);
	x2 = grev_7(x2);
	x3 = grev_7(x3);

	//  4 x XOR
	x0 = x0 ^ z0;							//  z is kept unreversed
	x1 = x1 ^ z1;
	x2 = x2 ^ z2;
	x3 = x3 ^ z3;

	//  4 x CMULH, 4 x CLMUL, 3 x XOR
	y = h->w[3];							//  start from highest word
	z4 = clmulh(x3, y);
	z3 = clmul(x3, y);
	t1 = clmulh(x2, y);
	z2 = clmul(x2, y);
	z3 = z3 ^ t1;
	t1 = clmulh(x1, y);
	z1 = clmul(x1, y);
	z2 = z2 ^ t1;
	t1 = clmulh(x0, y);
	z0 = clmul(x0, y);
	z1 = z1 ^ t1;

#ifdef NO_SHIFTRED
	//  Mul reduction: 1 x CLMULH, 1 x CLMUL, 2 x XOR
	t1 = clmulh(z4, 0x87);
	t0 = clmul(z4, 0x87);
	z1 = z1 ^ t1;
	z0 = z0 ^ t0;
#else
	//  Shift reduction: 6 x SHIFT, 7 x XOR
	z1 = z1 ^ (z4 >> 31) ^ (z4 >> 30) ^ (z4 >> 25);
	z0 = z0 ^ z4 ^ (z4 << 1) ^ (z4 << 2) ^ (z4 << 7);
#endif

	//  repeat 3 times
	for (i = 2; i >= 0; i--) {				//  towards less significant

		y = h->w[i];						//  unroll this if you like

		//  4 x CLMULH, 4 x CLMUL, 7 x XOR
		t1 = clmulh(x3, y);
		t0 = clmul(x3, y);
		z4 = z3 ^ t1;
		t1 = clmulh(x2, y);
		t2 = clmul(x2, y);
		z3 = z2 ^ t0 ^ t1;
		t1 = clmulh(x1, y);
		t0 = clmul(x1, y);
		z2 = z1 ^ t1 ^ t2;
		t1 = clmulh(x0, y);
		t2 = clmul(x0, y);
		z1 = z0 ^ t0 ^ t1;

#ifdef NO_SHIFTRED
		//  Mul reduction: 1 x CLMULH, 1 x CLMUL, 2 x XOR
		t1 = clmulh(z4, 0x87);
		t0 = clmul(z4, 0x87);
		z1 = z1 ^ t1;
		z0 = t2 ^ t0;
#else
		//  Shift reduction: 6 x SHIFT, 7 x XOR
		z1 = z1 ^ (z4 >> 31) ^ (z4 >> 30) ^ (z4 >> 25);
		z0 = t2 ^ z4 ^ (z4 << 1) ^ (z4 << 2) ^ (z4 << 7);
#endif

	}

	z->w[0] = z0;							//  inline to remove store
	z->w[1] = z1;
	z->w[2] = z2;
	z->w[3] = z3;
}

//  multiply z = ( z ^ rev(x) ) * h
//  32-bit Karatsuba version

void ghash_mul_kar(gf128_t * z, const gf128_t * x, const gf128_t * h)
{
	uint32_t x0, x1, x2, x3, y0, y1, y2, y3;
	uint32_t z0, z1, z2, z3, z4, z5, z6, z7;
	uint32_t t0, t1, t2, t3;

	x0 = x->w[0];							//  load new data
	x1 = x->w[1];
	x2 = x->w[2];
	x3 = x->w[3];

	z0 = z->w[0];							//  inline to avoid these loads
	z1 = z->w[1];
	z2 = z->w[2];
	z3 = z->w[3];

	y0 = h->w[0];							//  y is untouched
	y1 = h->w[1];
	y2 = h->w[2];
	y3 = h->w[3];

	//  4 x GREV
	x0 = grev_7(x0);					//  reverse input x only
	x1 = grev_7(x1);
	x2 = grev_7(x2);
	x3 = grev_7(x3);

	//  4 x XOR
	x0 = x0 ^ z0;							//  z is updated
	x1 = x1 ^ z1;
	x2 = x2 ^ z2;
	x3 = x3 ^ z3;

	//  2-level Karatsuba multiplication
	//  9 x CLMULH, 9 x CLMUL, 40 x XOR

	z7 = clmulh(x3, y3);				//  high pair
	z6 = clmul(x3, y3);
	z5 = clmulh(x2, y2);
	z4 = clmul(x2, y2);
	t0 = x2 ^ x3;
	t2 = y2 ^ y3;
	t1 = clmulh(t0, t2);
	t0 = clmul(t0, t2);
	t1 = t1 ^ z5 ^ z7;
	t0 = t0 ^ z4 ^ z6;
	z6 = z6 ^ t1;
	z5 = z5 ^ t0;

	z3 = clmulh(x1, y1);				//  low pair
	z2 = clmul(x1, y1);
	z1 = clmulh(x0, y0);
	z0 = clmul(x0, y0);
	t0 = x0 ^ x1;
	t2 = y0 ^ y1;
	t1 = clmulh(t0, t2);
	t0 = clmul(t0, t2);
	t1 = t1 ^ z1 ^ z3;
	t0 = t0 ^ z0 ^ z2;
	z2 = z2 ^ t1;
	z1 = z1 ^ t0;

	t3 = y1 ^ y3;							//  split
	t2 = y0 ^ y2;
	t1 = x1 ^ x3;
	t0 = x0 ^ x2;

	x3 = clmulh(t1, t3);				//  middle
	x2 = clmul(t1, t3);
	x1 = clmulh(t0, t2);
	x0 = clmul(t0, t2);

	t0 = t0 ^ t1;
	t2 = t2 ^ t3;
	t1 = clmulh(t0, t2);
	t0 = clmul(t0, t2);
	t1 = t1 ^ x1 ^ x3;
	t0 = t0 ^ x0 ^ x2;
	x2 = x2 ^ t1;
	x1 = x1 ^ t0;

	x3 = x3 ^ z3 ^ z7;						//  finalize
	x2 = x2 ^ z2 ^ z6;
	x1 = x1 ^ z1 ^ z5;
	x0 = x0 ^ z0 ^ z4;
	z5 = z5 ^ x3;
	z4 = z4 ^ x2;
	z3 = z3 ^ x1;
	z2 = z2 ^ x0;

	//  == REDUCTION ==

#ifdef NO_SHIFTRED
	//  Mul reduction: 4 x CLMULH, 4 x CLMUL, 8 x XOR
	t1 = clmulh(z7, 0x87);
	t0 = clmul(z7, 0x87);
	z4 = z4 ^ t1;
	z3 = z3 ^ t0;
	t1 = clmulh(z6, 0x87);
	t0 = clmul(z6, 0x87);
	z3 = z3 ^ t1;
	z2 = z2 ^ t0;
	t1 = clmulh(z5, 0x87);
	t0 = clmul(z5, 0x87);
	z2 = z2 ^ t1;
	z1 = z1 ^ t0;
	t1 = clmulh(z4, 0x87);
	t0 = clmul(z4, 0x87);
	z1 = z1 ^ t1;
	z0 = z0 ^ t0;
#else
	//  Shift reduction: 24 x SHIFT, 28 x XOR
	z4 = z4 ^ (z7 >> 31) ^ (z7 >> 30) ^ (z7 >> 25);
	z3 = z3 ^ z7 ^ (z7 << 1) ^ (z7 << 2) ^ (z7 << 7) ^
		(z6 >> 31) ^ (z6 >> 30) ^ (z6 >> 25);
	z2 = z2 ^ z6 ^ (z6 << 1) ^ (z6 << 2) ^ (z6 << 7) ^
		(z5 >> 31) ^ (z5 >> 30) ^ (z5 >> 25);
	z1 = z1 ^ z5 ^ (z5 << 1) ^ (z5 << 2) ^ (z5 << 7) ^
		(z4 >> 31) ^ (z4 >> 30) ^ (z4 >> 25);
	z0 = z0 ^ z4 ^ (z4 << 1) ^ (z4 << 2) ^ (z4 << 7);
#endif

	z->w[0] = z0;							//  inline to remove store
	z->w[1] = z1;
	z->w[2] = z2;
	z->w[3] = z3;
}

