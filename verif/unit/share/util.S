
.data


.text

.func   __rd_mtime
.global __rd_mtime
__rd_mtime:
    li a3, 0x00001000       // Base address of MMIO region
  __rd_mtime_again:
    lw a1, 4(a3)            // a1 = high word of mtime cmp
    lw a0, 0(a3)            // a0 = low word of mtime
    lw a2, 4(a3)            // a1 = high word of mtime cmp
    bne a1, a2, __rd_mtime_again
    ret
.endfunc

.func   __rd_mtimecmp
.global __rd_mtimecmp
__rd_mtimecmp:
    li a3, 0x00001000       // Base address of MMIO region
  __rd_mtimecmp_again:
    lw a1, 12(a3)           // a1 = high word of mtime cmp
    lw a0,  8(a3)           // a0 = low word of mtime
    lw a2, 12(a3)           // a1 = high word of mtime cmp
    bne a1, a2, __rd_mtimecmp_again
    ret
.endfunc

.func   __wr_mtimecmp
.global __wr_mtimecmp
__wr_mtimecmp:
    li a3, 0x00001000       // Base address of MMIO region
    li a2, -1
    sw a2,  8(a3)           // a1 = high word of mtime cmp
    sw a1, 12(a3)           // a1 = high word of mtime cmp
    sw a0,  8(a3)           // a0 = low word of mtime
    ret
.endfunc

.func   __rdcycle
.global __rdcycle
__rdcycle:
    rdcycleh a1
    rdcycle  a0
    rdcycleh a2
    bne a1, a2, __rdcycle
    ret
.endfunc

.func   __rdtime
.global __rdtime
__rdtime:
    rdtimeh a1
    rdtime  a0
    rdtimeh a2
    bne a1, a2, __rdtime
    ret
.endfunc

.func   __rdinstret
.global __rdinstret
__rdinstret:
    rdinstreth a1
    rdinstret  a0
    rdinstreth a2
    bne a1, a2, __rdinstret
    ret
.endfunc


.func __rdmcountinhibit
.global __rdmcountinhibit
__rdmcountinhibit:
    .word 0x32002573         // csrr a0,mcountinhibit
                             // Toolchain doesnt recognise mcountinhibit
    ret
.endfunc

.func __wrmcountinhibit
.global __wrmcountinhibit
__wrmcountinhibit:
    .word 0x32051573        // csrrw a0,mcountinhibit, a0
                            // Toolchain doesnt recognise mcountinhibit
    ret
.endfunc


.func __rd_mstatus
.global __rd_mstatus
__rd_mstatus:
    csrr a0, mstatus
    ret
.endfunc


.func __wr_mstatus
.global __wr_mstatus
__wr_mstatus:
    csrrw a0, mstatus, a0
    ret
.endfunc


.func __set_mstatus
.global __set_mstatus
__set_mstatus:
    csrs    mstatus, a0
    ret
.endfunc


.func __clr_mstatus
.global __clr_mstatus
__clr_mstatus:
    csrc    mstatus, a0
    ret
.endfunc


.func __rd_mie
.global __rd_mie
__rd_mie:
    csrr a0, mie
    ret
.endfunc


.func __wr_mie
.global __wr_mie
__wr_mie:
    csrrw a0, mie, a0
    ret
.endfunc


.func __set_mie
.global __set_mie
__set_mie:
    csrs    mie, a0
    ret
.endfunc


.func __clr_mie
.global __clr_mie
__clr_mie:
    csrc    mie, a0
    ret
.endfunc


.balign 4
.extern test_trap_handler
.func   __asm_test_trap_handler
.global __asm_test_trap_handler
__asm_test_trap_handler:
	addi    sp, sp, 32*4
    sw      x1,  0*4(sp)
    sw      x2,  1*4(sp)
    sw      x3,  2*4(sp)
    sw      x4,  3*4(sp)
    sw      x5,  4*4(sp)
    sw      x6,  5*4(sp)
    sw      x7,  6*4(sp)
    sw      x8,  7*4(sp)
    sw      x9,  8*4(sp)
    sw     x10,  9*4(sp)
    sw     x11, 10*4(sp)
    sw     x12, 11*4(sp)
    sw     x13, 12*4(sp)
    sw     x14, 13*4(sp)
    sw     x15, 14*4(sp)
    sw     x16, 15*4(sp)
    sw     x17, 16*4(sp)
    sw     x18, 17*4(sp)
    sw     x19, 18*4(sp)
    sw     x20, 19*4(sp)
    sw     x21, 20*4(sp)
    sw     x22, 21*4(sp)
    sw     x23, 22*4(sp)
    sw     x24, 23*4(sp)
    sw     x25, 24*4(sp)
    sw     x26, 25*4(sp)
    sw     x27, 26*4(sp)
    sw     x28, 27*4(sp)
    sw     x29, 28*4(sp)
    sw     x30, 29*4(sp)
    sw     x31, 30*4(sp)
    jal    test_trap_handler
    lw      x1,  0*4(sp)
    lw      x2,  1*4(sp)
    lw      x3,  2*4(sp)
    lw      x4,  3*4(sp)
    lw      x5,  4*4(sp)
    lw      x6,  5*4(sp)
    lw      x7,  6*4(sp)
    lw      x8,  7*4(sp)
    lw      x9,  8*4(sp)
    lw     x10,  9*4(sp)
    lw     x11, 10*4(sp)
    lw     x12, 11*4(sp)
    lw     x13, 12*4(sp)
    lw     x14, 13*4(sp)
    lw     x15, 14*4(sp)
    lw     x16, 15*4(sp)
    lw     x17, 16*4(sp)
    lw     x18, 17*4(sp)
    lw     x19, 18*4(sp)
    lw     x20, 19*4(sp)
    lw     x21, 20*4(sp)
    lw     x22, 21*4(sp)
    lw     x23, 22*4(sp)
    lw     x24, 23*4(sp)
    lw     x25, 24*4(sp)
    lw     x26, 25*4(sp)
    lw     x27, 26*4(sp)
    lw     x28, 27*4(sp)
    lw     x29, 28*4(sp)
    lw     x30, 29*4(sp)
    lw     x31, 30*4(sp)
	addi    sp, sp,-32*4
    mret

.endfunc
