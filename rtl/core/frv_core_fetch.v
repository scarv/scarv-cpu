

//
// module: frv_core_fetch
//
//  Fetch stage of the CPU, responsible for delivering instructions to
//  the decoder in a timely fashion.
//
module frv_core_fetch(

input  wire             g_clk       , // global clock
input  wire             g_resetn    , // synchronous reset

input  wire             cf_req      , // Control flow change request
input  wire [XLEN-1:0]  cf_target   , // Control flow change destination
output wire             cf_ack      , // Control flow change acknolwedge

output wire             imem_cen    , // Chip enable
output wire             imem_wen    , // Write enable
input  wire             imem_error  , // Error
input  wire             imem_stall  , // Memory stall
output wire [    3 :0]  imem_strb   , // Write strobe
output wire [    31:0]  imem_addr   , // Read/Write address
input  wire [    31:0]  imem_rdata  , // Read data
output wire [    31:0]  imem_wdata  , // Write data

input  wire [ RLEN-1:0] p_data      , // Data previously sent to decode

output wire [ RLEN-1:0] o_data      , // Output data to pipeline register.
output wire             o_valid     , // Is fetch stage output valid? 
input  wire             i_ready       // Is the decode stage ready?

);

// Width of the fetch->decode pipeline register.
parameter RLEN             = 33;

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Common core parameters and constants
`include "frv_common.vh"

//
// Pipeline events
// -------------------------------------------------------------------------

assign o_valid = a_recv_word;

assign o_data  = {imem_error, n_decode_data};

wire   a_pipe_progress = i_ready && o_valid;

//
// Control flow acknolwedgement
// -------------------------------------------------------------------------

// Acknowledge a control flow change on the boundary of a memory request,
// or if no request is currently active.
assign  cf_ack      = !imem_cen || a_recv_word;

// Control flow change occuring this cycle.
wire    a_cf_change = cf_req && cf_ack;

//
// Constant assignments
// -------------------------------------------------------------------------

// No write functionality used by instruction memory bus.
assign imem_wen     =  1'b0;
assign imem_strb    =  4'b0;
assign imem_wdata   = 32'b0;

//
// Fetch address control
// -------------------------------------------------------------------------

reg  [31:0] fetch_addr;

wire [31:0] fetch_addr_4 = fetch_addr + 4;

wire [31:0] n_fetch_addr = cf_req ? cf_target  : fetch_addr_4;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        fetch_addr <= FRV_PC_RESET_VALUE;
    end else if(a_cf_change) begin
        fetch_addr <= cf_target;
    end else if(a_pipe_progress) begin
        fetch_addr <= n_fetch_addr;
    end
end

//
// Memory Bus control
// -------------------------------------------------------------------------

wire    a_recv_word     = imem_cen     && !imem_stall;
wire    a_recv_error    = a_recv_word  &&  imem_error;

wire    a_recv_32       = a_recv_word  && imem_rdata[1:0] == 2'b11;
wire    a_recv_16       = a_recv_word  && imem_rdata[1:0] != 2'b11;

assign  imem_addr       = fetch_addr;

// Enable fetching iff the decode stage is ready to accept a new word.
assign  imem_cen        = i_ready;

//
// 16-bit buffer control
// -------------------------------------------------------------------------

// Is the current instruction stream halfword aligned?
reg         misaligned  ;

wire [31:0] prev_data   = p_data[XLEN-1:0];

wire [31:0] n_decode_data = 
    misaligned && !n_misaligned ? {aux_buf,prev_data[31:16] }    :
    misaligned &&  n_misaligned ? {imem_rdata[15:0], aux_buf}    :
                                  {imem_rdata               }    ;

reg  [15:0] aux_buf     ;
wire [15:0] n_aux_buf   = imem_rdata[31:16];
wire        load_aux_buf= n_misaligned;

wire n_misaligned = a_cf_change && cf_target[1] ||
                    misaligned  && a_recv_32    ||
                    !misaligned && a_recv_16     ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        aux_buf <= 16'b0;
    end else if(load_aux_buf) begin
        aux_buf <= n_aux_buf;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        misaligned <= FRV_PC_RESET_VALUE[1];
    end else if(a_pipe_progress) begin
        misaligned <= n_misaligned;
    end
end

endmodule
