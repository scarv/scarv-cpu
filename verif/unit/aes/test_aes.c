
#include "unit_test.h"

#include "aes.h"
#include "intrinsics.h"

int test_aes_128() {

    int         tr  = 0               ;

    uint8_t     ck  [16] = {0x2b ,0x7e ,0x15 ,0x16 ,0x28 ,0xae ,0xd2 ,0xa6 ,
                            0xab ,0xf7 ,0x15 ,0x88 ,0x09 ,0xcf ,0x4f ,0x3c};
    uint8_t     pt  [16] = {0x32 ,0x43 ,0xf6 ,0xa8 ,0x88 ,0x5a ,0x30 ,0x8d ,
                            0x31 ,0x31 ,0x98 ,0xa2 ,0xe0 ,0x37 ,0x07 ,0x34};
    uint8_t     ct  [16];
    uint8_t     fi  [16];
    uint32_t    erk [AES_128_RK_WORDS];
    uint32_t    drk [AES_128_RK_WORDS];

    uint64_t    cycles_eks = __rd_mtime();
    uint64_t    insret_eks = __rdinstret();

    aes_128_enc_key_schedule(erk, ck);
    
    cycles_eks = __rd_mtime () - cycles_eks;
    insret_eks = __rdinstret() - insret_eks;

    uint64_t    cycles_enc = __rd_mtime();
    uint64_t    insret_enc = __rdinstret();

    aes_128_enc_block(ct, pt, erk);
    
    cycles_enc = __rd_mtime () - cycles_enc;
    insret_enc = __rdinstret() - insret_enc;
    
    uint64_t    cycles_dks = __rd_mtime();
    uint64_t    insret_dks = __rdinstret();
    
    aes_128_dec_key_schedule(drk, ck);
    
    cycles_dks = __rd_mtime () - cycles_dks;
    insret_dks = __rdinstret() - insret_dks;
    
    uint64_t    cycles_dec = __rd_mtime();
    uint64_t    insret_dec = __rdinstret();

    aes_128_dec_block(fi, ct, drk);
    
    cycles_dec = __rd_mtime () - cycles_dec;
    insret_dec = __rdinstret() - insret_dec;

    for(int i = 0; i < 16; i ++){
        if(pt[i] != fi[i]) {
            tr |= 1;
        }
    }

    __putstr("pt : "); __puthexstr(pt , 16); __putchar('\n');
    __putstr("ct : "); __puthexstr(ct , 16); __putchar('\n');
    __putstr("fi : "); __puthexstr(fi , 16); __putchar('\n');
    __putstr("ck : "); __puthexstr(ck , 16); __putchar('\n');
    __putstr("erk: "); __puthexstr((uint8_t*)erk, AES_128_RK_BYTES); __putchar('\n');
    __putstr("drk: "); __puthexstr((uint8_t*)drk, AES_128_RK_BYTES); __putchar('\n');

    __putstr("!> ");
    __puthex64(cycles_eks); __putchar(',');
    __puthex64(cycles_enc); __putchar(',');
    __puthex64(cycles_dks); __putchar(',');
    __puthex64(cycles_dec); __putchar('\n');
    __putstr("?> ");
    __puthex64(insret_eks); __putchar(',');
    __puthex64(insret_enc); __putchar(',');
    __puthex64(insret_dks); __putchar(',');
    __puthex64(insret_dec); __putchar('\n');

    return tr;
}

int test_main() {

    __putstr("--- Test AES 128 ---\n");

    int result_aes_128 = test_aes_128();

    return result_aes_128;

}
