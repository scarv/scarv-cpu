
#include <stdint.h>

#ifndef UART_BASE
    #define UART_BASE 0x40600000
#endif

#ifndef GPIO_BASE
    #define GPIO_BASE 0x40000000
#endif

#define GPIO_LEDS 2

#define UART_RX 0
#define UART_TX 1
#define UART_ST 2
#define UART_CT 3

// Pointer to the UART register space.
static volatile uint32_t * uart = (volatile uint32_t*)(UART_BASE);

static volatile uint32_t * gpio = (volatile uint32_t*)(GPIO_BASE);

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

    for(int i = 0; welcome[i]; i ++) {
        
        while(uart[UART_ST] & UART_STATUS_TX_FULL) {
            // Do nothing.
        }   
        uart[UART_TX] = welcome[i];

    }
}

/*!
@brief First stage boot loader function.
*/
void fsbl() {
    
    gpio[GPIO_LEDS] = 0x1;

    fsbl_uart_setup();
    
    gpio[GPIO_LEDS] = 0x2;

    fsbl_print_welcome();
    
    gpio[GPIO_LEDS] = 0x4;
    
    // First 4 bytes are the size of the program (in bytes).
    uint32_t    program_size =
        ((uint32_t)uart_rd_char() << 24) |
        ((uint32_t)uart_rd_char() << 16) |
        ((uint32_t)uart_rd_char() <<  8) |
        ((uint32_t)uart_rd_char() <<  0) ;
    
    gpio[GPIO_LEDS] = 0x8;
    
    // Next 4 bytes are a 32-bit destination address.
    uint32_t    program_dest =
        ((uint32_t)uart_rd_char() << 24) |
        ((uint32_t)uart_rd_char() << 16) |
        ((uint32_t)uart_rd_char() <<  8) |
        ((uint32_t)uart_rd_char() <<  0) ;
    
    gpio[GPIO_LEDS] = -1;

    int bytes_per_led = program_size / 8;
    int led_count     = 0;

    uint8_t * dest_ptr = (uint8_t*)program_dest;

    // Download the program and write it to the destination memory.
    for(uint32_t i = 0; i < program_size; i ++) {

        led_count += 1;
        
        dest_ptr[i] = uart_rd_char();

        if(led_count >= bytes_per_led) {
            led_count = 0;

            gpio[GPIO_LEDS] = gpio[GPIO_LEDS] << 1;
        }

    }
    
    gpio[GPIO_LEDS] = 0x0;

    // Jump to the downloaded program.
    __fsbl_goto_main((uint32_t*)program_dest);

}
