
#include "scarv_cpu_csp.h"

// Define the values for memory mapped IO registers.
scarv_cpu_mmio_t scarv_cpu_mtime_lo       = __mmio_mtime_lo   ;
scarv_cpu_mmio_t scarv_cpu_mtime_hi       = __mmio_mtime_hi   ;
scarv_cpu_mmio_t scarv_cpu_mtimecmp_lo    = __mmio_mtimecmp_lo;
scarv_cpu_mmio_t scarv_cpu_mtimecmp_hi    = __mmio_mtimecmp_hi;
scarv_cpu_mmio_t scarv_cpu_trng           = __mmio_trng       ;

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
        lo1 = *scarv_cpu_mtime_lo;
        hi1 = *scarv_cpu_mtime_hi;
        lo2 = *scarv_cpu_mtime_lo;
    } while(lo2 < lo1);
    return ((uint64_t)hi1 << 32) | lo2;
}

/*!
*/
inline uint32_t scarv_cpu_get_mtime_lo(){
    return *scarv_cpu_mtime_lo;
}

/*!
*/
inline uint64_t scarv_cpu_get_mtimecmp(){
    uint32_t lo1, hi1;
    lo1 = *scarv_cpu_rd_mtime_lo;
    hi1 = *scarv_cpu_rd_mtime_hi;
    return ((uint64_t)hi1 << 32) | lo1;
}

/*!
*/
inline void     scarv_cpu_set_mtimecmp(uint64_t nv){
    *scarv_cpu_mtimecmp_hi = (uint32_t)(nv >> 32);
    *scarv_cpu_mtimecmp_lo = (uint32_t)(nv >>  0);
}
