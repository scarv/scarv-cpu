
//
// module: frv_rng_if
//
//  Handles interfacing with the external random number generator.
//
module frv_rngif (

input              g_clk            , // global clock
input              g_resetn         , // synchronous reset

input  wire        flush            , // Flush any internal resources.
input  wire        pipeline_progress, // Pipeline is progressing this cycle.

input  wire        valid            , // Inputs valid
input  wire [XL:0] rs1              , // Input source register 1.

output wire        rng_req_valid    , // Signal a new request to the RNG
output wire [ 2:0] rng_req_op       , // Operation to perform on the RNG
output wire [31:0] rng_req_data     , // Suplementary seed/init data
input  wire        rng_req_ready    , // RNG accepts request

input  wire        rng_rsp_valid    , // RNG response data valid
input  wire [ 2:0] rng_rsp_status   , // RNG status
input  wire [31:0] rng_rsp_data     , // RNG response / sample data.
output wire        rng_rsp_ready    , // CPU accepts response.

input  wire        uop_test         , // Test the RNG status
input  wire        uop_seed         , // Seed the RNG with new entropy
input  wire        uop_samp         , // Sample from the RNG

output wire [XL:0] result           , // Result to write back
output wire        ready              // Result ready.

);

`include "frv_common.vh"

//
// Request channel
// ------------------------------------------------------------

assign rng_req_op       = {
    uop_test, uop_samp, uop_seed
};

assign rng_req_data     = rs1;


reg    req_done;
wire   n_req_done       = (req_done || (rng_req_valid && rng_req_ready)) &&
                         !(flush || pipeline_progress);

assign rng_req_valid    = valid && !req_done;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        req_done <= 1'b0;
    end else begin
        req_done <= n_req_done;
    end
end

//
// Response channel
// ------------------------------------------------------------

// Only accept response transactions when the pipeline is ready to progress.
assign ready            = (valid && rng_rsp_valid) || req_done;

assign rng_rsp_ready    = pipeline_progress;

wire   status_healthy   = rng_rsp_status == RNG_IF_INIT_HEALTHY;

assign result           = uop_samp ? rng_rsp_data               :
                          uop_test ? {31'b0, status_healthy}    :
                                     32'b0                      ;

endmodule
