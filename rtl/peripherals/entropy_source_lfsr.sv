
//
//                    DO NOT USE IN PRODUCTION!
//
// module: entropy_source
//
//  A very basic pseudo-random number generator which can connect to the
//  scarv-cpu via it's randomness interface.
//
//                    DO NOT USE IN PRODUCTION!
//
module entropy_source (

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input  wire         es_entropy_req  , // set when reading from `mentropy`.
output wire [ 1:0]  es_entropy_opst , // return sample status value.
output wire [15:0]  es_entropy_data , // return sample randomness.
input  wire         es_noise_test   , // Are we in noise test mode?
input  wire         es_noise_wr     , // Write to `mnoise` CSR.
input  wire [31:0]  es_noise_wdata  , // write data for `mnoise`.
output wire [31:0]  es_noise_rdata    // read data from `mnoise`.

);

localparam POLLENTROPY_BIST = 2'b00;
localparam POLLENTROPY_ES16 = 2'b01;

//
// The entropy source.
//  - In this case, a dumb LFSR for bring up and testing.
// ------------------------------------------------------------

// Reset value for the PRNG.
parameter PRNG_RESET_VALUE  = 32'hABCDEF37;

// Disable PRNG updates in noise test mode.
wire update_prng= es_entropy_req && !es_noise_test;

wire n_prng_lsb = prng[31] ~^
                  prng[21] ~^
                  prng[ 1] ~^
                  prng[ 0]  ;

reg  [31:0]   prng ;
wire [31:0] n_prng = {prng[31-1:0], n_prng_lsb};

//
// Process for updating the LFSR.
always @(posedge g_clk) begin
    if(!g_resetn) begin
        prng <= PRNG_RESET_VALUE;
    end else if(update_prng) begin
        prng <= n_prng;
    end
end

//
// Interfacing to the es_ signals
// ------------------------------------------------------------

// Always return a valid sample for now.
assign es_entropy_opst = POLLENTROPY_ES16;
assign es_entropy_data = prng[15:0];

// Ignore the noise interface.
assign es_noise_rdata  = 32'b0;

endmodule
