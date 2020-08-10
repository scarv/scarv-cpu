
#include "unit_test.h"

// Used by __puthex*
char * lut = "0123456789ABCDEF";

// Base address of the memory mapped IO region
volatile uint32_t * __mmio_base = (uint32_t*)0x00001000;

//! Direct access to mtime
volatile uint64_t * __mtime     = (uint64_t*)0x00001000;

//! Direct access to mtimecmp
volatile uint64_t * __mtimecmp  = (uint64_t*)0x00001008;

volatile uint32_t * UART = (volatile uint32_t*)0x40600000;

//! Write a character to the uart.
void __putchar(char c) {
    UART[0] = c;
}

//! Write a null terminated string to the uart.
void __putstr(char *s) {
    int i = 0;
    if(s[0] == 0) {
        return;
    }
    do {
        uint32_t tw = s[i];
        UART[0]     = tw;
        i++;
    } while(s[i] != 0) ;
}

//! Print a 64-bit number as hex
void __puthex64(uint64_t w) {
    for(int i =  7; i >= 0; i --) {
        uint8_t b_0 = (w >> (8*i    )) & 0xF;
        uint8_t b_1 = (w >> (8*i + 4)) & 0xF;
        __putchar(lut[b_1]);
        __putchar(lut[b_0]);
    }
}

//! Print a 64-bit number as hex. No leading zeros.
void __puthex64_nlz(uint64_t w) {
    char nz_seen = 0;
    for(int i =  7; i >= 0; i --) {
        uint8_t b_0 = (w >> (8*i    )) & 0xF;
        uint8_t b_1 = (w >> (8*i + 4)) & 0xF;
        if(b_1 > 0 || nz_seen) {
            nz_seen = 1;
            __putchar(lut[b_1]);
        }
        if(b_0 > 0 || nz_seen) {
            nz_seen = 1;
            __putchar(lut[b_0]);
        }
    }
}

//! Print a 32-bit number as hex
void __puthex32(uint32_t w) {
    for(int i =  3; i >= 0; i --) {
        uint8_t b_0 = (w >> (8*i    )) & 0xF;
        uint8_t b_1 = (w >> (8*i + 4)) & 0xF;
        __putchar(lut[b_1]);
        __putchar(lut[b_0]);
    }
}

//! Print an 8-bit number as hex
void __puthex8(uint8_t w) {
    uint8_t b_0 = (w >> ( 0)) & 0xF;
    uint8_t b_1 = (w >> ( 4)) & 0xF;
    __putchar(lut[b_1]);
    __putchar(lut[b_0]);
}


//
// Test trap handler code.
// ------------------------------------------------------------

extern void __asm_test_trap_handler();

// The current trap handler config.
static test_trap_handler_cfg th_cfg;

void setup_test_trap_handler (test_trap_handler_cfg * cfg) {
    th_cfg.expect_trap    = cfg -> expect_trap   ;
    th_cfg.check_mcause   = cfg -> check_mcause  ;
    th_cfg.expect_mcause  = cfg -> expect_mcause ;
    th_cfg.check_mepc     = cfg -> check_mepc    ;
    th_cfg.expect_mepc    = cfg -> expect_mepc   ;
    th_cfg.check_mtval    = cfg -> check_mtval   ;
    th_cfg.expect_mtval   = cfg -> expect_mtval  ;
    th_cfg.step_over_mepc = cfg -> step_over_mepc;
    th_cfg.trap_seen      = cfg -> trap_seen     ;

    uint32_t handler_addr = (uint32_t)&__asm_test_trap_handler;
    scarv_cpu_wr_mtvec(handler_addr);
}


void __attribute__ ((used)) test_trap_handler() {

    if(th_cfg.trap_seen != NULL) {
        th_cfg.trap_seen[0] = 1;
    }

    if(!th_cfg.expect_trap) {
        __putstr("!A\n");
        test_fail();
    }

    if(th_cfg.check_mcause) {
        uint32_t mcause = scarv_cpu_get_mcause();
        uint32_t val    = 0x1 << mcause & (th_cfg.expect_mcause);

        if(val) {
            // All okay.
        } else {
            __putstr("!B\n");
            test_fail(); // Un-expected mcause value.
        }
    }

    if(th_cfg.check_mepc) {
        uint32_t mepc = scarv_cpu_get_mepc();
        if(mepc != th_cfg.expect_mepc) {
            __putstr("!C\n");
            test_fail(); // Un-expected mepc value.
        }
    }
    
    if(th_cfg.check_mtval) {
        uint32_t mtval = scarv_cpu_get_mtval();
        if(mtval != th_cfg.expect_mtval) {
            __putstr("!D\n");
            test_fail(); // Un-expected mtval value.
        }
    }

    if(th_cfg.step_over_mepc) {
        uint32_t mepc = scarv_cpu_get_mepc();
        uint8_t  ib0  = ((uint8_t*)mepc)[0];
        mepc += 2; // Always increment MEPC by two bytes.
        if((ib0 & 0x3) == 0x3) {
            // Faulting instr was 32-bits long, so increment by 2 bytes again.
            mepc += 2;
        }
        scarv_cpu_wr_mepc(mepc);
    }

    return;
}
