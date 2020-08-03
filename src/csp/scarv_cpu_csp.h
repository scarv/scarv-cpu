
#include <stdint.h>

#ifndef __SCARV_CPU_CSP_H__
#define __SCARV_CPU_CSP_H__

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

#define DECL_RD_CSR(CSR) volatile inline uint32_t scarv_cpu_rd_##CSR() { \
    uint32_t rd; asm volatile ("csrr %0, " #CSR : "=r"(rd)); return rd; \
}

#define DECL_WR_CSR(CSR) volatile inline void scarv_cpu_wr_##CSR(uint32_t rs1) { \
    asm volatile ("csrw " #CSR ", %0" : : "r"(rs1));   \
}

#define DECL_CLR_CSR(CSR) volatile inline void scarv_cpu_clr_##CSR(uint32_t rs1) { \
    asm volatile ("csrc " #CSR ", %0" : : "r"(rs1));   \
}

#define DECL_SET_CSR(CSR) volatile inline void scarv_cpu_set_##CSR(uint32_t rs1) { \
    asm volatile ("csrs " #CSR ", %0" : : "r"(rs1));   \
}

DECL_RD_CSR(mepc)
DECL_WR_CSR(mepc)

DECL_RD_CSR(mcause)

DECL_RD_CSR(mtvec)
DECL_WR_CSR(mtvec)

DECL_RD_CSR(mtval)
DECL_WR_CSR(mtval)

DECL_RD_CSR(mstatus)
DECL_WR_CSR(mstatus)
DECL_CLR_CSR(mstatus)
DECL_SET_CSR(mstatus)

DECL_RD_CSR(mie)
DECL_WR_CSR(mie)
DECL_CLR_CSR(mie)
DECL_SET_CSR(mie)

#endif

