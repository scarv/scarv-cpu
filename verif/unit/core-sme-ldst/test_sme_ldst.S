
.text

.global sme_load_all_shares
.func   sme_load_all_shares
// a0 - pointer to start of 16*N array
// a1 - N - number of shares.
sme_load_all_shares:
    csrr    a2, 0x006       // Read current smectl value
    or      a1, a1, a2
    andi    a2, a2, -16     // loop counter
    addi    a2, a2, 1       // Select bank 1
.l0:
    csrw    0x006, a2       // Set bank.
    lw      x16, 0*4(a0)    // Load all of the 0'th shares
    lw      x17, 1*4(a0)
    lw      x18, 2*4(a0)
    lw      x19, 3*4(a0)
    lw      x20, 4*4(a0)
    lw      x21, 5*4(a0)
    lw      x22, 6*4(a0)
    lw      x23, 7*4(a0)
    lw      x24, 8*4(a0)
    lw      x25, 9*4(a0)
    lw      x26,10*4(a0)
    lw      x27,11*4(a0)
    lw      x28,12*4(a0)
    lw      x29,13*4(a0)
    lw      x30,14*4(a0)
    lw      x31,15*4(a0)
    addi    a0, a0, 16*4    // Increment share pointer
    addi    a2, a2, 1       // Increment loop counter
    blt     a2, a1, .l0     // Have we finished?
    csrci   0x006, 0xF      // Reset bank to 0.
    ret                     // Return
.endfunc


.global sme_store_all_shares
.func   sme_store_all_shares
// a0 - pointer to start of 16*N array
// a1 - N - number of shares.
sme_store_all_shares:
    csrr    a2, 0x006       // Select bank 0.
    or      a1, a1, a2
    andi    a2, a2, -16     // loop counter
    addi    a2, a2, 1
.l1:
    csrw    0x006, a2       // Set bank.
    sw      x16, 0*4(a0)    // Load all of the 0'th shares
    sw      x17, 1*4(a0)
    sw      x18, 2*4(a0)
    sw      x19, 3*4(a0)
    sw      x20, 4*4(a0)
    sw      x21, 5*4(a0)
    sw      x22, 6*4(a0)
    sw      x23, 7*4(a0)
    sw      x24, 8*4(a0)
    sw      x25, 9*4(a0)
    sw      x26,10*4(a0)
    sw      x27,11*4(a0)
    sw      x28,12*4(a0)
    sw      x29,13*4(a0)
    sw      x30,14*4(a0)
    sw      x31,15*4(a0)
    addi    a0, a0, 16*4    // Increment share pointer
    addi    a2, a2, 1       // Increment loop counter
    blt     a2, a1, .l1     // Have we finished?
    csrci   0x006, 0xF      // Reset bank to 0.
    ret                     // Return
.endfunc
