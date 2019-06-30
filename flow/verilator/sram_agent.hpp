
#include "memory_device.hpp"
#include <vector>

#ifndef SRAM_AGENT_HPP
#define SRAM_AGENT_HPP

/*!
@brief Acts as an SRAM slave agent.
*/
class sram_agent {

public:

    sram_agent (
        memory_device * mem
    );


    //! Put the interface in reset
    void set_reset();
    
    //! Take the interface out of reset
    void clear_reset();
    
    //! Compute any *next* signal values
    void posedge_clk();

    //! Drive any signal updates
    void drive_signals();

    uint8_t  * mem_cen  ;  // Current Chip enable
    uint8_t  * mem_wen  ;  // Current Write enable
    uint8_t  * mem_error;  // Current Error
    uint8_t  * mem_stall;  // Current Memory stall
    uint8_t  * mem_strb ;  // Current Write strobe
    uint32_t * mem_addr ;  // Current Read/Write address
    uint32_t * mem_rdata;  // Current Read data
    uint32_t * mem_wdata;  // Current Write data

protected:
    
    //! memory device this agent can access.
    memory_device* mem;
    
    uint8_t  n_mem_error;  // Next Error
    uint8_t  n_mem_stall;  // Next Memory stall
    uint32_t n_mem_rdata;  // Next Read data
    
    uint8_t rand_chance(int a, int b) {
        return ((rand() % b) < a) ? 1 : 0;
    }
};

#endif
