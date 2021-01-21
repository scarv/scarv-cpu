

//
// module: frv_lfsr32
//
//  Simple 32-bit LFSR with parameterisable reset value.
//
module frv_lfsr32 #(
parameter RESET_VALUE = 32'h6789ABCD
)(
input  wire        g_clk      , // Clock to update PRNG
input  wire        g_resetn   , // Syncrhonous active low reset.
input  wire        update     , // Update PRNG with new value.
input  wire        extra_tap  , // Additional seed bit, possibly from TRNG.
output reg  [31:0] prng       , // Current PRNG value.
output wire [31:0] n_prng       // Next PRNG value.
);

wire        n_prng_lsb =  prng[31] ~^ prng[21] ~^ prng[ 1] ~^ prng[ 0] ^
                          extra_tap ;

assign n_prng     = {prng[31-1:0], n_prng_lsb};

always @(posedge g_clk) begin
    if     (!g_resetn) prng <= RESET_VALUE;
    else if( update  ) prng <= n_prng;
end

endmodule
