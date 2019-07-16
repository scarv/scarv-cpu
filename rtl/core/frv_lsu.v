
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

input  wire [XL:0] lsu_addr    , // Memory address to access.
input  wire [XL:0] lsu_wdata   , // Data to write to memory.
input  wire        lsu_load    , // Load instruction.
input  wire        lsu_store   , // Store instruction.
input  wire        lsu_byte    , // Byte operation width.
input  wire        lsu_half    , // Halfword operation width.
input  wire        lsu_word    , // Word operation width.
input  wire        lsu_signed  , // Sign extend loaded data?

output wire        dmem_cen    , // Chip enable
output wire        dmem_wen    , // Write enable
input  wire        dmem_error  , // Error
input  wire        dmem_stall  , // Memory stall
output wire [3:0]  dmem_strb   , // Write strobe
output wire [31:0] dmem_addr   , // Read/Write address
input  wire [31:0] dmem_rdata  , // Read data
output wire [31:0] dmem_wdata    // Write data

);

// Common core parameters and constants
`include "frv_common.vh"

assign lsu_ready = lsu_valid;
assign lsu_rdata = 0;
assign lsu_a_error = 0;
assign lsu_b_error = 0;

assign dmem_cen     = 0;
assign dmem_wen     = lsu_store ;
assign dmem_strb    = 0;
assign dmem_addr    = lsu_addr  ;
assign dmem_wdata   = lsu_wdata ;

endmodule
