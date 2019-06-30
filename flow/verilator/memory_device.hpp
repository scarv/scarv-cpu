
#include <cstdint>
#include <map>

#ifndef MEMORY_DEVICE_HPP
#define MEMORY_DEVICE_HPP


class memory_device {

public:

    memory_device (
        uint64_t base,
        uint64_t range
    );

    ~memory_device();

    uint64_t get_base (){return this -> addr_base ;}
    uint64_t get_range(){return this -> addr_range;}
    uint64_t get_top  (){return this -> addr_top  ;}

    /*
    @brief Return true iff the supplied address is inside this device range
    */
    bool     in_range (
        uint64_t addr //!< Base address
    ) {
        return (addr >= this -> get_base()) && (addr <= this -> get_top());
    }
    
    /*!
    @brief Return true iff the supplied address range is wholly inside this
    device range
    */
    bool     in_range (
        uint64_t addr,  //!< Base of the query
        uint64_t size   //!< Size of the query
    ) {
        return  ((addr     ) >= this -> get_base()) &&
                ((addr+size) <= this -> get_top ());
    }

    /*!
    @brief Read a word from the address given.
    @returns true if the read succeeds. False otherwise.
    */
    bool read_word (
        uint64_t addr,
        uint32_t * dout
    );

    /*!
    @brief Write a single byte to the device.
    @return true if the write is in range, else false.
    */
    bool write_byte (
        uint64_t addr,
        uint8_t  data
    );

    /*!
    @brief Return a single byte from the device.
    */
    uint8_t read_byte (
        uint64_t addr
    ) {
        return memory[addr];
    }

protected:

    uint64_t addr_base ;    //!< Base address of the device.
    uint64_t addr_range;    //!< Size of the device address range.
    uint64_t addr_top  ;    //!< Top address of the device.
    
    //! The underlying memory.
    std::map<uint64_t, uint8_t> memory;   

};

#endif

