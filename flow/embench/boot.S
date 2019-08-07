

.extern main

.section .text._start
.global _start
_start:                         // Entry point for the basic bootloader.
    j _boot


.section .text._passfail

.global test_fail
.func
test_fail:                      // Test ends here if it fails
    nop
    nop
    nop
    nop
    j test_fail
.endfunc

.global test_pass
.func
test_pass:                      // Test ends here if it passes
    nop
    nop
    nop
    nop
    j test_pass
.endfunc

.section .text 

.align 4
_boot:
    li x1 , 0
    li x2 , 0
    li x3 , 0
    li x4 , 0
    li x5 , 0
    li x6 , 0
    li x7 , 0
    li x8 , 0
    li x9 , 0
    li x10, 0
    li x11, 0
    li x12, 0
    li x13, 0
    li x14, 0
    li x15, 0
    li x16, 0
    li x17, 0
    li x18, 0
    li x19, 0
    li x20, 0
    li x21, 0
    li x22, 0
    li x23, 0
    li x24, 0
    li x25, 0
    li x26, 0
    li x27, 0
    li x28, 0
    li x29, 0
    li x30, 0
    li x31, 0

    la sp , _start + 0x7FFC

    la   t0 , _trap_handler     // Setup the trap handler.
    csrw mtvec, t0

    csrci  mstatus, 0b1111      // Clear global interrupt enable bits
    csrw   mie, zero            // Disable interrupts individually

    jal    main                 // Jump to the main test function.

    csrr t5, mcycle
    csrr t6, minstret

    beqz a0,test_pass           // Pass on test_main returning 0
    j       test_fail           // Nonzero -> fail.


_trap_handler:                  // Main trap handler function.
    j test_fail
    nop
    nop
    nop
    nop

