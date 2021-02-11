
#ifndef SME_SMAX
#define SME_SMAX 3
#endif

.macro mask RD RS1
    .insn r CUSTOM_0, 1    , 0    , \RD, \RS1 ,x0 ;
.endm

.macro remask RD RS1
    .insn r CUSTOM_0, 2    , 0    , \RD, \RS1 ,x0 ;
.endm

.macro unmask RD RS1
    .insn r CUSTOM_0, 4    , 0    , \RD, \RS1 ,x0 ;
.endm

.data

//
// Round constants for the AES Key Schedule
aes_rcon:
    .byte 0x01, 0x02, 0x04, 0x08, 0x10
    .byte 0x20, 0x40, 0x80, 0x1b, 0x36 

.text

//
// AES 128 Encrypt Key Expand
// ------------------------------------------------------------

.global sme_aes128_enc_key_exp
.func   sme_aes128_enc_key_exp
sme_aes128_enc_key_exp:
    // a0 - uint32_t rk[SME_SMAX][AES128_RK_WORDS]
    // a1 - uint32_t ck[4],
    addi    sp, sp, -16
    sw      x18, 0*4(sp)
    sw      x19, 1*4(sp)
    sw      x20, 2*4(sp)

    li t0, 0x1E0                // D=max, bank=0
    csrrw x0, 0x006, t0         // Turn on SME with MAX shares and 0'th bank.

    lw   x16,  0*4(a1)          // Load un-masked cipher key.
    lw   x17,  1*4(a1)
    lw   x18,  2*4(a1)
    lw   x19,  3*4(a1)

    mask x16, x16               // En-mask everything.
    mask x17, x17
    mask x18, x18
    mask x19, x19

    la   a2, aes_rcon           // Round constant pointer.
    addi a3, a2, 10             // End of loop

.aes128_enc_key_exp_l0:

    li t0, 0x1E0                // D=max, bank=0
    ori t1, t0, SME_SMAX
    mv  t2, a0
    .aes128_key_exp_l1:
        csrrw x0, 0x006, t0         // Select i'th bank
        sw   x16, 0*4(t2)      // Store i'th shares
        sw   x17, 1*4(t2)      // Store i'th shares
        sw   x18, 2*4(t2)      // Store i'th shares
        sw   x19, 3*4(t2)      // Store i'th shares
        addi t2, t2, 44*4
        addi t0, t0, 1
        bne  t0, t1, .aes128_key_exp_l1

    
    beq a2, a3, .aes128_enc_key_exp_finish

    lbu  a4, 0(a2)              // Load round constant byte
    addi a2, a2,  1             // Increment round const byte pointer
    addi a0, a0, 16             // Increment round key array pointer.

    xor  x16, x16, a4           // Add round constant.
    rori x20, x19,  8           // x20 = x19 >>> 8
    
    aes32esi x16, x20, 0        // Apply SBox
    aes32esi x16, x20, 1        //
    aes32esi x16, x20, 2        //
    aes32esi x16, x20, 3        //

    xor  x17, x17, x16
    xor  x18, x18, x17
    xor  x19, x19, x18

    j .aes128_enc_key_exp_l0    // Loop continue

.aes128_enc_key_exp_finish:

    csrrw x0, 0x006, x0         // Turn off SME
    lw      x18, 0*4(sp)
    lw      x19, 1*4(sp)
    lw      x20, 2*4(sp)
    addi    sp, sp, 16
    ret

.endfunc

//
// AES 128 Encrypt Block
// ------------------------------------------------------------

.global sme_aes128_enc_block
.func   sme_aes128_enc_block
sme_aes128_enc_block:
    // a0 - uint32_t ct[4],
    // a1 - uint32_t pt[4],
    // a2 - uint32_t rk[SME_SMAX][AES128_RK_WORDS]
    addi    sp, sp, -32
    sw      x18, 0*4(sp)
    sw      x19, 1*4(sp)
    sw      x20, 2*4(sp)
    sw      x21, 3*4(sp)
    sw      x22, 4*4(sp)
    sw      x23, 5*4(sp)
    
    lw a3, 1*4(a1)
    lw a4, 2*4(a1)
    lw a5, 3*4(a1)
    lw a1, 0*4(a1)              // Load plaintext. a1 now available.

    li t0, 0x1E0                // D=max, bank=0
    ori t1, t0, SME_SMAX        // Load 0'th round key.
    mv  t2, a2
    .aes128_enc_blk_ldkey0:
        csrrw x0, 0x006, t0     // Select i'th bank
        lw   x16, 0*4(t2)       // Load i'th shares
        lw   x17, 1*4(t2)       // Load i'th shares
        lw   x18, 2*4(t2)       // Load i'th shares
        lw   x19, 3*4(t2)       // Load i'th shares
        addi t2, t2, 44*4
        addi t0, t0, 1
        bne  t0, t1, .aes128_enc_blk_ldkey0

    xor x16, x16, a1            // 0'th add round key.
    xor x17, x17, a3
    xor x18, x18, a4
    xor x19, x19, a5

    addi a1, a2, 16*10          // Loop end pointer

