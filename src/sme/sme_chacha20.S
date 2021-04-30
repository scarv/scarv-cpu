
.macro mask RD RS1
    .insn r CUSTOM_0, 1    , 0    , \RD, \RS1 ,x0 ;
.endm

.macro remask RD RS1
    .insn r CUSTOM_0, 2    , 0    , \RD, \RS1 ,x0 ;
.endm

.macro unmask RD RS1
    .insn r CUSTOM_0, 4    , 0    , \RD, \RS1 ,\RS1;
.endm

.text

//
// ChaCha20 Quarter Round Function macro
// ------------------------------------------------------------

.macro CHACHA20_QR A, B, C, D
    add \A, \A, \B;     xor \D, \D, \A;     rori \D, \D, 32-16
    add \C, \C, \D;     xor \B, \B, \C;     rori \B, \B, 32-12
    add \A, \A, \B;     xor \D, \D, \A;     rori \D, \D, 32- 8
    add \C, \C, \D;     xor \B, \B, \C;     rori \B, \B, 32- 7
.endm

// label - loop label
// lc - loop counter register
// lt - loop top / stop register
// basereg - base address in memory to store to.
// treg - temp register.
.macro DUMP_STATE label, lc, lt, basereg, treg
    li    \lc, 0x1E0             // a3 = incrementing loop count variable.
    mv    \treg, \basereg
    .\label:
        csrrw x0, 0x006, \lc    // Select i'th bank
        sw  x16, 0*4(\treg)        // Load i'th share of input data.
        sw  x17, 1*4(\treg)
        sw  x18, 2*4(\treg)
        sw  x19, 3*4(\treg)
        sw  x20, 4*4(\treg)
        sw  x21, 5*4(\treg)
        sw  x22, 6*4(\treg)
        sw  x23, 7*4(\treg)
        sw  x24, 8*4(\treg)
        sw  x25, 9*4(\treg)
        sw  x26,10*4(\treg)
        sw  x27,11*4(\treg)
        sw  x28,12*4(\treg)
        sw  x29,13*4(\treg)
        sw  x30,14*4(\treg)
        sw  x31,15*4(\treg)
        addi \treg, \treg, 16*4       // Select next share of input
        addi \lc, \lc, 1
        bne  \lc, \lt, .\label
.endm

// label - loop label
// lc - loop counter register
// lt - loop top / stop register
// basereg - base address in memory to store to.
// treg - temp register.
.macro DUMP_STATE_HALF label,lc,lt,basereg, treg, r0,r1,r2,r3,r4,r5,r6,r7,off
    li    \lc, 0x1E0             // a3 = incrementing loop count variable.
    mv    \treg, \basereg
    .\label:
        csrrw x0, 0x006, \lc    // Select i'th bank
        sw  \r0,\off+ 0*4(\treg)
        sw  \r1,\off+ 1*4(\treg)
        sw  \r2,\off+ 2*4(\treg)
        sw  \r3,\off+ 3*4(\treg)
        sw  \r4,\off+ 4*4(\treg)
        sw  \r5,\off+ 5*4(\treg)
        sw  \r6,\off+ 6*4(\treg)
        sw  \r7,\off+ 7*4(\treg)
        addi \treg, \treg, 16*4       // Select next share of input
        addi \lc, \lc, 1
        bne  \lc, \lt, .\label
.endm


// label - loop label
// lc - loop counter register
// lt - loop top / stop register
// basereg - base address in memory to store to.
// treg - temp register.
.macro LOAD_STATE_HALF label,lc,lt,basereg, treg, r0,r1,r2,r3,r4,r5,r6,r7,off
    li    \lc, 0x1E0             // a3 = incrementing loop count variable.
    mv    \treg, \basereg
    .\label:
        csrrw x0, 0x006, \lc    // Select i'th bank
        lw  \r0,\off+ 0*4(\treg)
        lw  \r1,\off+ 1*4(\treg)
        lw  \r2,\off+ 2*4(\treg)
        lw  \r3,\off+ 3*4(\treg)
        lw  \r4,\off+ 4*4(\treg)
        lw  \r5,\off+ 5*4(\treg)
        lw  \r6,\off+ 6*4(\treg)
        lw  \r7,\off+ 7*4(\treg)
        addi \treg, \treg, 16*4       // Select next share of input
        addi \lc, \lc, 1
        bne  \lc, \lt, .\label
