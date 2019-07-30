
//
// module: frv_lsu
//
//  Load store unit. Responsible for all data accesses.
//
module frv_lsu (

input  wire        g_clk       , // Global clock
input  wire        g_resetn    , // Global reset.

input  wire        lsu_valid   , // Inputs are valid.
output wire        lsu_a_error , // Address error.
output wire        lsu_ready   , // Outputs are valid / instruction complete.
output wire        lsu_mmio    , // Is this an MMIO access?

input  wire        pipe_prog   , // Pipeline is progressing this cycle.

input  wire [XL:0] lsu_addr    , // Memory address to access.
input  wire [XL:0] lsu_wdata   , // Data to write to memory.
input  wire        lsu_load    , // Load instruction.
input  wire        lsu_store   , // Store instruction.
input  wire        lsu_byte    , // Byte operation width.
input  wire        lsu_half    , // Halfword operation width.
input  wire        lsu_word    , // Word operation width.
input  wire        lsu_signed  , // Sign extend loaded data?

input  wire        hold_lsu_req, // Don't make LSU requests yet.

output wire        mmio_en     , // MMIO enable
output wire        mmio_wen    , // MMIO write enable
output wire [31:0] mmio_addr   , // MMIO address
output wire [31:0] mmio_wdata  , // MMIO write data

output wire        dmem_req    , // Start memory request
output wire        dmem_wen    , // Write enable
output wire [3:0]  dmem_strb   , // Write strobe
output wire [XL:0] dmem_wdata  , // Write data
output wire [XL:0] dmem_addr   , // Read/Write address
input  wire        dmem_gnt      // request accepted

);

// Base address of the memory mapped IO region.
parameter   MMIO_BASE_ADDR        = 32'h0000_1000;
parameter   MMIO_BASE_MASK        = 32'hFFFF_F000;

// Common core parameters and constants
`include "frv_common.vh"

//
// MMIO Handling
// -------------------------------------------------------------------------

assign      lsu_mmio   = lsu_valid && 
                         (lsu_addr & MMIO_BASE_MASK) == MMIO_BASE_ADDR;

reg         mmio_done;

wire        n_mmio_done= (mmio_done || mmio_en) && !pipe_prog;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mmio_done <= 1'b0;
    end else begin
        mmio_done <= n_mmio_done;
    end
end

assign      mmio_en    = lsu_mmio && !mmio_done && !hold_lsu_req;
assign      mmio_addr  = lsu_addr   ;
assign      mmio_wen   = lsu_store  ;
assign      mmio_wdata = lsu_wdata  ;

//
// Instruction done tracking
// -------------------------------------------------------------------------

wire dmem_txn_done = !lsu_mmio && dmem_req && dmem_gnt  ||
                      lsu_mmio && mmio_en               ;


reg  lsu_finished;

wire n_lsu_finished = 
    (lsu_finished || ((lsu_valid && dmem_txn_done) || lsu_a_error)) &&
    !pipe_prog;

assign lsu_ready    = dmem_txn_done || lsu_finished;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        lsu_finished <= 1'b0;
    end else begin
        lsu_finished <= n_lsu_finished;
    end
end


// Address error?
assign lsu_a_error = lsu_half &&  lsu_addr[  0] ||
                     lsu_word && |lsu_addr[1:0]  ;

//
// Memory bus assignments
// -------------------------------------------------------------------------

assign dmem_req     = lsu_valid && !lsu_finished && !lsu_a_error &&
                      !hold_lsu_req && !lsu_mmio;
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
