
//
// module: frv_leak
//
//  Handles the leakage barrier instruction state and some functionality.
//  Contains the configuration register and pseudo random number source.
//
module frv_leak (

input  wire         g_clk           ,
input  wire         g_resetn        ,

output reg  [XL:0]  leak_prng       , // Current PRNG value.

input  wire         leak_fence        // Fence instruction flying past.

);

// Common core parameters and constants
`include "frv_common.vh"

// Is any of this implemented?
parameter XC_CLASS_LEAK       = 1'b1;

// Randomise registers (if set) or zero them (if clear)
parameter XC_CLASS_LEAK_STRONG= 1'b1;

// Reset value for the ALCFG register
parameter ALCFG_RESET_VALUE = 13'b0;

// Reset value for the PRNG.
parameter PRNG_RESET_VALUE  = 32'hABCDEF37;

generate if(XC_CLASS_LEAK) begin // Leakage instructions are implemented
    
    if(XC_CLASS_LEAK_STRONG) begin

        wire n_prng_lsb = leak_prng[31] ~^
                          leak_prng[21] ~^
                          leak_prng[ 1] ~^
                          leak_prng[ 0]  ;
        
        wire [XL:0] n_prng = {leak_prng[XL-1:0], n_prng_lsb};

        //
        // Process for updating the LFSR.
        always @(posedge g_clk) begin
            if(!g_resetn) begin
                leak_prng <= PRNG_RESET_VALUE;
            end else if(leak_fence) begin
                leak_prng <= n_prng;
            end
        end

    end else begin
        
        always @(*) leak_prng = 0;

    end

end else begin // Leakage instructions are not implemented

    always @(*) leak_prng  = {XLEN{1'b0}};

end endgenerate

endmodule
