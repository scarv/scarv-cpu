
#include "memory_device.hpp"
#include <queue>

#ifndef SRAM_AGENT_HPP
#define SRAM_AGENT_HPP

/*!
@brief Contains all required information on a single SRAM interface request.
*/
class sram_agent_req {

public:

    //! Create a new request object.
    sram_agent_req (
        uint32_t addr   , //!< Address of the request.
        bool     write  , //!< Is this a write request?
        uint8_t  wstrb  , //!< Write strobe enable.
        uint32_t data     //!< Read/Write data
    ) {
        this -> addr  = addr ;
        this -> write = write;
        this -> wstrb = wstrb;
        this -> data  = data ;
    }

    uint32_t addr   ; //!< Address of the request.
    bool     write  ; //!< Is this a write request?
    uint8_t  wstrb  ; //!< Write strobe enable.
    uint32_t  data  ; //!< Read/Write data
    bool     success; //!< Did the access succeed?

};

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

    // Request channel
    uint8_t  * mem_req  ; // Start memory request
    uint8_t  * mem_gnt  ; // request accepted
    uint8_t  * mem_wen  ; // Write enable
    uint8_t  * mem_strb ; // Write strobe
    uint32_t * mem_wdata; // Write data
    uint32_t * mem_addr ; // Read/Write address

    // Response channel
    uint8_t  * mem_recv ; // Instruction memory recieve response.
    uint8_t  * mem_error; // Error
    uint32_t * mem_rdata; // Read data

protected:
    
    //! memory device this agent can access.
    memory_device* mem;
    
    //! Queue of requests to handle.
    std::queue<sram_agent_req*> req_q;
    
    uint8_t  n_mem_error;  // Next Error
    uint8_t  n_mem_recv ;  // Next Memory stall
    uint32_t n_mem_rdata;  // Next Read data
    uint32_t n_mem_gnt  ;  // Next request grant.
    
    uint8_t rand_chance(int a, int b) {
        return ((rand() % b) < a) ? 1 : 0;
    }

    //! handles populating of read data or writing of write data.
    void handle_read_write(
        sram_agent_req * req    //!< The request to handle.
    );
};

#endif
