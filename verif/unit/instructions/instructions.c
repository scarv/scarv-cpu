
#include "unit_test.h"

int test_main() {

    uint32_t rs1 = 0xF0F0F0F0;
    uint32_t rs2 = 0x0F0F0F0F;
    uint32_t rd1,rd2,rd3;

    uint32_t sum = 0;

    __asm__ ("clmul %0, %1, %2" : "=r"(rd1) : "r"(rs1), "r"(rs2));
    __asm__ ("clmulr %0, %1, %2" : "=r"(rd2) : "r"(rs1), "r"(rs2));
    __asm__ ("xc.pclmul.l h, %0, %1, %2" : "=r"(rd3) : "r"(rs1), "r"(rs2));

    sum += (rd1+rd2+rd3);

    __asm__("xc.rngseed %0" : : "r"(sum));

    do {
        __asm__ volatile ("xc.rngtest %0" : "=r"(rd1) :);
        __asm__ volatile ("xc.rngsamp %0" : "=r"(rd2) :);
    } while(rd1 == 0);

    
    rs1 = 0x1FFF;
    __asm__ volatile ("xc.alsetcfg %0" : :"r"(rs1) );

    volatile int arry[10];

    for(int i = 0; i < 10; i ++) {
        sum += i;
        sum = sum << 2;
        __asm__ volatile ("xc.alfence");
        arry[i] = sum;
        sum += arry[i];
    }
    
    sum += rd2;

    if(sum) {

        return 0;

    } else {
        
        return 1;
        
    }
}

