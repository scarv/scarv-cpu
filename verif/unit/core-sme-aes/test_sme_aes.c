
#include "unit_test.h"

// $SCARV_CPU/src/csp/scarv_cpu_sme.h
#include "scarv_cpu_sme.h"

#define EXPECTED_SMAX  3
#define NREGS         16

typedef unsigned int uint_xlen_t ;

uint_xlen_t result [EXPECTED_SMAX];

static inline uint_xlen_t _aes32esi (uint_xlen_t rs1, uint_xlen_t rs2, int bs) {__asm__("aes32esi  %0, %1, %2" : "+r"(rs1) : "r"(rs2), "i"(bs)); return rs1;}
static inline uint_xlen_t _aes32esmi(uint_xlen_t rs1, uint_xlen_t rs2, int bs) {__asm__("aes32esmi %0, %1, %2" : "+r"(rs1) : "r"(rs2), "i"(bs)); return rs1;}
static inline uint_xlen_t _aes32dsi (uint_xlen_t rs1, uint_xlen_t rs2, int bs) {__asm__("aes32dsi  %0, %1, %2" : "+r"(rs1) : "r"(rs2), "i"(bs)); return rs1;}
static inline uint_xlen_t _aes32dsmi(uint_xlen_t rs1, uint_xlen_t rs2, int bs) {__asm__("aes32dsmi %0, %1, %2" : "+r"(rs1) : "r"(rs2), "i"(bs)); return rs1;}

int test_main() {

    // Turn off SME for now and get the max number of supported shares.
    sme_off();
    int smax = sme_get_smax();
    
    // Don't bother if we get an unexpected SMAX value.
    if(EXPECTED_SMAX != smax) {test_fail();}

    register uint_xlen_t rs1 asm("x16") = 0;
    register uint_xlen_t rs2 asm("x17") = 0;
    register uint_xlen_t dut asm("x18") = 0;
    register uint_xlen_t rd  asm("x19") = 0;

    sme_on(smax);

    SME_MASK(rs1, rs1)
    SME_MASK(rs2, rs2)

    rs1 = _aes32esi(rs1, rs2, 0);
    rs1 = _aes32esi(rs1, rs2, 1);
    rs1 = _aes32esi(rs1, rs2, 2);
    rs1 = _aes32esi(rs1, rs2, 3);

    SME_STORE(result, rs1, smax)

    sme_off();

    return 0;

}
