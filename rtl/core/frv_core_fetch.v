

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
input  wire [ XLEN-1:0] cf_target   , // Control flow change destination
output wire             cf_ack      , // Control flow change acknolwedge
              
output reg              imem_cen    , // Chip enable
output wire             imem_wen    , // Write enable
input  wire             imem_error  , // Error
input  wire             imem_stall  , // Memory stall
output wire [     3 :0] imem_strb   , // Write strobe
output wire [     31:0] imem_addr   , // Read/Write address
input  wire [     31:0] imem_rdata  , // Read data
output wire [     31:0] imem_wdata  , // Write data

input  wire [     31:0] s1_data     , // Data previously sent to decode

output wire [     31:0] s0_data     , // Output data to pipeline register.
output wire             s0_error    , // Fetch error occured.
output wire             s0_d_valid  , // Output data is valid
output wire             s0_valid    , // Is fetch stage output valid? 
input  wire             s1_busy       // Is the decode stage busy? 

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Common core parameters and constants
`include "frv_common.vh"

//
// Pipeline events
// -------------------------------------------------------------------------

assign s0_valid = a_recv_word && buf_can_load ||
                 buf_depth >= 1 && prev_2b ||
                 buf_depth >= 2 && prev_4b ;

assign s0_data      = {n_buffer[1], n_buffer[0]};
assign s0_error     = a_recv_error;
assign s0_d_valid   = buf_depth >= 1 || a_recv_word && a_pipe_progress;

wire   a_pipe_progress = !s1_busy && s0_valid;

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
    end else if(a_recv_word) begin
        fetch_addr <= n_fetch_addr;
    end
end

//
// Memory Bus control
// -------------------------------------------------------------------------

wire    a_recv_word     = imem_cen     && !imem_stall && buf_can_load;
wire    a_recv_error    = a_recv_word  &&  imem_error;

wire    a_recv_32       = a_recv_word  && imem_rdata[1:0] == 2'b11;
wire    a_recv_16       = a_recv_word  && imem_rdata[1:0] != 2'b11;

assign  imem_addr       = fetch_addr;

// Enable fetching iff the decode stage is ready to accept a new word.
wire    n_imem_cen      = !s1_busy && g_resetn && 
                          (n_buf_depth <= 2 ||
                           buf_depth == 2 && a_eat_2 ||
                           buf_depth == 3 && a_eat_4 );

always @(posedge g_clk) begin
    if(!g_resetn) begin
        imem_cen <= 1'b0;
    end else begin
        imem_cen <= n_imem_cen;
    end
end

//
// 16-bit buffer control
// -------------------------------------------------------------------------

// Is the current instruction stream halfword aligned?
reg         misaligned  ;
reg  [15:0] aux_buf     ;
reg  [15:0] n_buffer [2:0];
wire [15:0]   buffer [2:0];

assign buffer[0] = s1_data[15: 0];
assign buffer[1] = s1_data[31:16];
assign buffer[2] = aux_buf      ;

wire [31:0] d_prev_data   = {a_eat_4 ? s1_data[31:16] : 16'b0, s1_data[15:0]};
wire        d_prev_valid  = buf_depth >= 1 && s1_data[1:0] != 2'b11 ||
                            buf_depth >= 2 && s1_data[1:0] == 2'b11  ;

wire [31:0] prev_data   = s1_data[XLEN-1:0];
wire        prev_2b     = buf_depth >= 1 && prev_data[1:0] != 2'b11;
wire        prev_4b     = buf_depth >= 2 && prev_data[1:0] == 2'b11;
wire        load_aux_buf= a_pipe_progress;

wire        buf_can_load = (buf_depth <= 1 ||
                           buf_depth <= 2 && (a_eat_2) ||
                                              a_eat_4)  ;

// Are we eating 2 or 4 bytes from the buffer this cycle? 
wire        a_eat_2     = prev_2b;
wire        a_eat_4     = prev_4b;

reg  [ 1:0] buf_depth   ;
wire [ 1:0] n_buf_depth = buf_depth + {a_recv_word,1'b0} - {a_eat_4, a_eat_2};

reg case_1;

always @(*) begin
    n_buffer[0] = buffer[0];
    n_buffer[1] = buffer[1];
    n_buffer[2] = buffer[2];
    case_1 =  0;

    case(buf_depth)
        0 : if(a_recv_word) begin
                {n_buffer[1],n_buffer[0]} = imem_rdata;
            end
        1 : if(a_recv_word) begin
                if(a_eat_2) begin
                    {n_buffer[1],n_buffer[0]} = imem_rdata;
                end else begin
                    {n_buffer[2],n_buffer[1]} = imem_rdata;
                end
            end else begin
                if(a_eat_2) begin
                    n_buffer[0] = n_buffer[1];
                end
            end
        2 : if(a_recv_word) begin
                if(a_eat_2) begin
                    case_1 =1;
                    n_buffer[0] = buffer[1];
                    {n_buffer[2],n_buffer[1]} = imem_rdata;
                end else if(a_eat_4) begin
                    {n_buffer[1],n_buffer[0]} = imem_rdata;
                end
            end else begin
                if(a_eat_2) begin
                    n_buffer[0] = buffer[1];
                end
            end
        3 : if(a_recv_word) begin
                if(a_eat_4) begin
                    n_buffer[0] = buffer[2];
                    {n_buffer[2],n_buffer[1]} = imem_rdata;
                end
            end else begin
                if(a_eat_4) begin
                    n_buffer[0] = buffer[2];
                end else if(a_eat_2) begin
                    {n_buffer[1],n_buffer[0]} = {buffer[2],buffer[1]};
                end
            end
    endcase

end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        buf_depth <= 2'b0;
    end else if(a_cf_change) begin
        buf_depth <= 2'b0;
    end else if(a_pipe_progress) begin
        buf_depth <= n_buf_depth;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        aux_buf <= 16'b0;
    end else if(load_aux_buf) begin
        aux_buf <= n_buffer[2];
    end
end

endmodule
