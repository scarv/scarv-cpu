
/*!
@defgroup crypto_hash_sha256 Crypto Hash SHA256
@{
*/

#include <stdint.h>

#ifndef __API_SHA256__
#define __API_SHA256__

void sha256_hash_block (
    uint32_t    H[ 8], //!< in,out - message block hash
    uint32_t    M[16]  //!< in - The message block to add to the hash
);

/*! @} */

#endif // __API_SHA256__
