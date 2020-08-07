
#include <cstdint>
#include <cstdlib>

#include "rng_agent.hpp"

const uint8_t rng_op_seed = 0b001;
const uint8_t rng_op_samp = 0b010;
const uint8_t rng_op_test = 0b100;

const uint8_t rng_status_noinit         = 0b000;
const uint8_t rng_status_init_unhealthy = 0b100;
const uint8_t rng_status_init_healthy   = 0b101;

//! Put the interface in reset
void rng_agent::set_reset() {

    *rng_req_ready = 0;
    *rng_rsp_valid = 0;

    req_stall_len  = 0;
    rsp_stall_len  = 0;

    status         = rng_status_noinit;

}

//! Take the interface out of reset
void rng_agent::clear_reset() {
    
    *rng_req_ready = rand_chance(5,10);
    *rng_rsp_valid = 0;

}

//! Compute any *next* signal values
void rng_agent::posedge_clk() {

    // Handle the request channel
    if(*rng_req_valid && !*rng_req_ready) {
        
        // stall accepting the request
        req_stall_len ++;

    } else if(*rng_req_valid && *rng_req_ready) {
        
        // Capture the request
        req_stall_len = 0;

        rng_agent_txn * txn = new rng_agent_txn;

        txn -> status = get_status();
        txn -> data   = rng_sample();

        if(*rng_req_op == rng_op_seed) {
            rng_seed(*rng_req_data);
        }

        rsp_q.push(txn);

    }
    
    // Handle the response channel
    if(rsp_q.size() && !*rng_rsp_valid) {
        
        // Stall the response
        rsp_stall_len ++;

    } else if(*rng_rsp_valid && *rng_rsp_ready) {
        
        // The response has been accepted so remove it
        // from the queue.
        rsp_stall_len = 0;
        
        delete rsp_q.front();
        rsp_q.pop();

    }

    n_rng_req_ready = rand_chance(5,10) || (req_stall_len > max_req_stall);

    n_rng_rsp_valid = (*rng_rsp_valid && !*rng_rsp_ready    ) ||
                      (rsp_q.size()   && rand_chance(5,10)  ) ||
                      (rsp_q.size()   && rsp_stall_len > max_rsp_stall);

    if(rsp_q.size() > 0) {

        n_rng_rsp_data  = rsp_q.front() -> data     ;
        n_rng_rsp_status= rsp_q.front() -> status   ;

    }

}

//! Drive any signal updates
void rng_agent::drive_signals() {
    
    *rng_req_ready  = n_rng_req_ready  ;
    *rng_rsp_valid  = n_rng_rsp_valid  ;
    *rng_rsp_status = n_rng_rsp_status ;
    *rng_rsp_data   = n_rng_rsp_data   ;

}
    
    
//! Get the current status of the RNG
uint8_t    rng_agent::get_status() {
    
    return this -> status;

}

//! Sample a new value from the RNG
uint32_t   rng_agent::rng_sample() {

    status = rand_chance(9,10) ? rng_status_init_healthy    : 
                                 rng_status_init_unhealthy  ;

    return std::rand();

}

//! Seed the RNG.
void       rng_agent::rng_seed  (uint32_t seed) {
    
    status = rng_status_init_unhealthy;
    
    std::srand(seed);

}

