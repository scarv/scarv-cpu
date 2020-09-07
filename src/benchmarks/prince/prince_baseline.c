
/*
Code adapted for the SCARV project from:
- https://github.com/sebastien-riou/prince-c-ref

Originally written by Sebastien Riou
*/

#include <stdint.h>

#include "prince.h"

static uint64_t prince_round_consts[] = {
    0x0000000000000000,
    0x13198a2e03707344,
    0xa4093822299f31d0,
    0x082efa98ec4e6c89,
    0x452821e638d01377,
    0xbe5466cf34e90c6c,
    0x7ef84f78fd955cb1,
    0x85840851f1ac43aa,
    0xc882d32f25323c54,
    0x64a51195e0e3610d,
    0xd3b5a399ca0c2399,
    0xc0ac29b7c97c50dd
};


//! Prince forward SBOX
static uint64_t prince_sbox(const uint64_t s_in){
  uint64_t s_out = 0;
  const unsigned int sbox[] = {
    0xb, 0xf, 0x3, 0x2,
    0xa, 0xc, 0x9, 0x1,
    0x6, 0x7, 0x8, 0x0,
    0xe, 0x5, 0xd, 0x4
  };
  for(unsigned int i=0;i<16;i++){
    const unsigned int shift = i*4;
    const unsigned int sbox_in = (s_in>>shift) & 0xF;
    const uint64_t sbox_out = sbox[sbox_in];
    s_out |= sbox_out<<shift;
  }
  return s_out;
}

static uint64_t prince_isbox(const uint64_t s_inv_in){
  uint64_t s_inv_out = 0;
  const unsigned int isbox[] = {
    0xb, 0x7, 0x3, 0x2,
    0xf, 0xd, 0x8, 0x9,
    0xa, 0x6, 0x4, 0x0,
    0x5, 0xe, 0xc, 0x1
  };
  for(unsigned int i=0;i<16;i++){
    const unsigned int shift = i*4;
    const unsigned int sbox_in = (s_inv_in>>shift) & 0xF;
    const uint64_t sbox_out = isbox[sbox_in];
    s_inv_out |= sbox_out<<shift;
  }
  return s_inv_out;
}

//! Galois field matrix multiplication
static uint64_t prince_gf_mul(const uint64_t in, const uint16_t mat[16]){
  uint64_t out = 0;
  for(unsigned int i=0;i<16;i++){
    if((in>>i) & 1)
      out ^= mat[i];
  }
  return out;
}


//! Matrix multiply step
static uint64_t prince_m_prime_layer(const uint64_t m_prime_in){
  static const uint16_t m16[2][16] = {
    {0x0111, 0x2220, 0x4404, 0x8088, 0x1011, 0x0222, 0x4440, 0x8808,
     0x1101, 0x2022, 0x0444, 0x8880, 0x1110, 0x2202, 0x4044, 0x0888},
    {0x1110, 0x2202, 0x4044, 0x0888, 0x0111, 0x2220, 0x4404, 0x8088,
     0x1011, 0x0222, 0x4440, 0x8808, 0x1101, 0x2022, 0x0444, 0x8880}
  };
  const uint64_t chunk0 = prince_gf_mul(m_prime_in>>(0*16),m16[0]);
  const uint64_t chunk1 = prince_gf_mul(m_prime_in>>(1*16),m16[1]);
  const uint64_t chunk2 = prince_gf_mul(m_prime_in>>(2*16),m16[1]);
  const uint64_t chunk3 = prince_gf_mul(m_prime_in>>(3*16),m16[0]);
  const uint64_t m_prime_out = (chunk3<<(3*16)) | (chunk2<<(2*16)) | (chunk1<<(1*16)) | (chunk0<<(0*16));
  return m_prime_out;
}


//! Shift rows step
static uint64_t prince_shift_rows(const uint64_t in, int inverse){
  const uint64_t row_mask = 0xF000F000F000F000;

  uint64_t shift_rows_out = 0;

  for(unsigned int i=0;i<4;i++){

    const uint64_t smask = (row_mask>>(4*i));
    const uint64_t row   = in & smask;

    const uint32_t shift = (inverse ? i*16 : 64-(i*16)) & 0x3f;

    shift_rows_out      |= (row>>shift) | (row<<(64-shift));

  }
  return shift_rows_out;
}


/*!
@brief Core prince function for encrypt/decrypt.
*/
static uint64_t prince_core(uint64_t in, uint64_t k1) {

  uint64_t round_input = in ^ k1 ^ prince_round_consts[0];

  for(unsigned int round = 1; round < 6; round++){

    uint64_t s_out          = prince_sbox(round_input);
    uint64_t m_prime_out    = prince_m_prime_layer(s_out);
    uint64_t shift_rows_out = prince_shift_rows(m_prime_out,0);

    round_input = shift_rows_out ^ k1 ^ prince_round_consts[round];

  }

  uint64_t middle_round_s_out     = prince_sbox(round_input);
  uint64_t m_prime_out            = prince_m_prime_layer(middle_round_s_out);
  uint64_t middle_round_s_inv_out = prince_isbox(m_prime_out);

  round_input = middle_round_s_inv_out;

  for(unsigned int round = 6; round < 11; round++){

    uint64_t m_inv_in       = round_input ^ k1 ^ prince_round_consts[round];
    uint64_t shift_rows_out = prince_shift_rows(m_inv_in,1);
    uint64_t m_prime_out    = prince_m_prime_layer(shift_rows_out);
    uint64_t s_inv_out      = prince_isbox(m_prime_out);

    round_input = s_inv_out;

  }

  const uint64_t core_output = round_input ^ k1 ^ prince_round_consts[11];

  return core_output;

}
/*!
@brief perform a single encryption of a prince block.
@param k0 - upper 64 bits of key
@param k1 - lower 64 bits of key
*/
uint64_t prince_enc(uint64_t in, uint64_t k0, uint64_t k1) {

    uint64_t k0p;

    k0p = ((k0 >> 1) | (k0 << 63)) ^ (k0 >> 63);

    uint64_t core_in  = in ^ k0;

    uint64_t core_out = prince_core(core_in, k1);

    uint64_t result   = core_out ^ k0p;

    return   result;

}


/*!
@brief perform a single decryption of a prince block.
@param k0 - upper 64 bits of key
@param k1 - lower 64 bits of key
*/
uint64_t prince_dec(uint64_t in, uint64_t k0, uint64_t k1) {

    uint64_t alpha    = 0xc0ac29b7c97c50dd;

    uint64_t k0p;

    k0p = ((k0 >> 1) | (k0 << 63)) ^ (k0 >> 63);

    uint64_t core_in  = in ^ k0p;

    uint64_t core_out = prince_core(core_in, k1 ^ alpha);

    return   core_out ^ k0;

}


