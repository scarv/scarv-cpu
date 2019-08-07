
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
