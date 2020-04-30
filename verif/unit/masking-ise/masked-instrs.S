
.text

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

.global test_masked_add
.func   test_masked_add
test_masked_add:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.add      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_add_finish:
    ret
.endfunc

.global test_masked_sub
.func   test_masked_sub
test_masked_sub:

    mask.b.mask     (t2,t1), a0
    mask.b.mask     (t4,t3), a1
    mask.b.sub      (a1,a0), (t2,t1), (t4,t3)
    mask.b.unmask    a0    , (a1,a0)

.test_masked_sub_finish:
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

