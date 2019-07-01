
#include <iostream>
#include "sram_agent.hpp"
    
    
sram_agent::sram_agent (
    memory_device * mem
) {
    this -> mem = mem;
}


//! Put the interface in reset
void sram_agent::set_reset(){

    *mem_error  = 0;  // Next Error
    *mem_stall  = 0;  // Next Memory stall
    *mem_rdata  = 0;  // Next Read data
    n_mem_error = 0;  // Next Error
    n_mem_stall = 0;  // Next Memory stall
    n_mem_rdata = 0;  // Next Read data
}

//! Take the interface out of reset
void sram_agent::clear_reset(){
    *mem_stall  = this -> rand_chance(5,10);  // Next Memory stall
}

//! Compute any *next* signal values
void sram_agent::posedge_clk(){

    n_mem_stall = 0;//this -> rand_chance(5,10);  // Next Memory stall

}

//! Drive any signal updates
void sram_agent::drive_signals(){
    
    if(*mem_cen) {
        
        uint64_t addr = *mem_addr;
        uint32_t wdata= *mem_wdata;

        if(*mem_wen) {

            bool write_success = true;
            
            if(*this -> mem_strb & 0b0001) {
                write_success &= this -> mem -> write_byte(addr+0,(wdata>> 0)&0xFF);
            }
            
            if(*this -> mem_strb & 0b0010) {
                write_success &= this -> mem -> write_byte(addr+1,(wdata>> 8)&0xFF);
            }
            
            if(*this -> mem_strb & 0b0100) {
                write_success &= this -> mem -> write_byte(addr+2,(wdata>>16)&0xFF);
            }
            
            if(*this -> mem_strb & 0b1000) {
                write_success &= this -> mem -> write_byte(addr+3,(wdata>>24)&0xFF);
            }

            if(write_success == false) {
                n_mem_error = 1;
                std::cerr << "Failed write to " << std::hex << addr
                          << std::endl;
            }

        } else {
            bool read_success = this -> mem -> read_word(
                addr, &n_mem_rdata
            );

            if(read_success) {
                n_mem_error = 0;
            } else {
                n_mem_error = 1;
                std::cerr << "Failed read from " << std::hex << addr
                          << std::endl;
            }
        }

    } else {

        // No outstanding response. Randomise everything.
        n_mem_error = 0;  // Next Error

    }

    *mem_error  = n_mem_error;  // Next Error
    *mem_stall  = n_mem_stall;
    *mem_rdata  = n_mem_rdata;  // Next Read data

}
