
#include <queue>

#include "memory_txns.hpp"
#include "memory_bus.hpp"

#ifndef SRAM_AGENT_HPP
#define SRAM_AGENT_HPP

/*!
@brief Acts as an SRAM slave agent.
*/
class sram_agent {

public:

    sram_agent (
        memory_bus * mem
    );


    //! Put the interface in reset
    void set_reset();
    
    //! Take the interface out of reset
    void clear_reset();
    
    //! Compute any *next* signal values
    void posedge_clk();

    //! Drive any signal updates
    void drive_signals();

    // Request channel
    uint8_t  * mem_req  ; // Start memory request
    uint8_t  * mem_gnt  ; // request accepted
    uint8_t  * mem_wen  ; // Write enable
    uint8_t  * mem_strb ; // Write strobe
    uint32_t * mem_wdata; // Write data
    uint32_t * mem_addr ; // Read/Write address

    // Response channel
    uint8_t  * mem_error; // Error
    uint32_t * mem_rdata; // Read data

    //! Maximum length of a stalled request.
    uint32_t   max_req_stall = 5;

protected:

    //! Current request stall length.
    uint32_t   req_stall_len = 0;
    
    //! memory bus this agent can access.
    memory_bus * mem;
    
    //! Queue of requests to handle.
    std::queue<memory_req_txn *> req_q;
    
    uint8_t  n_mem_error;  // Next Error
    uint32_t n_mem_rdata;  // Next Read data
    uint32_t n_mem_gnt  ;  // Next request grant.
    
    uint8_t rand_chance(int a, int b) {
        return ((rand() % b) < a) ? 1 : 0;
    }
    
    //! Drives the response channel.
    void drive_response();
};

#endif
