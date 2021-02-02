
.text

.global sme_xor
.func   sme_xor
// a0 - lhs shares array
// a1 - rhs shares array
// a2 - result shares array
// a3 - N - number of shares.
sme_xor:
    csrr    t0, 0x006       // Read current smectl value
    andi    t0, t0, -16     // loop counter
    or      t1, a3, t0      // Loop count end.
.l0:
    csrw    0x006, t0       // Set bank.
    lw      x16, 0*4(a0)    // Load all of the i'th shares
    lw      x17, 0*4(a1)
    addi    a0, a0, 4       // Increment lhs share pointer
    addi    a1, a1, 4       // Increment rhs share pointer
    addi    t0, t0, 1       // Increment loop counter
    blt     t0, t1, .l0     // Have we finished?
    nop
    nop
    nop
    xor     x17, x17, x16   // DO the XOR
    
    andi    t0, t0, -16     // loop counter / set bank to 0.
.l1:
    csrw    0x006, t0       // Set bank.
    sw      x17, 0*4(a2)    // store the result shares
    addi    a2, a2, 4       // Increment result share pointer
    addi    t0, t0, 1       // Increment loop counter
    blt     t0, t1, .l1     // Have we finished?
    ret

.endfunc


