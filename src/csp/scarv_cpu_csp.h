
/*!
@defgroup scarv-cpu-csp SCARV-CPU Core Support Package
@brief Core Support functions for the SCARV-CPU.
@details Used by including the `scarv_cpu_csp.h` header file.
@{
*/

#include <stdint.h>

#ifndef __SCARV_CPU_CSP_H__
#define __SCARV_CPU_CSP_H__

// ----------- Memory Mapped IO Addresses ----------

//! Constant Pointer to a volatile memory mapped IO word.
typedef uint32_t volatile * const scarv_cpu_mmio_t;

//! Bits 31:0 of the memory mapped mtime register.
scarv_cpu_mmio_t scarv_cpu_mtime_lo       ;

//! Bits 63:32 of the memory mapped mtime register.
scarv_cpu_mmio_t scarv_cpu_mtime_hi       ;

//! Bits 31:0 of the memory mapped mtimecmp register.
scarv_cpu_mmio_t scarv_cpu_mtimecmp_lo    ;

//! Bits 63:32 of the memory mapped mtimecmp register.
scarv_cpu_mmio_t scarv_cpu_mtimecmp_hi    ;

//! Address which pollentropy instructions access.
scarv_cpu_mmio_t scarv_cpu_trng           ;

// ----------- Timer Access Functions --------------

//! System clock frequency
const uint32_t scarv_cpu_freq;

/*!
@brief Read the 64-bit value of the mtime register.
@returns The full 64-bit value of mtime.
*/
inline uint64_t scarv_cpu_get_mtime();

/*!
@brief Read the low 32 bits of the mtime register.
@returns The low 32 bits of mtime.
*/
inline uint32_t scarv_cpu_get_mtime_lo();

/*!
@brief Read the current value of mtimecmp
*/
inline uint64_t scarv_cpu_set_mtimecmp();

/*!
@brief Set the new value of mtimecmp
*/
inline void     scarv_cpu_get_mtimecmp(uint64_t nv);

/*!
@brief Wait for an interrupt to be pending.
@note May raise a trap in user mode if mstatus.tw (Timeout Wait) is set.
*/
inline void     scarv_cpu_wait_for_interrupt() {
    asm volatile ("wfi");
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
#define DECL_RD_CSR(CSR) volatile inline uint32_t scarv_cpu_get_##CSR() { \
    uint32_t rd; asm volatile ("csrr %0, " #CSR : "=r"(rd)); return rd; \
}

//! Declare a volatile inline function for Writing a CSR value
#define DECL_WR_CSR(CSR) volatile inline void scarv_cpu_wr_##CSR(uint32_t rs1) { \
    asm volatile ("csrw " #CSR ", %0" : : "r"(rs1));   \
}

//! Declare a volatile inline function for Clearing CSR bits.
#define DECL_CLR_CSR(CSR) volatile inline void scarv_cpu_clr_##CSR(uint32_t rs1) { \
    asm volatile ("csrc " #CSR ", %0" : : "r"(rs1));   \
}

//! Declare a volatile inline function for Setting CSR bits.
#define DECL_SET_CSR(CSR) volatile inline void scarv_cpu_set_##CSR(uint32_t rs1) { \
    asm volatile ("csrs " #CSR ", %0" : : "r"(rs1));   \
}

//! Top level macro for defining all CSR accessor functions.
#define DECL_CSR_ACCESS(CSR) \
    DECL_RD_CSR(CSR)         \
    DECL_WR_CSR(CSR)         \
    DECL_CLR_CSR(CSR)        \
    DECL_SET_CSR(CSR) 

DECL_CSR_ACCESS(mepc)
DECL_CSR_ACCESS(mcause)
DECL_CSR_ACCESS(mtvec)
DECL_CSR_ACCESS(mtval)
DECL_CSR_ACCESS(mstatus)
DECL_CSR_ACCESS(mie)
DECL_CSR_ACCESS(mip)

#endif

//! @}