.endm

    
//
// ChaCha20 Block Function 
// ------------------------------------------------------------

.global sme_chacha20_block
.func   sme_chacha20_block
sme_chacha20_block:
    // a0 - uint32_t out[SME_SMAX][16] 
    // a1 - uint32_t in [SME_SMAX][16]
    
    //
    // Function prologue 
    // ----------------------------------------

    addi    sp, sp, -96                 // Saved registers to stack
    sw      x18, 0*4(sp)
    sw      x19, 1*4(sp)
    sw      x20, 2*4(sp)
    sw      x21, 3*4(sp)
    sw      x22, 4*4(sp)
    sw      x23, 5*4(sp)
    sw      x24, 6*4(sp)
    sw      x25, 7*4(sp)
    sw      x26, 8*4(sp)
    sw      x27, 9*4(sp)
    
    //
    // SME discovery
    // ----------------------------------------

    li t0, 0x1E0                // D=max, bank=0
    csrrw x0, 0x006, t0         // Turn on SME with MAX shares and 0'th bank.
    csrr  a2, 0x006
    srli  a2, a2, 5             // a2 contains current number of shares
    or    a2, a2, t0            // a2 = max loop counter variable.
    
    //
    // Loading in initial input shares.
    // ----------------------------------------

    mv    a3, t0                // a3 = incrementing loop count variable.
    mv    a4, a1
    .load_state_0:
        csrrw x0, 0x006, a3     // Select i'th bank

        lw  x16, 0*4(a4)        // Load i'th share of input data.
        lw  x17, 1*4(a4)
        lw  x18, 2*4(a4)
        lw  x19, 3*4(a4)
        lw  x20, 4*4(a4)
        lw  x21, 5*4(a4)
        lw  x22, 6*4(a4)
        lw  x23, 7*4(a4)
        lw  x24, 8*4(a4)
        lw  x25, 9*4(a4)
        lw  x26,10*4(a4)
        lw  x27,11*4(a4)
        lw  x28,12*4(a4)
        lw  x29,13*4(a4)
        lw  x30,14*4(a4)
        lw  x31,15*4(a4)

        addi a4, a4, 16*4       // Select next share of input
        addi a3, a3, 1
        bne  a3, a2, .load_state_0
    
    //
    // Perform the round function
    // ----------------------------------------

    li t0, 0
    li t1, 20

    .round_function:

        CHACHA20_QR x16, x20, x24, x28 
        CHACHA20_QR x17, x21, x25, x29 
        CHACHA20_QR x18, x22, x26, x30 
        CHACHA20_QR x19, x23, x27, x31 
        
        CHACHA20_QR x16, x21, x26, x31 
        CHACHA20_QR x17, x22, x27, x28 
        CHACHA20_QR x18, x23, x24, x29 
        CHACHA20_QR x19, x20, x25, x30 
        
        addi t0, t0, 2
        bltu t0, t1, .round_function
    
    //
    // Final operation: Add initial state.
    // ----------------------------------------
    
    //DUMP_STATE_HALF dsl,a3,a2,a0,a4,  x16,x17,x18,x19,x20,x21,x22,x23, 0
    //DUMP_STATE_HALF dshf,a3,a2,a0,a4, x24,x25,x26,x27,x28,x29,x30,x31, 4*8
    
    // Dump low 8 words of state to output array
    DUMP_STATE_HALF dsl,a3,a2,a0,a4, x16,x17,x18,x19,x20,x21,x22,x23, 0
    
    // Load top 8 words of original input state
    LOAD_STATE_HALF lsl,a3,a2,a1,a4, x16,x17,x18,x19,x20,x21,x22,x23, 4*8

    add x24, x24, x16   // Add original state to block output.
    add x25, x25, x17
    add x26, x26, x18
    add x27, x27, x19
    add x28, x28, x20
    add x29, x29, x21
    add x30, x30, x22
    add x31, x31, x23

    // Dump out the now final top half of the state
    DUMP_STATE_HALF dshf,a3,a2,a0,a4, x24,x25,x26,x27,x28,x29,x30,x31, 4*8
    
    // ---

    // Load low 8 words of output array
    LOAD_STATE_HALF lol,a3,a2,a0,a4, x16,x17,x18,x19,x20,x21,x22,x23, 0
    
    // Load low 8 words of original input state
    LOAD_STATE_HALF lsh,a3,a2,a1,a4, x24,x25,x26,x27,x28,x29,x30,x31, 0  

    add x24, x24, x16   // Add original state to block output.
    add x25, x25, x17
    add x26, x26, x18
    add x27, x27, x19
    add x28, x28, x20
    add x29, x29, x21
    add x30, x30, x22
    add x31, x31, x23
    
    // Dump out the now final top half of the state
    DUMP_STATE_HALF dslf,a3,a2,a0,a4, x24,x25,x26,x27,x28,x29,x30,x31, 0

    //
    // Function epilogue
    // ----------------------------------------

    csrrw x0, 0x006, x0                 // Turn off SME

    lw      x18, 0*4(sp)                // Saved registers from stack
    lw      x19, 1*4(sp)
    lw      x20, 2*4(sp)
    lw      x21, 3*4(sp)
    lw      x22, 4*4(sp)
    lw      x23, 5*4(sp)
    lw      x24, 6*4(sp)
    lw      x25, 7*4(sp)
    lw      x26, 8*4(sp)
    lw      x27, 9*4(sp)
    addi    sp, sp,  96

    ret

