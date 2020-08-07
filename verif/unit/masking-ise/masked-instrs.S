
.text

.extern test_fail

.global test_bit_reverse_representation
.func   test_bit_reverse_representation
test_bit_reverse_representation:

    addi        sp, sp, -32     // Stack space

    xor         a7, a0, a1      // Create expected answer in non masked form.
    sh          a7, 16(sp)      // Store halfword result to stack.

    mask.b.mask (t2,t1), a0     // Mask lhs
    mask.b.mask (a1,a0), a1     // Mask rhs

    nop
    nop                         // Gap to make reasoning about forwarding
    nop                         // easier.
    nop
    nop

    sh          t1, 0(sp)       // Store mask shares to stack.
    sh          t2, 4(sp)
    sh          a0, 8(sp)
    sh          a1,12(sp)

    lhu         t1, 0(sp)       // load mask shares from stack.
    lhu         t2, 4(sp)
    lhu         a0, 8(sp)
    lhu         a1,12(sp)
    lhu         a7,16(sp)       // Load back reference answer.

    nop
    nop

    mask.b.xor  (t4,t3), (t2,t1), (a1,a0) // Masked result
    mask.b.unmask a6,(t4,t3)    // Unmask result.

    slli    a6, a6, 16
    srli    a6, a6, 16

    beq a6, a7, .bit_rev_test_pass
    
    .bit_rev_test_fail:
        j test_fail

    .bit_rev_test_pass:
        addi sp, sp, 32
        ret
.endfunc

.global test_masked_not
.func   test_masked_not
test_masked_not:

    mask.b.mask     (t2,t1), a0
    mask.b.not      (a1,a0), (t2,t1)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_not_finish:
    ret
.endfunc

.global test_masked_and
.func   test_masked_and
test_masked_and:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.and      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_and_finish:
    ret
.endfunc

.global test_masked_ior
.func   test_masked_ior
test_masked_ior:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.ior      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_ior_finish:
    ret
.endfunc

.global test_masked_xor
.func   test_masked_xor
test_masked_xor:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.xor      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_xor_finish:
    ret
.endfunc

.global test_masked_b_add
.func   test_masked_b_add
test_masked_b_add:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.add      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_b_add_finish:
    ret
.endfunc

.global test_masked_b_sub
.func   test_masked_b_sub
test_masked_b_sub:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.sub      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_b_sub_finish:
    ret
.endfunc


.global test_masked_srli
.func   test_masked_srli
test_masked_srli:

    mask.b.mask     (t2,t1), a0
    mask.b.srli     (a1,a0), (t2,t1), 8
    mask.b.unmask    a0    , (a1,a0)

.test_masked_srli_finish:
    ret
.endfunc


.global test_masked_slli
.func   test_masked_slli
test_masked_slli:

    mask.b.mask     (t2,t1), a0
    mask.b.slli     (a1,a0), (t2,t1), 8
    mask.b.unmask    a0    , (a1,a0)

.test_masked_slli_finish:
    ret
.endfunc

.global test_masked_rori16
.func   test_masked_rori16
test_masked_rori16:
    mask.b.mask    (t2,t1), a0
    mask.b.slli (t2,t1), (t2,t1), 16
    mask.b.srli (t2,t1), (t2,t1), 16-8
    mask.b.srli (t4,t3), (t2,t1), 16
    mask.b.xor  (t2,t1), (t2,t1), (t4,t3)
    mask.b.unmask a0, (t2,t1)
    ret
.endfunc

.global test_masked_rori
.func   test_masked_rori
test_masked_rori:

    mask.b.mask     (t2,t1), a0
    mask.b.rori     (a1,a0), (t2,t1), 8
    mask.b.unmask    a0    , (a1,a0)

.test_masked_rori_finish:
    ret
.endfunc


.global test_masked_brm
.func   test_masked_brm
test_masked_brm:

    mask.b.mask     (t2,t1), a0
    mask.b.remask   (a1,a0), (t2,t1)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_brm_finish:
    ret
.endfunc


.global test_masked_b2a
.func   test_masked_b2a
test_masked_b2a:

    mask.b.mask     (t2,t1), a0
    mask.b2a        (a1,a0), (t2,t1)
    mask.a.unmask    a0    , (a1,a0)

.test_masked_b2a_finish:
    ret
.endfunc


.global test_masked_arm
.func   test_masked_arm
test_masked_arm:

    mask.a.mask     (t2,t1), a0
    mask.a.remask   (a1,a0), (t2,t1)
    mask.a.unmask    a0    , (a1,a0)

.test_masked_arm_finish:
    ret
.endfunc

.global test_masked_a2b
.func   test_masked_a2b
test_masked_a2b:

    mask.a.mask     (t2,t1), a0
    mask.a2b        (a1,a0), (t2,t1)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_a2b_finish:
    ret
.endfunc


.global test_masked_a_add
.func   test_masked_a_add
test_masked_a_add:

    mask.a.mask     (t2,t1), a0
    mask.a.mask     (t4,t3), a1
    mask.a.add      (a1,a0), (t2,t1), (t4,t3)
    mask.a.unmask    a0    , (a1,a0)

.test_masked_a_add_finish:
    ret
.endfunc

.global test_masked_a_sub
.func   test_masked_a_sub
test_masked_a_sub:

    mask.a.mask     (t2,t1), a0
    mask.a.mask     (t4,t3), a1
    mask.a.sub      (a1,a0), (t2,t1), (t4,t3)
    mask.a.unmask    a0    , (a1,a0)

.test_masked_a_sub_finish:
    ret
.endfunc


.global test_masked_f_mul
.func   test_masked_f_mul
test_masked_f_mul:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.f.mul      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_f_mul:
    ret
.endfunc


.global test_masked_f_aff
.func   test_masked_f_aff
test_masked_f_aff:

    mv  t4, a1
    mv  t3, a2
    mask.b.mask     (t2,t1), a0
    mask.f.aff      (a1,a0), (t2,t1), (t4,t3) 
    mask.b.unmask    a0    , (a1,a0)

.test_masked_f_aff:
    ret
.endfunc
