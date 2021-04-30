
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

.macro DUMP_HALF_STATE LC, BR, SP, R0, R1, R2, R3, R4, R5, R6, R7, LABEL
    li    \LC, 0x1E0             // LC = incrementing loop count variable.
    mv    \BR, \SP
    \LABEL:
        csrrw x0, 0x006, \LC     // Select i'th bank

        sw  \R0, 0*4(\BR)        // Load i'th share of input data.
        sw  \R1, 1*4(\BR)
        sw  \R2, 2*4(\BR)
        sw  \R3, 3*4(\BR)
        sw  \R4, 4*4(\BR)
        sw  \R5, 5*4(\BR)
        sw  \R6, 6*4(\BR)
        sw  \R7, 7*4(\BR)

        addi \BR,\BR,  16*4       // Select next share of input
        addi \LC, \LC, 1
        bne  \LC, a2, \LABEL
.endm

.macro LOAD_HALF_STATE LC, BR, SP, R0, R1, R2, R3, R4, R5, R6, R7, LABEL
    li    \LC, 0x1E0             // LC = incrementing loop count variable.
    mv    \BR, \SP
    \LABEL:
        csrrw x0, 0x006, \LC     // Select i'th bank

        lw  \R0, 0*4(\BR)        // Load i'th share of input data.
        lw  \R1, 1*4(\BR)
        lw  \R2, 2*4(\BR)
        lw  \R3, 3*4(\BR)
        lw  \R4, 4*4(\BR)
        lw  \R5, 5*4(\BR)
        lw  \R6, 6*4(\BR)
        lw  \R7, 7*4(\BR)

        addi \BR,\BR,  16*4       // Select next share of input
        addi \LC, \LC, 1
        bne  \LC, a2, \LABEL
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
        
        CHACHA20_QR x16, x20, x24, x28 
        CHACHA20_QR x17, x21, x25, x29 
        CHACHA20_QR x18, x22, x26, x30 
        CHACHA20_QR x19, x23, x27, x31 
        
        addi t0, t0, 2
        bltu t0, t1, .round_function
    
    //
    // Final operation: Add initial state.
    // ----------------------------------------

    // First, dump out half of the state to the stack make room for the
    // initial inputs in the masked registers
    DUMP_HALF_STATE a3, a4, sp, x24, x25, x26, x27, x28, x29, x30, x31, .ds0
    
    // Next, load the first half of the initial state
    LOAD_HALF_STATE a3, a4, a1, x24, x25, x26, x27, x28, x29, x30, x31, .ds1
    
    // Add initial state
    add x16, x16, x24
    add x17, x17, x25
    add x18, x18, x26
    add x19, x19, x27
    add x20, x20, x28
    add x21, x21, x29
    add x22, x22, x30
    add x23, x23, x31

    // Dump out the first half of the final state.
    DUMP_HALF_STATE a3, a4, a0, x16, x17, x18, x19, x20, x21, x22, x23, .ds2
    
    // Next, load the second half of the initial state
    LOAD_HALF_STATE a3, a4, a1, x24, x25, x26, x27, x28, x29, x30, x31, .ds3

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
