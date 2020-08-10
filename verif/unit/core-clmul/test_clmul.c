
#include "unit_test.h"

uint32_t clmul_ref (uint32_t rs1, uint32_t rs2) {
    uint32_t x = 0;
	for (int i = 0; i < 32; i++) {
		if (rs2 & 1) {
			x ^= rs1 << i;
        }
        rs2 = rs2 >> 1;
    }
	return x;
}

uint32_t clmulh_ref (uint32_t rs1, uint32_t rs2) {
    uint32_t x = 0;
	for (int i = 1; i < 32; i++) {
        rs2 = rs2 >> 1;
		if (rs2 & 1) {
			x ^= rs1 >> (32-i);
        }
    }
	return x;
}

uint32_t clmulr_ref (uint32_t rs1, uint32_t rs2) {
    uint32_t x = 0;
    for (int i = 0; i < 32; i++) {
        if (rs2 & 1) {
            x ^= rs1 >> (32-i-1);
        }
        rs2 = rs2 >> 1;
    }
    return x;
}

volatile inline uint32_t clmul_dut (uint32_t rs1, uint32_t rs2) {
    uint32_t rd;
    asm ("clmul %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2));
    return rd;
}

volatile inline uint32_t clmulh_dut (uint32_t rs1, uint32_t rs2) {
    uint32_t rd;
    asm ("clmulh %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2));
    return rd;
}

volatile inline uint32_t clmulr_dut (uint32_t rs1, uint32_t rs2) {
    uint32_t rd;
    asm ("clmulr %0, %1, %2" : "=r"(rd) : "r"(rs1), "r"(rs2));
    return rd;
}


#define CHECK(DUTF,GRMF,RS1,RS2) {      \
    uint32_t dut = DUTF(RS1,RS2);       \
    uint32_t grm = GRMF(RS1,RS2);       \
    if(dut!=grm) {                      \
        failures ++ ;                   \
        __putstr("RS1: "); __puthex32(RS1); __putchar('\n'); \
        __putstr("RS2: "); __puthex32(RS2); __putchar('\n'); \
        __putstr("GRM: "); __puthex32(grm); __putchar('\n'); \
        __putstr("DUT: "); __puthex32(dut); __putchar('\n'); \
        test_fail();                    \
    } else {                            \
        result = dut;                   \
    }                                   \
}

int test_main() {

    int failures    = 0;
    uint32_t result = 0;

    //
    // CLMUL

    CHECK(clmul_dut, clmul_ref, 0x00000000, 0x00000000)
    CHECK(clmul_dut, clmul_ref, 0x00000000, 0x00000001)
    CHECK(clmul_dut, clmul_ref, 0x00000001, 0x00000000)
    CHECK(clmul_dut, clmul_ref, 0x00000001, 0x00000001)
    CHECK(clmul_dut, clmul_ref, 0xFFFFFFFF, 0x00000000)
    CHECK(clmul_dut, clmul_ref, 0xFFFFFFFF, 0x00000001)
    CHECK(clmul_dut, clmul_ref, 0xFFFFFFFF, 0x00000010)
    CHECK(clmul_dut, clmul_ref, 0x00000000, 0xFFFFFFFF)
    CHECK(clmul_dut, clmul_ref, 0x00000001, 0xFFFFFFFF)
    CHECK(clmul_dut, clmul_ref, 0x00000010, 0xFFFFFFFF)
        
    uint32_t rs1 = 0xabcdef01;
    uint32_t rs2 = 0x12345678;

    for(int i = 0; i < 14; i ++) {
        CHECK(clmul_dut, clmul_ref, rs1, rs2)
        rs2 ^= rs1;
        rs1 ^= result;
    }
    
    //
    // CLMULH

    CHECK(clmulh_dut, clmulh_ref, 0x00000000, 0x00000000)
    CHECK(clmulh_dut, clmulh_ref, 0x00000000, 0x00000001)
    CHECK(clmulh_dut, clmulh_ref, 0x00000001, 0x00000000)
    CHECK(clmulh_dut, clmulh_ref, 0x00000001, 0x00000001)
    CHECK(clmulh_dut, clmulh_ref, 0xFFFFFFFF, 0x00000000)
    CHECK(clmulh_dut, clmulh_ref, 0xFFFFFFFF, 0x00000001)
    CHECK(clmulh_dut, clmulh_ref, 0xFFFFFFFF, 0x00000010)
    CHECK(clmulh_dut, clmulh_ref, 0x00000000, 0xFFFFFFFF)
    CHECK(clmulh_dut, clmulh_ref, 0x00000001, 0xFFFFFFFF)
    CHECK(clmulh_dut, clmulh_ref, 0x00000010, 0xFFFFFFFF)
        
    rs1 = 0xabcdef01;
    rs2 = 0x12345678;

    for(int i = 0; i < 14; i ++) {
        CHECK(clmulh_dut, clmulh_ref, rs1, rs2)
        rs2 ^= rs1;
        rs1 ^= result;
    }
    
    //
    // CLMULR

    CHECK(clmulr_dut, clmulr_ref, 0x00000000, 0x00000000)
    CHECK(clmulr_dut, clmulr_ref, 0x00000000, 0x00000001)
    CHECK(clmulr_dut, clmulr_ref, 0x00000001, 0x00000000)
    CHECK(clmulr_dut, clmulr_ref, 0x00000001, 0x00000001)
    CHECK(clmulr_dut, clmulr_ref, 0xFFFFFFFF, 0x00000000)
    CHECK(clmulr_dut, clmulr_ref, 0xFFFFFFFF, 0x00000001)
    CHECK(clmulr_dut, clmulr_ref, 0xFFFFFFFF, 0x00000010)
    CHECK(clmulr_dut, clmulr_ref, 0x00000000, 0xFFFFFFFF)
    CHECK(clmulr_dut, clmulr_ref, 0x00000001, 0xFFFFFFFF)
    CHECK(clmulr_dut, clmulr_ref, 0x00000010, 0xFFFFFFFF)
        
    rs1 = 0xabcdef01;
    rs2 = 0x12345678;

    for(int i = 0; i < 14; i ++) {
        CHECK(clmulr_dut, clmulr_ref, rs1, rs2)
        rs2 ^= rs1;
        rs1 ^= result;
    }

    return failures;

}
