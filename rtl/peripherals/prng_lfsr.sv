
//
// module: prng_lfsr
//
//  A very basic pseudo-random number generator which can connect to the
//  scarv-cpu via it's randomness interface.
//
module prng_lfsr (

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input  wire         rng_req_valid   , // Signal a new request to the RNG
input  wire [ 2:0]  rng_req_op      , // Operation to perform on the RNG
input  wire [31:0]  rng_req_data    , // Suplementary seed/init data
output wire         rng_req_ready   , // RNG accepts request

output wire         rng_rsp_valid   , // RNG response data valid
output wire [ 2:0]  rng_rsp_status  , // RNG status
output wire [31:0]  rng_rsp_data    , // RNG response / sample data.
input  wire         rng_rsp_ready     // CPU accepts response.

);

// Reset value for the PRNG.
parameter PRNG_RESET_VALUE  = 32'hABCDEF37;

parameter OP_SEED = 3'b001;
parameter OP_SAMP = 3'b010;
parameter OP_TEST = 3'b100;

parameter STATUS_NO_INIT    = 3'b000;
parameter STATUS_UNHEALTHY  = 3'b100;
parameter STATUS_HEALTHY    = 3'b101;

//
// Response handling

assign rng_req_ready = 1'b1;

assign rng_rsp_valid = rng_req_valid;

assign rng_rsp_data  = prng;

// Always report healthy for now.
assign rng_rsp_status = STATUS_HEALTHY;

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
    end else if(rng_req_valid && rng_req_op == OP_SEED) begin
        prng <= rng_req_data;
    end else if(rng_req_valid) begin
        prng <= n_prng;
    end
end

endmodule
