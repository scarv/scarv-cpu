
.text

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
