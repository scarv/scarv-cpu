
`ifndef __CHECKERS_COMMON_SVH__
`define __CHECKERS_COMMON_SVH__

`define ROR32(x, y) ((x >> y) | (x << (32-y)))
`define ROL32(x, y) ((x << y) | (x >> (32-y)))

`endif
