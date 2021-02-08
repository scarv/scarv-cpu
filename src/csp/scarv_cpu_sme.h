
/*
 * file: sme.h
 *
 *  Header for various functions/constants relating to the SME implementation.
 *
 */

#ifndef __SME_H__
#define __SME_H__

// Write smectl with w.
volatile inline void sme_ctlw(int w){
    asm volatile (
        "csrw 0x006, %0" 
        :
        : "r"(w)
    );
}

// Read smectl.
volatile inline int sme_ctlr(){
    int rd;
    asm volatile (
        "csrr %0, 0x006"
        : "=r"(rd)
        :
    );
    return rd;
}

// Get max supported shares.
volatile inline int sme_get_smax() {
    int rd;
    int tmp = -1;
    asm volatile (
        "csrrw %0, 0x006, %2;"
        "csrrw %1, 0x006, %0"
        : "=r"(tmp), "=r"( rd)
        : "r"(tmp)
    );
    return 0xF & (rd >> 5);
}

// Turn off SME. {smectl.d,t,b} = {0,0,0}
volatile inline void sme_off() {
    asm volatile (
        "csrw 0x006, x0;"
    );
}

// Turn on SME and use the supplied number of shares.
// Sets smectl.t=smectl.b=0
volatile inline void sme_on(int shares) {
    shares  &= 0xF;
    shares <<= 5  ;
    asm volatile (
        "csrw 0x006, %0;"
        :
        : "r"(shares)
    );
}

// Use boolean masking
volatile inline void sme_use_boolean(){
    asm volatile (
        "csrci 0x006, 0x10"
    );
}

// Use Arithmetic masking
volatile inline void sme_use_arithmetic(){
    asm volatile (
        "csrsi 0x006, 0x10"
    );
}

#define SME_LOAD(var, src, s) {                         \
    register int start;                                 \
    asm volatile ("csrr %0, 0x006" : "=r"(start));      \
    start &= ~0xF;                                      \
    register int end = start + s;                       \
    uint32_t * rdp = src ;                              \
    for(int i = start; i < end; i++) {                  \
        sme_ctlw(i);                                    \
        var = *rdp++;                                   \
    }                                                   \
}

#define SME_STORE(dest, var, s) {                       \
    register int start;                                 \
    asm volatile ("csrr %0, 0x006" : "=r"(start));      \
    start &= ~0xF;                                      \
    register int end = start + s;                       \
    uint32_t * rdp = dest;                              \
    for(int i = start; i < end; i++) {                  \
        sme_ctlw(i);                                    \
        *rdp++ = var;                                   \
    }                                                   \
}

#define SME_ROR(dest, rs1, rs2)                         \
asm (                                                   \
    ".insn r OP, 5, 48, %0, %1, %2"                     \
    : "=r"(rd)                                          \
    : "r"(rs1), "r"(rs2)                                \
);

#define SME_ROL(dest, rs1, rs2)                         \
asm (                                                   \
    ".insn r OP, 1, 48, %0, %1, %2"                     \
    : "=r"(rd)                                          \
    : "r"(rs1), "r"(rs2)                                \
);

#define SME_RORI(dest, rs1, shamt)                      \
asm (                                                   \
    "rori %0, %1, %2"                                   \
    : "=r"(rd)                                          \
    : "r"(rs1), "i"(shamt)                              \
);

// En-mask the supplied variable.
#define SME_MASK(rd, rs1) {                             \
    asm volatile (                                      \
        " .insn r CUSTOM_0, 1    , 0    , %0, %1 ,x0 ;" \
        : "=r"(rd)                                      \
        :  "r"(rs1)                                     \
    );                                                  \
}

// Re-mask the supplied variable.
#define SME_REMASK(rd, rs1) {                           \
    asm volatile (                                      \
        " .insn r CUSTOM_0, 2    , 0    , %0, %1 ,x0 ;" \
        : "=r"(rd)                                      \
        :  "r"(rs1)                                     \
    );                                                  \
}

// Un-mask the supplied variable.
#define SME_UNMASK(rd, rs1) {                           \
    asm volatile (                                      \
        " .insn r CUSTOM_0, 4    , 0    , %0, %1 ,x0 ;" \
        : "=r"(rd)                                      \
        :  "r"(rs1)                                     \
    );                                                  \
}

#endif
