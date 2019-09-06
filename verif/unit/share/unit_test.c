
#include "unit_test.h"

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
