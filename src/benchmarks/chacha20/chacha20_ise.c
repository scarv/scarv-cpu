
#include "api_chacha20.h"

static inline uint32_t ROTL(uint32_t x, int y) {
    uint32_t rd;
    asm ("rori %0, %1, 32-%2" :"=r"(rd) :"r"(x), "i"(y));
    return rd;
}

#define QR(a, b, c, d) (			\
	a += b,  d ^= a,  d = ROTL(d,16),	\
	c += d,  b ^= c,  b = ROTL(b,12),	\
	a += b,  d ^= a,  d = ROTL(d, 8),	\
	c += d,  b ^= c,  b = ROTL(b, 7))

#define CHACHA20_ROUNDS 20

//! A vanilla implementation of the ChaCha20 block function.
void chacha20_block(uint32_t out[16], uint32_t const in[16])
{
	int i;
	uint32_t x[16];

	x[ 0] = in[ 0];
	x[ 1] = in[ 1];
	x[ 2] = in[ 2];
	x[ 3] = in[ 3];
	x[ 4] = in[ 4];
	x[ 5] = in[ 5];
	x[ 6] = in[ 6];
	x[ 7] = in[ 7];
	x[ 8] = in[ 8];
	x[ 9] = in[ 9];
	x[10] = in[10];
	x[11] = in[11];
	x[12] = in[12];
	x[13] = in[13];
	x[14] = in[14];
	x[15] = in[15];

	for (i = 0; i < CHACHA20_ROUNDS; i += 2)
    {
		// Odd round
		QR(x[0], x[4], x[ 8], x[12]); // column 0
		QR(x[1], x[5], x[ 9], x[13]); // column 1
		QR(x[2], x[6], x[10], x[14]); // column 2
		QR(x[3], x[7], x[11], x[15]); // column 3

		// Even round
		QR(x[0], x[5], x[10], x[15]); // diagonal 1
		QR(x[1], x[6], x[11], x[12]); // diagonal 2
		QR(x[2], x[7], x[ 8], x[13]); // diagonal 3
		QR(x[3], x[4], x[ 9], x[14]); // diagonal 4
	}

	for (i = 0; i < 16; ++i) {
		out[i] = x[i] + in[i];
    }
}

