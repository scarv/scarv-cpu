
#include <iostream>
#include "sram_agent.hpp"
    
    
sram_agent::sram_agent (
    memory_device * mem
) {
    this -> mem = mem;
}


//! Put the interface in reset
void sram_agent::set_reset(){

    *mem_gnt = 0;
    *mem_recv= 0;

    // Empty the request queue.
    while(this -> req_q.empty() == false) {
        delete this -> req_q.back();
        this -> req_q.pop();
    }
    
}


//! Take the interface out of reset
void sram_agent::clear_reset(){

}


//! handles populating of read data or writing of write data.
void sram_agent::handle_read_write(
    sram_agent_req * req    //!< The request to handle.
){
        
    uint64_t addr = req -> addr;
        
    if(req -> write) {

        uint32_t wdata= req -> data;

        req -> success = true;
        
        if(req -> wstrb & 0b0001) {
            req -> success &= mem -> write_byte(addr+0,(wdata>> 0)&0xFF);
        }
        
        if(req -> wstrb & 0b0010) {
            req -> success &= mem -> write_byte(addr+1,(wdata>> 8)&0xFF);
        }
        
        if(req -> wstrb & 0b0100) {
            req -> success &= mem -> write_byte(addr+2,(wdata>>16)&0xFF);
        }
        
        if(req -> wstrb & 0b1000) {
            req -> success &= mem -> write_byte(addr+3,(wdata>>24)&0xFF);
        }

        if(req -> success == false) {
            std::cerr << "Failed write to " << std::hex << addr
                      << std::endl;
        }

    } else {
        req -> success = this -> mem -> read_word(
            req -> addr, &req -> data
        );

        if(!req -> success) {
            n_mem_error = 1;
            std::cerr << "Failed read from " << std::hex << addr
                      << std::endl;
        }
    }

}

//! Drive any signal updates
void sram_agent::drive_signals(){

    *mem_recv   = n_mem_recv;
    *mem_error  = n_mem_error;
    *mem_rdata  = n_mem_rdata;
    *mem_gnt    = n_mem_gnt;

}


//! Compute any *next* signal values
void sram_agent::posedge_clk(){
    
    //
    // Respond to any outstanding transactions.
    if(req_q.empty() == false && this -> rand_chance(9,10)) {

        sram_agent_req * req = req_q.front();

        handle_read_write(req);
        
        n_mem_error = !(req -> success);
        n_mem_recv  = 1;
        n_mem_rdata = req -> data;

        req_q.pop();
        delete req;

    } else {
        
        n_mem_error = 0;
        n_mem_recv  = 0;
        n_mem_rdata = 0;

    }

    //
    // Check for new transaction requests
    
    bool new_txn = *mem_req && *mem_gnt;

    if(new_txn) {
        // There is an active request.
        req_q.push(new sram_agent_req (
            *mem_addr,
            *mem_wen ,
            *mem_strb,
            *mem_wdata
        ));
    }
    
    // Randomise the stall signal value.
    n_mem_gnt = this -> rand_chance(6,10);

}
