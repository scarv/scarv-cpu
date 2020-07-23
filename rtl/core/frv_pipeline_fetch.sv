
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
`include "frv_common.svh"

//
// Pipeline progression
// --------------------------------------------------------------

// Stage can progress if buffer has enough data in it for an instruction.
assign  s1_valid    = buf_valid;

// When can we accept a control flow change?
assign  cf_ack      = (!imem_req) || (imem_req && imem_gnt);

// New control flow change occuring right now.
wire    e_cf_change = cf_req && cf_ack;

//
// Request buffer interface signals.
// --------------------------------------------------------------

wire f_ready;   // Buffer ready to recieve input data.
wire f_4byte;   // Buffer should store 4 bytes of input.
wire f_2byte;   // Buffer should store 2 bytes of input.

wire       buf_16;
wire       buf_32;
wire [2:0] buf_depth; // Current buffer depth.
wire [2:0] n_buf_depth; // Next buffer depth.

wire buf_out_2 ; // Buffer has entire valid 2 byte instruction.
wire buf_out_4 ; // Buffer has entire valid 4 byte instruction.
wire buf_valid ; // D output data is valid
wire buf_ready = s1_valid && !s1_busy; // Eat 2/4 bytes

//
// Memory Event tracking.
// --------------------------------------------------------------

// New request issued this cycle.
wire        e_new_req           = imem_req && imem_gnt;

// New response recieved this cycle.
reg         e_new_rsp           ;
reg         p_new_rsp           ;

always @(posedge g_clk) if(!g_resetn) begin
    e_new_rsp <= 1'b0;
    p_new_rsp <= 1'b0;
end else begin
    e_new_rsp <= e_new_req;
    p_new_rsp <= e_new_req;
end

//
// Memory bus requests
// --------------------------------------------------------------

// Next natural instruction memory fetch address.
wire [XL:0] n_imem_addr         = imem_addr + 4;

// We only hold half of a 32-bit instruction.
wire        incomplete_instr    = buf_32 && buf_depth == 1;

wire nc_1 = n_buf_depth == 1              ;
wire nc_2 = n_buf_depth <= 3 && !e_new_req;
wire nc_3 = 1'b0;

wire   n_imem_req = nc_1 || nc_2 || nc_3;

//
// Update the fetch address in terms of control flow changes and natural
// progression to the next word.
always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_addr <= FRV_PC_RESET_VALUE;
    end else if(e_cf_change) begin
        imem_addr <= {cf_target[31:2],2'b00};
    end else if(e_new_req) begin
        imem_addr <= n_imem_addr;
    end
end

//
// Update instruction memory fetch request bit.
always @(posedge g_clk) if(!g_resetn) begin
    imem_req    <= 1'b0;
end else if(imem_req && !imem_gnt) begin
    imem_req    <= 1'b1;
end else begin
    imem_req    <= n_imem_req;
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
    e_cf_change ? cf_target[1] : fetch_misaligned && !f_2byte;

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

// When to discard returning fetch data.
wire   n_drop_response    = e_cf_change;

reg      drop_response    ;

always @(posedge g_clk) if(!g_resetn) begin
    drop_response <= 1'b0;
end else begin
    drop_response <= n_drop_response;
end

// Store the entire 4-byte response data
assign f_4byte = e_new_rsp && !fetch_misaligned && !drop_response;

// Store the upper halfword of the response data.
assign f_2byte = e_new_rsp &&  fetch_misaligned && !drop_response;

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
.f_ready  (f_ready      ), // Buffer ready for more input data.
.f_4byte  (f_4byte      ), // Input data valid
.f_2byte  (f_2byte      ), // Load only the 2 MS bytes
.f_err    (imem_error   ), // Input error
.f_in     (imem_rdata   ), // Input data
.buf_depth(buf_depth    ), // Number of halfwords in buffer.
.n_buf_depth(n_buf_depth    ), // Number of halfwords in buffer.
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
