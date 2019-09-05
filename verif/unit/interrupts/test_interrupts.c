
#include "unit_test.h"

#include "test_interrupts.h"


//! Check interrupts can be enabled / disabled globally.
int test_global_interrupt_enable() {

    // Make sure mtimecmp is at it's maximum value.
    __mtimecmp[0] = 0xFFFFFFFFFFFFFFFF;
    
    uint32_t mstatus    = __rd_mstatus();

    uint32_t mie= mstatus & MSTATUS_MIE;
    uint32_t sie= mstatus & MSTATUS_SIE;
    uint32_t uie= mstatus & MSTATUS_UIE;

    // U/S mode not implemented. uie/sie should never be set.
    if(sie) {return 1;}
    if(uie) {return 2;}

    // Writes should be ignored to UIE / SIE
    __set_mstatus(MSTATUS_SIE | MSTATUS_UIE);
    
    mstatus     = __rd_mstatus();
    sie         = mstatus & MSTATUS_SIE;
    uie         = mstatus & MSTATUS_UIE;

    if(sie) {return 3; }
    if(uie) {return 4; }
    
    // Clear MIE bit. No interrupts enabled.
    __clr_mstatus(MSTATUS_MIE);

    mstatus     = __rd_mstatus();
    mie         = mstatus & MSTATUS_MIE;

    // MIE should be zero now.
    if(mie) {return 5;}

    // Set MIE bit.
    __set_mstatus(MSTATUS_MIE);

    mstatus     = __rd_mstatus();
    mie         = mstatus & MSTATUS_MIE;

    // MIE should be set now.
    if(!mie){return 6;}

    // Leave interrupts disabled.
    __clr_mstatus(MSTATUS_MIE);

    return 0;
}

//! Check external/software/timer interrupts can be enabled/disabled
int test_individual_interrupt_enable() {
    
    // Start by clearing all interrupt enable bits.
    __clr_mstatus(MSTATUS_MIE | MSTATUS_SIE | MSTATUS_UIE);
    __clr_mie(MIE_MEIE | MIE_MTIE | MIE_MSIE);

    // Check they are all zeroe'd appropriately
    uint32_t mstatus = __rd_mstatus();
    uint32_t mie     = __rd_mie();

    if(mstatus & MSTATUS_MIE){return 7;}
    if(mstatus & MSTATUS_SIE){return 8;}
    if(mstatus & MSTATUS_UIE){return 9;}
    
    if(mie     & MIE_MEIE){return 10;}
    if(mie     & MIE_MTIE){return 11;}
    if(mie     & MIE_MSIE){return 12;}

    // Check we can enable them one by one.

    // External interrupts
    __set_mie(MIE_MEIE);
    mie     = __rd_mie();
    if(!(mie & MIE_MEIE)){return 13;}
    __clr_mie(MIE_MEIE);

    // Software interrupts
    __set_mie(MIE_MSIE);
    mie     = __rd_mie();
    if(!(mie & MIE_MSIE)){return 14;}
    __clr_mie(MIE_MSIE);

    // Timer interrupts
    __set_mie(MIE_MTIE);
    mie     = __rd_mie();
    if(!(mie & MIE_MTIE)){return 15;}
    __clr_mie(MIE_MTIE);

    return 0;

}

//! Check that we can cause a timer interrupt.
int test_timer_interupt() {

    volatile int interrupt_seen = 0;

    // Globally Disable interrupts
    __clr_mstatus(MSTATUS_MIE);

    // Disable all other interrupt sources.
    __clr_mie(MIE_MEIE | MIE_MSIE);

    // Enable timer interrupts.
    __set_mie(MIE_MTIE);

    // Setup the interrupt handler vector.
    setup_timer_interrupt_handler(
        &interrupt_seen
    );

    // Add a big value to mtime and set mtimecmp to this.
    __mtimecmp[0] = __mtime[0] + 400;

    // Re-enable interrupts.
    __set_mstatus(MSTATUS_MIE);

    for(int i = 0; i < 200; i ++) {
        // Spin round doing nothing, waiting to see the interrupt.
        if(interrupt_seen) {
            break;
        }
    }
    
    // Globally Disable interrupts again.
    __clr_mstatus(MSTATUS_MIE);
    
    if(interrupt_seen) {
        return 0;
    } else {
        return 1;
    }
}

//! Check that when a trap occurs, mpp, mpie and mie are set correctly.

//! Check that we can schedule a timer interrupt and it is raised correctly.

/*!
@brief Test for interrupt control.
*/
int test_main() {

    int fail;
    
    fail = test_global_interrupt_enable();
    if(fail){return fail;}


    fail = test_individual_interrupt_enable();
    if(fail){return fail;}


    fail = test_timer_interupt();
    if(fail){return fail;}


    return 0;
}
