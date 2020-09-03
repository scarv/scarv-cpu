
#include <stdlib.h>
#include <stdint.h>
#include "scarv_cpu_csp.h"

#ifndef UNIT_TEST_H
#define UNIT_TEST_H


// ----------- Defined in boot.S -------------------

//! Called if the test fails
void test_fail();


//! Called if the test passes
void test_pass();

// ----------- Defined in util.S -------------------

//! Write a character to the uart.
void __putchar(char c) ;

//! Write a null terminated string to the uart.
void __putstr(char *s) ;

//! Print a 64-bit number as hex
void __puthex64(uint64_t w);

//! Print a 64-bit number as hex, no leading zeros.
void __puthex64_nlz(uint64_t w);

//! Print a 32-bit number as hex
void __puthex32(uint32_t w);

//! Print an 8-bit number as hex
void __puthex8(uint8_t w);

typedef struct {
uint8_t  expect_trap   ; // Expect a trap to occur. If false, mepc=test_fail
uint8_t  check_mcause  ; // Should we check the value of mcause?
uint32_t expect_mcause ; // Expected values of mcause as bit vector.
uint8_t  check_mepc    ; // Should we check the value of mepc?
uint32_t expect_mepc   ; // Expected value of mepc.
uint8_t  check_mtval   ; // Should we check the value of mtval?
uint32_t expect_mtval  ; // Expected value of mtval.
uint8_t  step_over_mepc; // Should handler check value of mepc?
volatile uint8_t *trap_seen     ; // Pointer to value set to 1 if trap handler seen.
} test_trap_handler_cfg ;

void setup_test_trap_handler (test_trap_handler_cfg * cfg);

#define MEASURE_PERF_BEGIN(NAME)     {                    \
    uint32_t instr_start, instr_end                     ; \
    uint32_t cycle_start, cycle_end                     ; \
    asm volatile("rdcycle   %0" : "=r"(cycle_start))    ; \
    asm volatile("rdinstret %0" : "=r"(instr_start))    ;
    

#define MEASURE_PERF_END(NAME, I, C)                      \
    asm volatile("rdcycle   %0" : "=r"(cycle_end))      ; \
    asm volatile("rdinstret %0" : "=r"(instr_end))      ; \
    I = instr_end - instr_start                         ; \
    C = cycle_end - cycle_start                         ; \
}

#endif

