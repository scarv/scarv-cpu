
.global test_mul_ld
.func   test_mul_ld
test_mul_ld:
    li  a4, 0       // Zero load dest register to check it works.
    nop
    lw  a4, 0(a2)   // Load c in shadow of multiply.
    mul a3, a0, a1  //  a2 = a0 * a1 / tmp = a*b
    add a0, a3, a4  // a0 = a0*a1+c
    ret
.endfunc
