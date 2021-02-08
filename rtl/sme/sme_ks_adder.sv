
module sme_ks_adder #(
parameter D =  3, // Number of shares.
parameter N = 32  // Width of the operation.
)(
input             g_clk     , // Global clock
input             g_clk_req , // Global clock request
input             g_resetn  , // Sychronous active low reset.

input             en        , // Operation Enable.
input             sub       , // Subtract when =1, add when =0.
input  [XLEN-1:0] rng [D-1:0],// Extra randomness.

input  [XLEN-1:0] rs1 [D-1:0], // RS1 as SMAX shares
input  [XLEN-1:0] rs2 [D-1:0], // RS2 as SMAX shares

output [XLEN-1:0] rd  [D-1:0]  // RD as SMAX shares

);


endmodule

