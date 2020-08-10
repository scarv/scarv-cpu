
#include "scarv_cpu_csp.h"

//
// These are all provided by the linker script.
extern uint32_t volatile * __mmio_mtime_lo   ;
extern uint32_t volatile * __mmio_mtime_hi   ;
extern uint32_t volatile * __mmio_mtimecmp_lo;
extern uint32_t volatile * __mmio_mtimecmp_hi;
extern uint32_t volatile * __mmio_trng       ;

/*!
@details
If the SCARV_CPU_FREQ compiler define *is* defined, then take
its value. Otherwise, set a default value of 50MHz.
*/
const uint32_t scarv_cpu_freq = 50000000;

/*!
*/
inline uint64_t scarv_cpu_get_mtime(){
    uint32_t lo1, lo2, hi1;
    do {
        lo1 = (uint32_t)(&__mmio_mtime_lo)[0];
        hi1 = (uint32_t)(&__mmio_mtime_lo)[1];
        lo2 = (uint32_t)(&__mmio_mtime_lo)[0];
    } while(lo2 < lo1);
    return ((uint64_t)hi1 << 32) | lo2;
}

/*!
*/
inline void     scarv_cpu_set_mtime(uint64_t nv){
    (&__mmio_mtime_lo)[0] = (uint32_t)(nv >>  0);
    (&__mmio_mtime_lo)[1] = (uint32_t)(nv >> 32);
    if((uint32_t)(&__mmio_mtimecmp_lo)[1] != nv >> 32) {
        (&__mmio_mtime_lo)[0] = (uint32_t)(nv >>  0);
        (&__mmio_mtime_lo)[1] = (uint32_t)(nv >> 32);
    }
}

/*!
*/
inline uint32_t scarv_cpu_get_mtime_lo(){
    return (uint32_t)(&__mmio_mtime_lo)[0];
}

/*!
*/
inline uint64_t scarv_cpu_get_mtimecmp(){
    uint32_t lo1, hi1;
    lo1 = (uint32_t)(&__mmio_mtimecmp_lo)[0];
    hi1 = (uint32_t)(&__mmio_mtimecmp_lo)[1];
    return ((uint64_t)hi1 << 32) | lo1;
}

/*!
*/
inline void     scarv_cpu_set_mtimecmp(uint64_t nv){
    (&__mmio_mtimecmp_lo)[0] = (uint32_t)(nv >>  0);
    (&__mmio_mtimecmp_lo)[1] = (uint32_t)(nv >> 32);
}