.aes128_enc_blk_l0:
    
    li  t0, 0x1E0               // D=max, bank=0
    ori t1, t0, SME_SMAX        // Load 0'th round key.
    mv  t2, a2
    .aes128_enc_blk_ldkey1:
        csrrw x0, 0x006, t0     // Select i'th bank
        lw   x20, 16+0*4(t2)    // Load i'th shares
        lw   x21, 16+1*4(t2)    // Load i'th shares
        lw   x22, 16+2*4(t2)    // Load i'th shares
        lw   x23, 16+3*4(t2)    // Load i'th shares
        addi t2, t2, 44*4
        addi t0, t0, 1
        bne  t0, t1, .aes128_enc_blk_ldkey1
    nop;nop;nop;

    aes32esmi x20, x16, 0        // Even Round
    aes32esmi x20, x17, 1
    aes32esmi x20, x18, 2
    aes32esmi x20, x19, 3

    aes32esmi x21, x17, 0
    aes32esmi x21, x18, 1
    aes32esmi x21, x19, 2
    aes32esmi x21, x16, 3

    aes32esmi x22, x18, 0
    aes32esmi x22, x19, 1
    aes32esmi x22, x16, 2
    aes32esmi x22, x17, 3

    aes32esmi x23, x19, 0
    aes32esmi x23, x16, 1
    aes32esmi x23, x17, 2
    aes32esmi x23, x18, 3        // x20-x23 contains new state
    
    li  t0, 0x1E0               // D=max, bank=0
    ori t1, t0, SME_SMAX        // Load 0'th round key.
    mv  t2, a2
    .aes128_enc_blk_ldkey2:
        csrrw x0, 0x006, t0     // Select i'th bank
        lw   x16, 32+0*4(t2)    // Load i'th shares
        lw   x17, 32+1*4(t2)    // Load i'th shares
        lw   x18, 32+2*4(t2)    // Load i'th shares
        lw   x19, 32+3*4(t2)    // Load i'th shares
        addi t2, t2, 44*4
        addi t0, t0, 1
        bne  t0, t1, .aes128_enc_blk_ldkey2
    nop;nop;nop;

    addi a2, a2, 32             // Increment round key pointer.
    beq  a1, a2, .aes128_enc_blk_final
    
    aes32esmi x16, x20, 0        // Odd Round
    aes32esmi x16, x21, 1
    aes32esmi x16, x22, 2
    aes32esmi x16, x23, 3

    aes32esmi x17, x21, 0
    aes32esmi x17, x22, 1
    aes32esmi x17, x23, 2
    aes32esmi x17, x20, 3

    aes32esmi x18, x22, 0
    aes32esmi x18, x23, 1
    aes32esmi x18, x20, 2
    aes32esmi x18, x21, 3

    aes32esmi x19, x23, 0
    aes32esmi x19, x20, 1
    aes32esmi x19, x21, 2
    aes32esmi x19, x22, 3        // x20-x23 contains new state

    j .aes128_enc_blk_l0
    nop;nop;nop

.aes128_enc_blk_final:
    aes32esi x16, x20, 0        // Odd Round [Final]
    aes32esi x16, x21, 1
    aes32esi x16, x22, 2
    aes32esi x16, x23, 3

    aes32esi x17, x21, 0
    aes32esi x17, x22, 1
    aes32esi x17, x23, 2
    aes32esi x17, x20, 3

    aes32esi x18, x22, 0
    aes32esi x18, x23, 1
    aes32esi x18, x20, 2
    aes32esi x18, x21, 3

    aes32esi x19, x23, 0
    aes32esi x19, x20, 1
    aes32esi x19, x21, 2
    aes32esi x19, x22, 3        // x20-x23 contains new state

    unmask   x16, x16
    unmask   x17, x17
    unmask   x18, x18
    unmask   x19, x19

    csrrw x0, 0x006, x0         // Turn off SME

    sw       x16, 0*4(a0)       // Store result
    sw       x17, 1*4(a0)       // Store result
    sw       x18, 2*4(a0)       // Store result
    sw       x19, 3*4(a0)       // Store result

    lw      x18, 0*4(sp)        // Saved reg restore
    lw      x19, 1*4(sp)
    lw      x20, 2*4(sp)
    lw      x21, 3*4(sp)
    lw      x22, 4*4(sp)
    lw      x23, 5*4(sp)
    addi    sp, sp,32          // Stack restore
    ret

.endfunc

