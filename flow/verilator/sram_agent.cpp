
#include <iostream>

#include "sram_agent.hpp"
    
    
sram_agent::sram_agent (
    memory_bus * mem
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


//! Drive any signal updates
void sram_agent::drive_signals(){

    *mem_recv   = n_mem_recv;
    *mem_error  = n_mem_error;
    *mem_rdata  = n_mem_rdata;
    *mem_gnt    = n_mem_gnt;

}

//
// Called on each posedge of the clock, readies the *next* values.
void sram_agent::drive_response(){

    //
    // Respond to any outstanding transactions.
    if(req_q.empty() == false && 
       (this -> rand_chance(7,10) || (rsp_stall_len >= max_rsp_stall))) {

        memory_req_txn * req = req_q.front();

        memory_rsp_txn * rsp = this -> mem -> request(req);
        
        n_mem_error = rsp -> error();
        n_mem_recv  = 1;

        rsp_stall_len = 0;

        if(req -> is_read()) {
            n_mem_rdata = rsp -> data_word();
        }

        req_q.pop();
        delete rsp;
        delete req;

    } else {

        rsp_stall_len += req_q.size() > 0 ? 1 : 0;
        
        n_mem_error = 0;
        n_mem_recv  = 0;
        n_mem_rdata = 0;

    }

}

//! Compute any *next* signal values
void sram_agent::posedge_clk(){

    //
    // Check for new transaction requests
    
    bool new_txn = *mem_req && *mem_gnt;

    if(*mem_req && !*mem_gnt) {
        req_stall_len += 1;
    }

    if(new_txn) {
        // There is an active request.

        req_stall_len      = 0;

        size_t txn_length  = 4;

        memory_req_txn * req = new memory_req_txn(
            *mem_addr,
            txn_length,
            *mem_wen
        );

        if(*mem_wen) {

            for(int i = 0; i < 4 ; i ++) {
                req -> data()[i] = (*mem_wdata>> (8*i)) & 0xFF;
                req -> strb()[i] = (bool)((*mem_strb >> i    ) & 0x1);
            }

        }

        req_q.push(req);
    }
    
    // Randomise the stall signal value.
    n_mem_gnt = this -> rand_chance(7,10) ||
                (req_stall_len >= max_req_stall);

    
    if       (!*mem_recv  && !*mem_ack) {
        drive_response();

    } else if(!*mem_recv  &&  *mem_ack) {
        drive_response();
    
    } else if( *mem_recv  && !*mem_ack) {
        // Do nothing, waiting to accept response.
    
    } else if( *mem_recv  &&  *mem_ack) {
        drive_response();

    }

}
