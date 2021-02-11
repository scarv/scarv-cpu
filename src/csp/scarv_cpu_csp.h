
/*!
@defgroup scarv-cpu-csp SCARV-CPU Core Support Package
@brief Core Support functions for the SCARV-CPU.
@details Used by including the `scarv_cpu_csp.h` header file.
@{
*/

#include <stdint.h>

#ifndef __SCARV_CPU_CSP_H__
#define __SCARV_CPU_CSP_H__

// ----------- Timer Access Functions --------------

//! System clock frequency
extern const uint32_t scarv_cpu_freq;

/*!
@brief Read the 64-bit value of the mtime register.
@returns The full 64-bit value of mtime.
*/
uint64_t scarv_cpu_get_mtime();

/*!
@brief Set the new value of mtime
*/
void     scarv_cpu_set_mtime(uint64_t nv);

/*!
@brief Read the low 32 bits of the mtime register.
@returns The low 32 bits of mtime.
*/
uint32_t scarv_cpu_get_mtime_lo();

/*!
@brief Read the current value of mtimecmp
*/
uint64_t scarv_cpu_get_mtimecmp();

/*!
@brief Set the new value of mtimecmp
*/
void     scarv_cpu_set_mtimecmp(uint64_t nv);

/*!
@brief Wait for an interrupt to be pending.
@note May raise a trap in user mode if mstatus.tw (Timeout Wait) is set.
*/
inline void     scarv_cpu_wait_for_interrupt() {
    asm volatile ("wfi");
}

//! Read the current cycle count
inline uint64_t scarv_cpu_rdcycle() {
    uint32_t lo1, lo2, hi1;
    do {
        asm volatile ("rdcycle  %0" : "=r"(lo1) : );
        asm volatile ("rdcycleh %0" : "=r"(hi1) : );
        asm volatile ("rdcycle  %0" : "=r"(lo2) : );
    } while(lo2 < lo1);
    return ((uint64_t)hi1 << 32) | lo2;
}

//! Read the current cycle count
inline uint32_t scarv_cpu_rdcycle_lo() {
    uint32_t lo1;
    asm volatile ("rdcycle  %0" : "=r"(lo1) : );
    return lo1;
}

//! Read the current instructions retired count
inline uint64_t scarv_cpu_rdinstret() {
    uint32_t lo1, lo2, hi1;
    do {
        asm volatile ("rdinstret  %0" : "=r"(lo1) : );
        asm volatile ("rdinstreth %0" : "=r"(hi1) : );
        asm volatile ("rdinstret  %0" : "=r"(lo2) : );
    } while(lo2 < lo1);
    return ((uint64_t)hi1 << 32) | lo2;
}

//! Read the current instructions retired count
inline uint32_t scarv_cpu_rdinstret_lo() {
    uint32_t lo1;
    asm volatile ("rdinstret  %0" : "=r"(lo1) : );
    return lo1;
}

// ----------- CSR Constant Codes ------------------

#define SCARV_CPU_MCAUSE_IALIGN         (0x00000000)
#define SCARV_CPU_MCAUSE_IACCESS        (0x00000001)
#define SCARV_CPU_MCAUSE_IOPCODE        (0x00000002)
#define SCARV_CPU_MCAUSE_BREAKPT        (0x00000003)
#define SCARV_CPU_MCAUSE_LDALIGN        (0x00000004)
#define SCARV_CPU_MCAUSE_LDACCESS       (0x00000005)
#define SCARV_CPU_MCAUSE_STALIGN        (0x00000006)
#define SCARV_CPU_MCAUSE_STACCESS       (0x00000007)
#define SCARV_CPU_MCAUSE_ECALL_UMODE    (0x00000008)
#define SCARV_CPU_MCAUSE_ECALL_MMODE    (0x0000000B)

// ----------- CSR Read / Write --------------------


//! Declare a volatile inline function for Reading a CSR value
#define DECL_RD_CSR(CSR,A) volatile inline uint32_t scarv_cpu_get_##CSR() { \
    uint32_t rd; asm volatile ("csrr %0, " #A : "=r"(rd)); return rd; \
}

//! Declare a volatile inline function for Writing a CSR value
#define DECL_WR_CSR(CSR,A) volatile inline void scarv_cpu_wr_##CSR(uint32_t rs1) { \
    asm volatile ("csrw " #A ", %0" : : "r"(rs1));   \
}

//! Declare a volatile inline function for Clearing CSR bits.
#define DECL_CLR_CSR(CSR,A) volatile inline void scarv_cpu_clr_##CSR(uint32_t rs1) { \
    asm volatile ("csrc " #A ", %0" : : "r"(rs1));   \
}

//! Declare a volatile inline function for Setting CSR bits.
#define DECL_SET_CSR(CSR,A) volatile inline void scarv_cpu_set_##CSR(uint32_t rs1) { \
    asm volatile ("csrs " #A ", %0" : : "r"(rs1));   \
}

//! Top level macro for defining all CSR accessor functions.
#define DECL_CSR_ACCESS(CSR,A) \
    DECL_RD_CSR(CSR,A)         \
    DECL_WR_CSR(CSR,A)         \
    DECL_CLR_CSR(CSR,A)        \
    DECL_SET_CSR(CSR,A) 

DECL_RD_CSR(misa,0x301)
DECL_RD_CSR(mvendorid,0xF11)
DECL_RD_CSR(marchid,0xF12)
DECL_RD_CSR(mimpid,0xF13)
DECL_CSR_ACCESS(mepc,0x341)
DECL_CSR_ACCESS(mcause,0x342)
DECL_CSR_ACCESS(mtvec,0x305)
DECL_CSR_ACCESS(mtval,0x343)
DECL_CSR_ACCESS(mstatus,0x300)
DECL_CSR_ACCESS(mie,0x304)
DECL_CSR_ACCESS(mip,0x344)
DECL_CSR_ACCESS(mcounteren,0x306)
DECL_CSR_ACCESS(mcountinhibit,0x320)
DECL_CSR_ACCESS(mscratch,0x340)

//
// Entropy Source
// ------------------------------------------------------------

#define SCARV_CPU_POLLENTROPY_BIST 0
#define SCARV_CPU_POLLENTROPY_ES16 1
#define SCARV_CPU_POLLENTROPY_WAIT 2
#define SCARV_CPU_POLLENTROPY_DEAD 3

#define SCARV_CPU_MNOISE_NOISETEST (1 << 31)

inline volatile uint32_t scarv_cpu_pollentropy() {
    uint32_t rd;
    asm volatile ("csrrs %0, 0xF15, x0" : "=r"(rd));
    return rd;
}

inline volatile uint32_t scarv_cpu_getnoise_rd() {
    uint32_t rd;
    asm volatile ("csrrs %0, 0x7A9, x0" : "=r"(rd));
    return rd;
}

inline volatile void scarv_cpu_getnoise_wr(uint32_t wd) {
    asm volatile ("csrw 0x7A9, %0" : :  "r"(wd));
}

#endif

//! @}

