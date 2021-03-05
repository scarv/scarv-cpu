
//
// module: sme_rng
//
//  Random number source for the SME module.
//
module sme_rng #(
parameter XLEN  =32,
parameter SMAX  = 3 
)(
input       g_clk       ,
output      g_clk_req   ,
input       g_resetn    , // Sychronous active low reset.
input       update      , // Update the internal RNG.
output [XL:0] rng[RM:0]   // RNG outputs.
);

localparam RMAX  = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;

assign g_clk_req = update;

wire [RM:0] trng_taps ;
wire [RM:0] trng_ready;

genvar prng;
generate for(prng=0; prng<RMAX; prng = prng+1) begin: g_prngs

    sme_lfsr32 #(
        .RESET_VALUE(prng ^ (32'h3456_789A<<prng | 32'h3456_789A>>prng))
    ) i_lfsr32 (
        .g_clk    (g_clk            ), // Clock to update PRNG
        .g_resetn (g_resetn         ), // Syncrhonous active low reset.
        .update   (1'b1             ), // Update PRNG with new value.
        .extra_tap(trng_taps[prng]  ), // Additional seed bit, from TRNG.
        .prng     (rng[prng]        )  // Current PRNG value.
    );

end endgenerate // g_prngs


//
// TRNG Instance

`ifndef VERILATOR

sme_trng #(
.Nb (RMAX),
.Ne (3   ),
.ORD(3   )
) i_trng (
.g_clk      (g_clk      ),
.g_resetn   (g_resetn   ),
.gen        (update     ),
.rnb        (trng_taps  ),
.rdy        (trng_ready )
);

`else

assign trng_taps = {RMAX{1'b0}};
assign trng_ready= {RMAX{1'b0}};

`endif

endmodule
