
#include "unit_test.h"

int test_main() {

    uint32_t rs1 = 0xF0F0F0F0;
    uint32_t rs2 = 0x0F0F0F0F;
    uint32_t rd1,rd2,rd3;

    __asm__ ("clmul %0, %1, %2" : "=r"(rd1) : "r"(rs1), "r"(rs2));
    __asm__ ("clmulr %0, %1, %2" : "=r"(rd2) : "r"(rs1), "r"(rs2));

    __asm__ ("xc.pclmul.l h, %0, %1, %2" : "=r"(rd3) : "r"(rs1), "r"(rs2));

    if(rd1 && rd2 && rd3) {

        return 0;

    } else {
        
        return 1;
        
    }
}

