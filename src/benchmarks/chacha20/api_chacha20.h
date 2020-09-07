
#include <stdint.h>

#ifndef __CHACHA20_API_H__
#define __CHACHA20_API_H__

 
//! The chacha20 block function.
void chacha20_block(uint32_t out[16], uint32_t const in[16]);

#endif
