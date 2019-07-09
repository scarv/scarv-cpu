
//
// module: frv_pipeline_back
//
//  The backend of the instruction execution pipeline. Responsible for
//  gathering instruction operands, dispatching them to execute and
//  writing back their results.
//
module frv_pipeline_back (

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

output wire        cf_req          , // Control flow change request
output wire [XL:0] cf_target       , // Control flow change target
input  wire        cf_ack          , // Control flow change acknowledge.

output wire        dmem_cen        , // Chip enable
output wire        dmem_wen        , // Write enable
input  wire        dmem_error      , // Error
input  wire        dmem_stall      , // Memory stall
output wire [3:0]  dmem_strb       , // Write strobe
output wire [31:0] dmem_addr       , // Read/Write address
input  wire [31:0] dmem_rdata      , // Read data
output wire [31:0] dmem_wdata        // Write data

);

// Common core parameters and constants
`include "frv_common.vh"

// -------------------------------------------------------------------------

//
// TEMPORARY assignments for bring-up
assign cf_req       = 1'b0;
assign cf_target    = {XLEN{1'b0}};

assign dmem_cen     = 1'b0;
assign dmem_wen     = 1'b0;
assign dmem_addr    = 32'b0;
assign dmem_strb    =  4'b0;
assign dmem_wdata   = 32'b0;

//
// Inter-stage wiring
// -------------------------------------------------------------------------

wire        flush_dispatch  ; // Flush dispatch pipeline stage.
wire        flush_execute   ; // Flush dispatch pipeline stage.
wire        flush_writeback ; // Flush dispatch pipeline stage.

wire [ 4:0] s4_rd           ; // Writeback stage destination reg.
wire        s4_load         ; // Writeback stage has load in it.
wire        s4_csr          ; // Writeback stage has CSR op in it.

wire        gpr_wen         ; // GPR write enable.
wire [ 4:0] gpr_rd          ; // GPR destination register.
wire [XL:0] gpr_wdata       ; // GPR write data.

wire [ 4:0] s3_rd           ; // Destination register address
wire [XL:0] s3_opr_a        ; // Operand A
wire [XL:0] s3_opr_b        ; // Operand B
wire [XL:0] s3_opr_c        ; // Operand C
wire [31:0] s3_pc           ; // Program counter
wire [ 4:0] s3_uop          ; // Micro-op code
wire [ 4:0] s3_fu           ; // Functional Unit
wire        s3_trap         ; // Raise a trap?
wire [ 1:0] s3_size         ; // Size of the instruction.
wire [31:0] s3_instr        ; // The instruction word
wire        s3_p_busy       ; // Can this stage accept new inputs?
wire        s3_p_valid      ; // Is this input valid?

//
// Sub-module instances.
// -------------------------------------------------------------------------

//
// instance: frv_pipeline_dispatch
//
//  Part of the backend, responsible for clearing pipeline bubbles, RAW
//  hazards and gathering operands ready for execution.
//
frv_pipeline_dispatch i_pipeline_dispatch (
.g_clk           (g_clk           ), // global clock
.g_resetn        (g_resetn        ), // synchronous reset
.s2_p_busy       (s2_p_busy       ), // Can this stage accept new inputs?
.s2_p_valid      (s2_p_valid      ), // Is this input valid?
.s2_rd           (s2_rd           ), // Destination register address
.s2_rs1          (s2_rs1          ), // Source register address 1
.s2_rs2          (s2_rs2          ), // Source register address 2
.s2_imm          (s2_imm          ), // Decoded immediate
.s2_pc           (s2_pc           ), // Program counter
.s2_uop          (s2_uop          ), // Micro-op code
.s2_fu           (s2_fu           ), // Functional Unit
.s2_trap         (s2_trap         ), // Raise a trap?
.s2_size         (s2_size         ), // Size of the instruction.
.s2_instr        (s2_instr        ), // The instruction word
.flush           (flush_dispatch  ), // Flush this pipeline stage.
.s4_rd           (s4_rd           ), // Writeback stage destination reg.
.s4_load         (s4_load         ), // Writeback stage has load in it.
.s4_csr          (s4_csr          ), // Writeback stage has CSR op in it.
.gpr_wen         (gpr_wen         ), // GPR write enable.
.gpr_rd          (gpr_rd          ), // GPR destination register.
.gpr_wdata       (gpr_wdata       ), // GPR write data.
.s3_rd           (s3_rd           ), // Destination register address
.s3_opr_a        (s3_opr_a        ), // Operand A
.s3_opr_b        (s3_opr_b        ), // Operand B
.s3_opr_c        (s3_opr_c        ), // Operand C
.s3_pc           (s3_pc           ), // Program counter
.s3_uop          (s3_uop          ), // Micro-op code
.s3_fu           (s3_fu           ), // Functional Unit
.s3_trap         (s3_trap         ), // Raise a trap?
.s3_size         (s3_size         ), // Size of the instruction.
.s3_instr        (s3_instr        ), // The instruction word
.s3_p_busy       (s3_p_busy       ), // Can this stage accept new inputs?
.s3_p_valid      (s3_p_valid      )  // Is this input valid?
);

endmodule