.endfunc

//
// ChaCha20 State Mask and Unmask operations
// ------------------------------------------------------------

.global sme_chacha20_mask
.func   sme_chacha20_mask
sme_chacha20_mask:
    
    //
    // Function prologue 
    // ----------------------------------------

    addi    sp, sp, -48         // Saved registers to stack.
    sw      x18, 0*4(sp)
    sw      x19, 1*4(sp)
    sw      x20, 2*4(sp)
    sw      x21, 3*4(sp)
    sw      x22, 4*4(sp)
    sw      x23, 5*4(sp)
    sw      x24, 6*4(sp)
    sw      x25, 7*4(sp)
    sw      x26, 8*4(sp)
    sw      x27, 9*4(sp)
    
    lw  x16, 0*4(a1)            // Load state to be masked.
    lw  x17, 1*4(a1)
    lw  x18, 2*4(a1)
    lw  x19, 3*4(a1)
    lw  x20, 4*4(a1)
    lw  x21, 5*4(a1)
    lw  x22, 6*4(a1)
    lw  x23, 7*4(a1)
    lw  x24, 8*4(a1)
    lw  x25, 9*4(a1)
    lw  x26,10*4(a1)
    lw  x27,11*4(a1)
    lw  x28,12*4(a1)
    lw  x29,13*4(a1)
    lw  x30,14*4(a1)
    lw  x31,15*4(a1)

    li t0, 0x1E0                // D=max, bank=0
    csrrw x0, 0x006, t0         // Turn on SME with MAX shares and 0'th bank.

    mask x16, x16               // Mask everything
    mask x17, x17
    mask x18, x18
    mask x19, x19
    mask x20, x20
    mask x21, x21
    mask x22, x22
    mask x23, x23
    mask x24, x24
    mask x25, x25
    mask x26, x26
    mask x27, x27
    mask x28, x28
    mask x29, x29
    mask x30, x30
    mask x31, x31
    
    csrr  t1, 0x006
    srli  t1, t1, 5             // t1 contains current number of shares
    or    t1, t1, t0            // t1 = max loop counter variable.
    DUMP_STATE enmask_dump, t0, t1, a0, a0

    //
    // Function epilogue
    // ----------------------------------------

    csrrw x0, 0x006, x0         // Turn off SME

    lw      x18, 0*4(sp)        // Saved registers from stack
    lw      x19, 1*4(sp)
    lw      x20, 2*4(sp)
    lw      x21, 3*4(sp)
    lw      x22, 4*4(sp)
    lw      x23, 5*4(sp)
    lw      x24, 6*4(sp)
    lw      x25, 7*4(sp)
    lw      x26, 8*4(sp)
    lw      x27, 9*4(sp)
    addi    sp, sp,  48

    ret

.endfunc

