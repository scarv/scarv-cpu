
#include <stdint.h>

#ifndef UART_BASE
    #define UART_BASE 0x40600000
#endif

#define UART_RX 0
#define UART_TX 1
#define UART_ST 2
#define UART_CT 3

// Pointer to the UART register space.
static volatile uint32_t * uart = (volatile uint32_t*)(UART_BASE);

const uint32_t UART_CTRL_RST_TX_FIFO = 0x00000001;
const uint32_t UART_CTRL_RST_RX_FIFO = 0x00000002;
const uint32_t UART_CTRL_INT_ENA     = 0x00000010;

const uint32_t UART_STATUS_RX_VALID  = 0x00000001;
const uint32_t UART_STATUS_TX_FULL   = 0x00000008;

//! Read a single character from the UART.
uint8_t uart_rd_char(){
    while(!(uart[UART_ST] & UART_STATUS_RX_VALID)) {
        // Do nothing.
    }
    return (uint8_t)uart[UART_RX];
}

//! Jump to the main function
extern void __fsbl_goto_main(uint32_t * tgt);

/*!
@brief Setup the UART peripheral
@details Configures the UART peripheral such that:
- The TX and RX fifos are empty
- Interrupts are disabled
*/
void fsbl_uart_setup() {

    uart[UART_CT] = UART_CTRL_RST_TX_FIFO | UART_CTRL_RST_RX_FIFO ;

}

/*!
@brief Print the simple welcome message to show we are ready.
*/
void fsbl_print_welcome() {

    // Welcome message
    char * welcome = "scarv-cpu fsbl\n";

    for(char * p = welcome; *p != 0; p++ ) {
        
        while(uart[UART_ST] & UART_STATUS_TX_FULL) {
            // Do nothing.
        }   
        uart[UART_TX] = *p;

    }
}

/*!
@brief First stage boot loader function.
*/
void fsbl() {

    fsbl_uart_setup();

    fsbl_print_welcome();
    
    // First 4 bytes are the size of the program (in bytes).
    uint32_t    program_size =
        ((uint32_t)uart_rd_char() << 24) |
        ((uint32_t)uart_rd_char() << 16) |
        ((uint32_t)uart_rd_char() <<  8) |
        ((uint32_t)uart_rd_char() <<  0) ;
    
    // Next 4 bytes are a 32-bit destination address.
    uint32_t    program_dest =
        ((uint32_t)uart_rd_char() << 24) |
        ((uint32_t)uart_rd_char() << 16) |
        ((uint32_t)uart_rd_char() <<  8) |
        ((uint32_t)uart_rd_char() <<  0) ;

    uint8_t * dest_ptr = (uint8_t*)program_dest;

    // Download the program and write it to the destination memory.
    for(uint32_t i = 0; i < program_size; i ++) {
        
        dest_ptr[i] = uart_rd_char();

    }

    // Jump to the downloaded program.
    __fsbl_goto_main((uint32_t*)program_dest);

}
