
#include "unit_test.h"
#include "speck.h"
    
const int TV_PY = 0;
const int TV_PX = 1;
const int TV_K0 = 2;
const int TV_K1 = 3; 
const int TV_K2 = 4;
const int TV_K3 = 5;
const int TV_CY = 6;
const int TV_CX = 7;


uint32_t test_vectors[1][8] = {
// y       ,  x        , k0        , k1        , k2        , k3        , c0        , c1
{0x7475432D, 0x3B726574, 0x03020100, 0x0B0A0908, 0x13121110, 0x1B1A1918, 0x454E028B, 0x8C6FA548},
};

// Constant mask to make debugging easier.
uint32_t mask = 0x0;

int test_main() {

    uint32_t k      [   4];
    uint32_t mk     [2* 4];
    uint32_t ekey   [2*27];
    uint32_t py, px;
    uint32_t cy, cx; 

    py   = test_vectors[0][TV_PY];
    px   = test_vectors[0][TV_PX];
    k[0] = test_vectors[0][TV_K0];
    k[1] = test_vectors[0][TV_K1]; 
    k[2] = test_vectors[0][TV_K2];
    k[3] = test_vectors[0][TV_K3];
    cy   = test_vectors[0][TV_CY];
    cx   = test_vectors[0][TV_CX];

    for(int i = 0; i< 4; i ++) {
        mk[i+4] = mask;
        mk[i  ] = k[i] ^ mask;
    }

    // Key expansion.
    bmsk_speck_key_exp_asm(ekey, mk);

    //for(int i = 0; i < 27; i++) {
    //    uint32_t s0 = ekey[i +  0];
    //    uint32_t s1 = ekey[i + 27];
    //    uint32_t k  = s0 ^ s1;
    //    __puthex32(k); __putchar('\n');
    //}

    // Encrypt.
    bmsk_speck_encrypt_asm(ekey, &px, &py);

    uint32_t grm_cx = test_vectors[0][TV_CX];
    uint32_t grm_cy = test_vectors[0][TV_CY];

    if((px != grm_cx) || (py != grm_cy)) {
        __putstr("Encrypt Fail.\n");
        __puthex32(px); __putchar(' '); __puthex32(py); __putchar('\n');
        __puthex32(grm_cx); __putchar(' ');__puthex32(grm_cy); __putchar('\n');
        return 1;
    }

    // Decrypt
    bmsk_speck_decrypt_asm(ekey, &cx, &cy);
    
    uint32_t grm_px = test_vectors[0][TV_PX];
    uint32_t grm_py = test_vectors[0][TV_PY];
    
    if((cx != grm_px) || (cy != grm_py)) {
        __putstr("Decrypt Fail.\n");
        __puthex32(    cx);__putchar(' ');__puthex32(    cy);__putchar('\n');
        __puthex32(grm_px);__putchar(' ');__puthex32(grm_py);__putchar('\n');
        return 1;
    }

    __putstr("Speck Pass");

    return 0;

}

