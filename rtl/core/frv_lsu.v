
//
// module: frv_lsu
//
//  Load store unit. Responsible for all data accesses.
//
module frv_lsu (

input  wire        g_clk       , // Global clock
input  wire        g_resetn    , // Global reset.

input  wire        lsu_valid   , // Inputs are valid.
output wire [XL:0] lsu_rdata   , // Data read from memory.
output wire        lsu_a_error , // Address error.
output wire        lsu_b_error , // Bus error.
output wire        lsu_ready   , // Outputs are valid / instruction complete.

input  wire        pipe_prog   , // Pipeline is progressing this cycle.

input  wire [XL:0] lsu_addr    , // Memory address to access.
input  wire [XL:0] lsu_wdata   , // Data to write to memory.
input  wire        lsu_load    , // Load instruction.
input  wire        lsu_store   , // Store instruction.
input  wire        lsu_byte    , // Byte operation width.
input  wire        lsu_half    , // Halfword operation width.
input  wire        lsu_word    , // Word operation width.
input  wire        lsu_signed  , // Sign extend loaded data?

output wire        dmem_req    , // Start memory request
output wire        dmem_wen    , // Write enable
output wire [3:0]  dmem_strb   , // Write strobe
output wire [XL:0] dmem_wdata  , // Write data
output wire [XL:0] dmem_addr   , // Read/Write address
input  wire        dmem_gnt    , // request accepted
input  wire        dmem_recv   , // Instruction memory recieve response.
output wire        dmem_ack    , // Data memory ack response.
input  wire        dmem_error  , // Error
input  wire [XL:0] dmem_rdata    // Read data

);

// Common core parameters and constants
`include "frv_common.vh"

//
// Instruction done tracking
// -------------------------------------------------------------------------

assign dmem_ack    = 1'b1;

wire dmem_txn_done = 1'b1; // dmem_cen      && !dmem_stall;
wire dmem_txn_err  = dmem_txn_done &&  dmem_error;

reg  lsu_finished;

wire n_lsu_finished = 
    (lsu_finished || (lsu_valid && dmem_txn_done)) &&
    !pipe_prog;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        lsu_finished <= 1'b0;
    end else begin
        lsu_finished <= n_lsu_finished;
    end
end

//
// EXU interface
// -------------------------------------------------------------------------

assign lsu_ready   = dmem_txn_done || lsu_finished;

wire [ 7: 0] rdata_b0 =
    {8{lsu_byte && lsu_addr[1:0] == 2'b00}} & dmem_rdata[ 7: 0] |
    {8{lsu_half && lsu_addr[  1] == 1'b0 }} & dmem_rdata[ 7: 0] |
    {8{lsu_word                          }} & dmem_rdata[ 7: 0] |
    {8{lsu_byte && lsu_addr[1:0] == 2'b01}} & dmem_rdata[15: 8] |
    {8{lsu_byte && lsu_addr[1:0] == 2'b10}} & dmem_rdata[23:16] |
    {8{lsu_half && lsu_addr[  1] == 1'b1 }} & dmem_rdata[23:16] |
    {8{lsu_byte && lsu_addr[1:0] == 2'b11}} & dmem_rdata[31:24] ;

wire [ 7: 0] rdata_b1 =
    {8{lsu_byte && lsu_signed            }} & {8{rdata_b0[7] }} |
    {8{lsu_half && lsu_addr[  1] == 1'b0 }} & dmem_rdata[15: 8] |
    {8{lsu_word                          }} & dmem_rdata[15: 8] |
    {8{lsu_half && lsu_addr[  1] == 1'b1 }} & dmem_rdata[31:24] ;

wire [15: 0] rdata_h1 =
    {16{lsu_byte && lsu_signed           }} & {16{rdata_b1[7]  }}  |
    {16{lsu_half && lsu_signed           }} & {16{rdata_b1[7]  }}  |
    {16{lsu_word                         }} & dmem_rdata[31:16]    ;

//                  31....16,15.....8,7......0
assign lsu_rdata = {rdata_h1,rdata_b1,rdata_b0};

// Address error?
assign lsu_a_error = lsu_half &&  lsu_addr[  0] ||
                     lsu_word && |lsu_addr[1:0]  ;

// Bus error?
assign lsu_b_error = dmem_txn_err;


//
// Memory bus assignments
// -------------------------------------------------------------------------

assign dmem_req     = lsu_valid && !lsu_finished && !lsu_a_error;
assign dmem_wen     = lsu_store ;
assign dmem_addr    = lsu_addr  & 32'hFFFF_FFFC;

assign dmem_wdata   = 
    {32{lsu_byte && lsu_addr[1:0]==2'b00}} & {24'b0, lsu_wdata[ 7:0]       } |
    {32{lsu_byte && lsu_addr[1:0]==2'b01}} & {16'b0, lsu_wdata[ 7:0],  8'b0} |
    {32{lsu_byte && lsu_addr[1:0]==2'b10}} & { 8'b0, lsu_wdata[ 7:0], 16'b0} |
    {32{lsu_byte && lsu_addr[1:0]==2'b11}} & {       lsu_wdata[ 7:0], 24'b0} |
    {32{lsu_half && lsu_addr[  1]==1'b1 }} & {       lsu_wdata[15:0], 16'b0} |
    {32{lsu_half && lsu_addr[  1]==1'b0 }} & {16'b0, lsu_wdata[15:0]       } |
    {32{lsu_word                        }} & {       lsu_wdata             } ;

assign dmem_strb[0] = lsu_byte &&  lsu_addr[1:0] == 2'b00 ||
                      lsu_half && !lsu_addr[  1]          ||
                      lsu_word                             ;

assign dmem_strb[1] = lsu_byte &&  lsu_addr[1:0] == 2'b01 ||
                      lsu_half && !lsu_addr[  1]          ||
                      lsu_word                             ;

assign dmem_strb[2] = lsu_byte &&  lsu_addr[1:0] == 2'b10 ||
                      lsu_half &&  lsu_addr[  1]          ||
                      lsu_word                             ;

assign dmem_strb[3] = lsu_byte &&  lsu_addr[1:0] == 2'b11 ||
                      lsu_half &&  lsu_addr[  1]          ||
                      lsu_word                             ;

endmodule
