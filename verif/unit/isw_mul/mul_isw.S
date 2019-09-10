
.global mul_isw
.func   mul_isw
mul_isw: 
    // a0 - uint32_t * a
    // a1 - uint32_t * b
    // a2 - uint32_t   d
    // a3 - uint32_t * c
    
    li t0, -1
    xc.lkgconf  t0                          // Set leakage barrier to "all"

    li t0, 0                                // i    = t0 = 0
    .L0:
        xc.ldr.w t1, a0(t0)                 //        t1 = a[i]
        xc.ldr.w t2, a1(t0)                 //        t2 = b[i]
        and      t3, t1, t2                 //        t3 = a[i] * b[i]
        xc.str.w t3, a3(t0)                 // c[i] = t3 = a[i] * b[i]

        addi t0, t0, 1
        bltu t0, a2, .L0                    // if i < d goto .L0

    addi a7, a2, -1
    li t0, 0                                // i    = t0 = 0
    .L1:
        
        addi t1, t0, 1                      // j    = t1 = t0 + 1 = i + 1
        
        .L2:

            xc.rngsamp  t2                  // s    = t2 = random()

            xc.ldr.w    t3, a0(t0)          //        t3 = a_i
            xc.ldr.w    t4, a1(t1)          //        t4 = b_j
            xc.ldr.w    t5, a0(t1)          //        t5 = a_j
            xc.ldr.w    t6, a1(t0)          //        t6 = b_i

            // s' = (s + (a[i]*b[j])) + (a[j] * b[i])
            and         a4, t3, t4          //        a4 = a_i * b_j
            xor         a5, a4, t2          //        a5 = s + (a_i * b_j)
            and         a6, t5, t6          //        a6 = a_j * b_i
            xor         t3, a5, a6          // s'     a7 = a5 + a6

            xc.ldr.w    t5, a3(t0)          //        t5 = c[i]
            xc.ldr.w    t6, a3(t1)          //        t6 = c[j]

            xor         t5, t5, t2          //        t5 = c[i] ^ s
            xor         t6, t6, t3          //        t6 = c[j] ^ s'

            xc.str.w    t5, a3(t0)          // c[i] = t5 = c[i] ^ s
            xc.str.w    t6, a3(t1)          // c[j] = t6 = c[j] ^ s'

            addi t1, t1, 1
            bltu t1, a2, .L2                // if j < d goto .L2

        addi t0, t0, 1
        bltu t0, a7, .L1                    // if i < d goto .L1

    ret

.endfunc

