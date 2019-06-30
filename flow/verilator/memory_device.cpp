
#include "memory_device.hpp"
    
memory_device::memory_device (
    uint64_t base,
    uint64_t range
) {
    
    this -> addr_base = base;
    this -> addr_range= range;
    this -> addr_top  = base + range;

}

memory_device::~memory_device() {
}


/*!
*/
bool memory_device::read_word (
    uint64_t addr,
    uint32_t * dout
){
    
    if(this -> in_range(addr, 4)) {
        
        *dout = 
            (uint32_t)this -> memory[addr+3] << 24 |
            (uint32_t)this -> memory[addr+2] << 16 |
            (uint32_t)this -> memory[addr+1] <<  8 |
            (uint32_t)this -> memory[addr+0] <<  0 ;

        return true;

    } else {
        return false;
    }
}
    
/*!
*/
bool memory_device::write_byte (
    uint64_t addr,
    uint8_t  data
){
    if(this -> in_range(addr, 1)) {
        
        this -> memory[addr] = data;

        return true;

    } else {
        return false;
    }
}

