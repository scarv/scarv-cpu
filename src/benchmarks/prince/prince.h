
#include <stdint.h>

#ifndef _PRINCE_H
#define _PRINCE_H


/*!
@brief perform a single encryption of a prince block.
@param k0 - upper 64 bits of key
@param k1 - lower 64 bits of key
*/
uint64_t prince_enc(uint64_t in, uint64_t k0, uint64_t k1);


/*!
@brief perform a single decryption of a prince block.
@param k0 - upper 64 bits of key
@param k1 - lower 64 bits of key
*/
uint64_t prince_dec(uint64_t in, uint64_t k0, uint64_t k1);

#endif
