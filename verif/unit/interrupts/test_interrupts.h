
#ifndef TEST_INTERRUPTS_H
#define TEST_INTERRUPTS_H

#define MSTATUS_MIE  (0x00000001 <<  3)
#define MSTATUS_SIE  (0x00000001 <<  1)
#define MSTATUS_UIE  (0x00000001 <<  0)

#define MIP_MEIP     (0x00000001 << 11)
#define MIP_MTIP     (0x00000001 <<  7)
#define MIP_MSIP     (0x00000001 <<  3)

#define MIE_MEIE     (0x00000001 << 11)
#define MIE_MTIE     (0x00000001 <<  7)
#define MIE_MSIE     (0x00000001 <<  3)


//! Setup the interrupt handler.
void setup_timer_interrupt_handler(
    volatile int * indicator
);

#endif

