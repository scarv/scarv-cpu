
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

// Maximum outstanding memory requests
parameter FRV_MAX_REQS_OUTSTANDING = 1;

// Common core parameters and constants
`include "frv_common.vh"

//
// Pipeline progression
// --------------------------------------------------------------

// Stage can progress if buffer has enough data in it for an instruction.
assign s1_valid = buf_valid;

// TODO: track when to ignore requests more inteligently.
assign cf_ack   = (!imem_req) || (imem_req && imem_gnt);

//
// Request buffer interface signals.
// --------------------------------------------------------------

wire f_ready;   // Buffer ready to recieve input data.
wire f_4byte;   // Buffer should store 4 bytes of input.
wire f_2byte;   // Buffer should store 2 bytes of input.

wire       buf_16;
wire       buf_32;
wire [2:0] buf_depth; // Current buffer depth.

wire buf_out_2 ; // Buffer has entire valid 2 byte instruction.
wire buf_out_4 ; // Buffer has entire valid 4 byte instruction.
wire buf_valid ; // D output data is valid
wire buf_ready = s1_valid && !s1_busy; // Eat 2/4 bytes

//
// Memory bus requests
// --------------------------------------------------------------

// Counter to store the number of future memory responses to be ignored.
reg  [2:0] ignore_rsps       ;
wire [2:0] n_ignore_rsps     ;

assign     n_ignore_rsps    = ignore_rsps - {2'b00, rsp_recv};

// If we get a memory response while ignoring them, drop the response so
// it doesn't enter the fetch buffer.
wire        drop_response   = |ignore_rsps;

// The number of outstanding memory requests for which we haven't yet
// recieved a response. This counter is updated whether or not the
// response is dropped or not.
reg  [2:0]   reqs_outstanding;
wire [2:0]   reqs_outstanding_add = {2'b0,(imem_req && imem_gnt)};
wire [2:0]   reqs_outstanding_sub = {2'b0,(rsp_recv            )};

wire [2:0] n_reqs_outstanding = reqs_outstanding     +
                                reqs_outstanding_add -
                                reqs_outstanding_sub ;

wire cf_change          = cf_req && cf_ack;

// Update the memory fetch address each time we get a response.
wire progress_imem_addr = imem_req && imem_gnt;

wire [XL:0] n_imem_addr = imem_addr + 4;

wire incomplete_instr = buf_32 && buf_depth == 1;

// Don't start a memory fetch request if there are already a bunch of
// outstanding, unrecieved responses.
wire allow_new_mem_req  =
      reqs_outstanding <  FRV_MAX_REQS_OUTSTANDING ||
    n_reqs_outstanding == 0                        ||
   (  reqs_outstanding == FRV_MAX_REQS_OUTSTANDING &&
    n_reqs_outstanding == FRV_MAX_REQS_OUTSTANDING );

wire new_mem_req        = f_ready || cf_change;

wire        n_imem_req  =
    (new_mem_req && allow_new_mem_req || incomplete_instr) ||
    (imem_req && !imem_gnt);

//
// Update the fetch address in terms of control flow changes and natural
// progression to the next word.
always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_addr <= FRV_PC_RESET_VALUE;
    end else if(cf_change) begin
        imem_addr <= {cf_target[31:2],2'b00};
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
        reqs_outstanding <= 3'b0;
    end else begin
        reqs_outstanding <= n_reqs_outstanding;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        ignore_rsps <= 3'b0;
    end else if(cf_change) begin
        ignore_rsps <= n_reqs_outstanding;
    end else if(|ignore_rsps) begin
        ignore_rsps <= n_ignore_rsps;
    end
end

//
// Misalignment tracking
// --------------------------------------------------------------

//
// The fetch address only becomes misaligned iff we jump onto a
// halfword aligned instruction. The misalignment flag signals we
// should only store the "upper" halfword of the response.
reg  fetch_misaligned;
wire n_fetch_misaligned =
    cf_change ? cf_target[1] : fetch_misaligned && !f_2byte;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        fetch_misaligned <= 1'b0;
    end else begin
        fetch_misaligned <= n_fetch_misaligned;
    end
end

//
// Memory bus responses
// --------------------------------------------------------------

wire   rsp_recv= imem_recv && imem_ack;

// Store the entire 4-byte response data
assign f_4byte = rsp_recv && !fetch_misaligned && !drop_response;

// Store the upper halfword of the response data.
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
.buf_depth(buf_depth    ), // Number of halfwords in buffer.
.buf_out  (s1_data      ), // Output data
.buf_16   (buf_16       ), // 16 bit instruction next to be output
.buf_32   (buf_32       ), // 32 bit instruction next to be output
.buf_out_2(buf_out_2    ), // Output data
.buf_out_4(buf_out_4    ), // Output data
.buf_err  (s1_error     ), // Output error bit
.buf_valid(buf_valid    ), // D output data is valid
.buf_ready(buf_ready    )  // Eat 2/4 bytes
);


endmodule
