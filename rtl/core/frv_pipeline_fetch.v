
//
// module: frv_pipeline_fetch
//
//  Fetch pipeline stage.
//
module frv_pipeline_fetch (

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input  wire         cf_req          , // Control flow change
input  wire [XL:0]  cf_target       , // Control flow change target
output wire         cf_ack          , // Acknowledge control flow change

output reg          imem_req        , // Start memory request
output wire         imem_wen        , // Write enable
output wire [3:0]   imem_strb       , // Write strobe
output wire [XL:0]  imem_wdata      , // Write data
output reg  [XL:0]  imem_addr       , // Read/Write address
input  wire         imem_gnt        , // request accepted
output wire         imem_ack        , // Instruction memory ack response.
input  wire         imem_recv       , // Instruction memory recieve response.
input  wire         imem_error      , // Error
input  wire [XL:0]  imem_rdata      , // Read data

input  wire         s0_flush        , // Flush stage
input  wire         s1_busy        , // Stall stage

output wire         s1_valid        , // Stage ready to progress
output wire [XL:0]  s1_data         , // Data to be decoded.
output wire         s1_error 

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Common core parameters and constants
`include "frv_common.vh"

//
// Pipeline progression
// --------------------------------------------------------------

// Stage can progress if buffer has enough data in it for an instruction.
assign s1_valid = buf_valid;

// TODO: track when to ignore requests more inteligently.
assign cf_ack   = (!imem_req || imem_req && imem_gnt);

//
// Request buffer
// --------------------------------------------------------------

wire f_ready;
wire f_4byte;
wire f_2byte;

wire buf_out_2 ; // Buffer has 2 byte instruction.
wire buf_out_4 ; // Buffer has 4 byte instruction.
wire buf_valid ; // D output data is valid
wire buf_ready = s1_valid && !s1_busy; // Eat 2/4 bytes

//
// Memory bus requests
// --------------------------------------------------------------

reg  [1:0] ignore_rsps       ;
wire [1:0] n_ignore_rsps     ;

assign     n_ignore_rsps    = ignore_rsps - rsp_recv  ;

wire        drop_response   = |ignore_rsps;

reg  [1:0]   reqs_outstanding;
wire [1:0] n_reqs_outstanding = reqs_outstanding +
                                (imem_req && imem_gnt) -
                                rsp_recv;

wire cf_change          = cf_req && cf_ack;

wire progress_imem_addr = imem_req && imem_gnt;

wire [XL:0] n_imem_addr = imem_addr + 4;

wire        n_imem_req  = (f_ready || cf_change) && reqs_outstanding<3;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_addr <= FRV_PC_RESET_VALUE;
    end else if(cf_change) begin
        imem_addr <= cf_target;
    end else if(progress_imem_addr) begin
        imem_addr <= n_imem_addr;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_req    <= 1'b0;
    end else begin
        imem_req    <= n_imem_req;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        reqs_outstanding <= 2'b0;
    end else begin
        reqs_outstanding <= n_reqs_outstanding;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        ignore_rsps <= 2'b0;
    end else if(cf_change) begin
        ignore_rsps <= n_reqs_outstanding;
    end else if(|ignore_rsps) begin
        ignore_rsps <= n_ignore_rsps;
    end
end

//
// Misalignment tracking
// --------------------------------------------------------------

wire fetch_misaligned = 1'b0; // TODO

//
// Memory bus responses
// --------------------------------------------------------------

wire   rsp_recv= imem_recv && imem_ack;

assign f_4byte = rsp_recv && !fetch_misaligned && !drop_response;
assign f_2byte = rsp_recv &&  fetch_misaligned && !drop_response;

assign imem_ack= f_ready;

//
// Constant assignments for un-used signals.
// --------------------------------------------------------------
assign imem_wdata = 0;
assign imem_strb  = 0;
assign imem_wen   = 0;

// ---------------------- Submodules -------------------------


frv_core_fetch_buffer i_core_fetch_buffer (
.g_clk    (g_clk        ), // Global clock
.g_resetn (g_resetn     ), // Global negative level triggered reset
.flush    (s0_flush     ),
.f_ready  (f_ready      ),
.f_4byte  (f_4byte      ), // Input data valid
.f_2byte  (f_2byte      ), // Load only the 2 MS bytes
.f_err    (imem_error   ), // Input error
.f_in     (imem_rdata   ), // Input data
.buf_out  (s1_data      ), // Output data
.buf_out_2(buf_out_2    ), // Output data
.buf_out_4(buf_out_4    ), // Output data
.buf_err  (s1_error     ), // Output error bit
.buf_valid(buf_valid    ), // D output data is valid
.buf_ready(buf_ready    )  // Eat 2/4 bytes
);


endmodule
