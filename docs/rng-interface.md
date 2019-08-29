
# Random Number Generator Interface

*This document describes the logic interface between the CPU and
a random number generator.*

---

## Overview

XCrypto defines an *architectural interface* to a random number generator
using the `xc.rng*` instructions.

This document describes how the `scarv-cpu` implements this interface,
allowing different RNG implementations which meet this interface to be
attatched too it.

## Signals

- The interface consists of two channels:

  - The request channel, driven by the CPU.

  - The response channel, driven by the RNG.

- Both channels follow a `valid`/`ready` protocol, meaning both the CPU
  and the RNG can control the rate of information flow.

  - Data transfer occurs *only* when both `rng_*_valid` *and* `rng_*_ready`
    are both set for the respective channels.

  - Responses only occur due to a request.

  - Responses must occur in the order the corresponding requests were made in.

### Request Interface:

Name             | Width| Description
-----------------|------|----------------------------------------------
`rng_req_valid`  | 1    | Signal a new request to the RNG
`rng_req_op`     | 3    | Operation to perform on the RNG
`rng_req_data`   | 32   | Suplementary seed/init data
`rng_req_ready`  | 1    | RNG accepts request

The `rng_req_op` signal is encoded thusly:

Encoding | Meaning
---------|--------------------------
`001`    | Seed
`010`    | Sample
`100`    | Status Check
*Else*   | Reserved for future use.


### Response Interface:

Name             | Width| Description
-----------------|------|----------------------------------------------
`rng_rsp_valid`  | 1    | RNG response data valid
`rng_rsp_status` | 3    | RNG status
`rng_rsp_data`   | 32   | RNG response / sample data.
`rng_rsp_ready`  | 1    | CPU accepts response.

The `rng_rsp_status` signal is encoded thusly:

Encoding | Meaning
---------|--------------------------
`001`    | Un-initialised
`010`    | Initialised - not enough entropy.
`100`    | Initialised - ready to be sampled.
*Else*   | Reserved for future use.
