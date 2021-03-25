
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
output [RW:0] rng         // RNG outputs.
);

localparam RMAX = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM   = RMAX-1;
localparam RW   = RMAX*XLEN-1;

localparam KECCAK_LW = 8;
localparam KS        = 25*KECCAK_LW-1;

wire [KS:0] keccak_state;

assign g_clk_req = update;

wire [RM:0] trng_taps ;
wire [RM:0] trng_ready;

genvar i, j;
generate
    for(i = 0; i < RMAX; i=i+1) begin
        for(j = 0; j < XLEN; j=j+1) begin
            assign rng[i*XLEN+j] = keccak_state[i*XLEN+j];
        end
    end
endgenerate

//
// Keccak Instance
sme_keccak #(
.LW     (KECCAK_LW  ),
.TAPS   (RMAX       )
) i_sme_keccak (
.g_clk    (g_clk        ),
.g_resetn (g_resetn     ),
.update   (update       ),
.taps     (trng_taps    ),
.state    (keccak_state )    // Current state
);


//
// TRNG Instance

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

endmodule
