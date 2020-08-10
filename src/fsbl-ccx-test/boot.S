
.section .text.fsbl
.global __fsbl_start
__fsbl_start:
    la  ra , __fsbl_fail        // return address for jumps
    la  sp , __ccx_stack_start  // stack pointer
    li  gp , 0                  // global pointer
    li  tp , 0                  // thread pointer
    li  t0 , 0                  // temporary register 0
    li  t1 , 0                  // temporary register 1
    li  t2 , 0                  // temporary register 2
    li  s0 , 0                  // or fp saved register 0 or frame pointer
    li  s1 , 0                  // saved register 1
    li  a0 , 0                  // return value or function argument 0
    li  a1 , 0                  // return value or function argument 1
    li  a2 , 0                  // function argument 2
    li  a3 , 0                  // function argument 3
    li  a4 , 0                  // function argument 4
    li  a5 , 0                  // function argument 5
    li  a6 , 0                  // function argument 6
    li  a7 , 0                  // function argument 7
    li  s2 , 0                  // saved register 2
    li  s3 , 0                  // saved register 3
    li  s4 , 0                  // saved register 4
    li  s5 , 0                  // saved register 5
    li  s6 , 0                  // saved register 6
    li  s7 , 0                  // saved register 7
    li  s8 , 0                  // saved register 8
    li  s9 , 0                  // saved register 9
    li  s10, 0                  // saved register 10
    li  s11, 0                  // saved register 11
    li  t3 , 0                  // temporary register 3
    li  t4 , 0                  // temporary register 4
    li  t5 , 0                  // temporary register 5
    li  t6 , 0                  // temporary register 6

    csrw    mtvec, ra           // mtvec = test fail.

    jal __ram_begin             // Jump straight into start of the RAM.
    beqz    a0, __fsbl_pass     // Pass iff returned zero.

.balign 4
__fsbl_fail:
    j   __fsbl_fail

.balign 4
__fsbl_pass:
    j   __fsbl_pass
