
//
// module: frv_pipeline_dispatch
//
//  Part of the backend, responsible for clearing pipeline bubbles, RAW
//  hazards and gathering operands ready for execution.
//
module frv_pipeline_dispatch (

input              g_clk           , // global clock
input              g_resetn        , // synchronous reset

output wire        s2_p_busy       , // Can this stage accept new inputs?
input  wire        s2_p_valid      , // Is this input valid?
input  wire [ 4:0] s2_rd           , // Destination register address
input  wire [ 4:0] s2_rs1          , // Source register address 1
input  wire [ 4:0] s2_rs2          , // Source register address 2
input  wire [31:0] s2_imm          , // Decoded immediate
input  wire [31:0] s2_pc           , // Program counter
input  wire [ 4:0] s2_uop          , // Micro-op code
input  wire [ 4:0] s2_fu           , // Functional Unit
input  wire        s2_trap         , // Raise a trap?
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word

input  wire        flush           , // Flush this pipeline stage.
input  wire [ 4:0] s4_rd           , // Writeback stage destination reg.
input  wire        s4_load         , // Writeback stage has load in it.
input  wire        s4_csr          , // Writeback stage has CSR op in it.

input  wire        gpr_wen         , // GPR write enable.
input  wire [ 4:0] gpr_rd          , // GPR destination register.
input  wire [XL:0] gpr_wdata       , // GPR write data.

output wire [ 4:0] s3_rd           , // Destination register address
output wire [XL:0] s3_opr_a        , // Operand A
output wire [XL:0] s3_opr_b        , // Operand B
output wire [XL:0] s3_opr_c        , // Operand C
output wire [31:0] s3_pc           , // Program counter
output wire [ 4:0] s3_uop          , // Micro-op code
output wire [ 4:0] s3_fu           , // Functional Unit
output wire        s3_trap         , // Raise a trap?
output wire [ 1:0] s3_size         , // Size of the instruction.
output wire [31:0] s3_instr        , // The instruction word
input  wire        s3_p_busy       , // Can this stage accept new inputs?
output wire        s3_p_valid        // Is this input valid?

);

// Common core parameters and constants
`include "frv_common.vh"

// -------------------------------------------------------------------------

wire [ 4:0] n_s3_rd      = s2_rd    ; // Destination register address
wire [31:0] n_s3_pc      = s2_pc    ; // Program counter
wire [ 4:0] n_s3_uop     = s2_uop   ; // Micro-op code
wire [ 4:0] n_s3_fu      = s2_fu    ; // Functional Unit
wire [ 1:0] n_s3_size    = s2_size  ; // Size of the instruction.
wire [31:0] n_s3_instr   = s2_instr ; // The instruction word
wire [XL:0] n_s3_opr_a              ; // Operand A
wire [XL:0] n_s3_opr_b              ; // Operand B
wire [XL:0] n_s3_opr_c              ; // Operand C
wire        n_s3_trap               ; // Raise a trap?


endmodule


