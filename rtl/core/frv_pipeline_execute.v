
//
// module: frv_pipeline_execute
//
//  Execute stage of the pipeline, responsible for ALU / LSU / Branch compare.
//
module frv_pipeline_execute (

input              g_clk           , // global clock
input              g_resetn        , // synchronous reset

input  wire [ 4:0] s3_rd           , // Destination register address
input  wire [XL:0] s3_opr_a        , // Operand A
input  wire [XL:0] s3_opr_b        , // Operand B
input  wire [XL:0] s3_opr_c        , // Operand C
input  wire [31:0] s3_pc           , // Program counter
input  wire [ 4:0] s3_uop          , // Micro-op code
input  wire [ 4:0] s3_fu           , // Functional Unit
input  wire        s3_trap         , // Raise a trap?
input  wire [ 1:0] s3_size         , // Size of the instruction.
input  wire [31:0] s3_instr        , // The instruction word
output wire        s3_p_busy       , // Can this stage accept new inputs?
input  wire        s3_p_valid      , // Is this input valid?

input  wire        flush           , // Flush this pipeline stage.

input  wire [ 4:0] s4_rd           , // Destination register address
input  wire [XL:0] s4_opr_a        , // Operand A
input  wire [XL:0] s4_opr_b        , // Operand B
input  wire [31:0] s4_pc           , // Program counter
input  wire [ 4:0] s4_uop          , // Micro-op code
input  wire [ 4:0] s4_fu           , // Functional Unit
input  wire        s4_trap         , // Raise a trap?
input  wire [ 1:0] s4_size         , // Size of the instruction.
input  wire [31:0] s4_instr        , // The instruction word
input  wire        s4_p_busy       , // Can this stage accept new inputs?
output wire        s4_p_valid      , // Is this input valid?

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

//
// Operation Decoding
// -------------------------------------------------------------------------

wire fu_alu = s3_fu[P_FU_ALU] && s3_p_valid;
wire fu_mul = s3_fu[P_FU_MUL] && s3_p_valid;
wire fu_lsu = s3_fu[P_FU_LSU] && s3_p_valid;
wire fu_cfu = s3_fu[P_FU_CFU] && s3_p_valid;
wire fu_csr = s3_fu[P_FU_CSR] && s3_p_valid;

//
// Functional Unit Interfacing: ALU
// -------------------------------------------------------------------------

wire        alu_valid       = fu_alu    ; // Stall this stage
wire        alu_flush       = flush     ; // flush the stage
wire        alu_ready                   ; // stage ready to progress

wire        alu_op_add      = fu_alu && s3_uop == ALU_ADD;
wire        alu_op_sub      = fu_alu && s3_uop == ALU_SUB;
wire        alu_op_xor      = fu_alu && s3_uop == ALU_XOR;
wire        alu_op_or       = fu_alu && s3_uop == ALU_OR ;
wire        alu_op_and      = fu_alu && s3_uop == ALU_AND;

wire        alu_op_shf      = fu_alu && (s3_uop == ALU_SLL ||
                                         s3_uop == ALU_SRL ||
                                         s3_uop == ALU_SRA );

wire        alu_op_shf_left = fu_alu && s3_uop == ALU_SLL;
wire        alu_op_shf_arith= fu_alu && s3_uop == ALU_SRA;

wire        alu_op_cmp      = fu_alu && (s3_uop == ALU_SLT  ||
                                         s3_uop == ALU_SLTU );

wire        alu_op_unsigned = fu_alu && (s3_uop == ALU_SLTU);

wire        alu_lt                      ; // Is LHS < RHS?
wire        alu_eq                      ; // Is LHS = RHS?
wire [XL:0] alu_add_result              ; // Result of adding LHS,RHS.

wire [XL:0] alu_lhs         = s3_opr_a  ; // left hand operand
wire [XL:0] alu_rhs         = s4_opr_b  ; // right hand operand
wire [XL:0] alu_result                  ; // result of the ALU operation

//
// Functional Unit Interfacing: LSU
// -------------------------------------------------------------------------

wire        lsu_valid  = fu_lsu         ; // Inputs are valid.
wire [XL:0] lsu_rdata                   ; // Data read from memory.
wire        lsu_a_error                 ; // Address error.
wire        lsu_b_error                 ; // Bus error.
wire        lsu_ready                   ; // Load/Store instruction complete.

wire [XL:0] lsu_addr   = alu_add_result ; // Memory address to access.
wire [XL:0] lsu_wdata  = s3_opr_c       ; // Data to write to memory.
wire        lsu_load   = s3_uop[LSU_LOAD]    ;
wire        lsu_store  = s3_uop[LSU_STORE]   ;
wire        lsu_byte   = s3_uop[2:1] == LSU_BYTE;
wire        lsu_half   = s3_uop[2:1] == LSU_HALF;
wire        lsu_word   = s3_uop[2:1] == LSU_WORD;
wire        lsu_signed = s3_uop[LSU_SIGNED]  ;

//
// Functional Unit Interfacing: CFU
// -------------------------------------------------------------------------

wire        cfu_valid  = fu_cfu         ; // Inputs are valid.
wire        cfu_ready                   ; // Instruction complete.

//
// Functional Unit Interfacing: MUL/DIV
// -------------------------------------------------------------------------

wire        mul_valid  = fu_mul         ; // Inputs are valid.
wire        mul_ready                   ; // Instruction complete.

//
// Functional Unit Interfacing: CSR
// -------------------------------------------------------------------------

wire        csr_valid  = fu_csr         ; // Inputs are valid.
wire        csr_ready                   ; // Instruction complete.

//
// Stalling / Pipeline Progression
// -------------------------------------------------------------------------

// Input into pipeline register, which then drives s4_p_valid;
wire   p_valid = 1'b1;

// Is this stage currently busy?
assign s3_p_busy = 1'b0;

//
// Submodule instances
// -------------------------------------------------------------------------

frv_alu i_alu (
.g_clk           (g_clk           ), // global clock
.g_resetn        (g_resetn        ), // synchronous reset
.alu_valid       (alu_valid       ), // Stall this stage
.alu_flush       (alu_flush       ), // flush the stage
.alu_ready       (alu_ready       ), // stage ready to progress
.alu_op_add      (alu_op_add      ), // 
.alu_op_sub      (alu_op_sub      ), // 
.alu_op_xor      (alu_op_xor      ), // 
.alu_op_or       (alu_op_or       ), // 
.alu_op_and      (alu_op_and      ), // 
.alu_op_shf      (alu_op_shf      ), // 
.alu_op_shf_left (alu_op_shf_left ), // 
.alu_op_shf_arith(alu_op_shf_arith), // 
.alu_op_cmp      (alu_op_cmp      ), // 
.alu_op_unsigned (alu_op_unsigned ), //
.alu_lt          (alu_lt          ), // Is LHS < RHS?
.alu_eq          (alu_eq          ), // Is LHS = RHS?
.alu_add_result  (alu_add_result  ), // Sum of LHS and RHS.
.alu_lhs         (alu_lhs         ), // left hand operand
.alu_rhs         (alu_rhs         ), // right hand operand
.alu_result      (alu_result      )  // result of the ALU operation
);


frv_lsu i_lsu (
.g_clk          (g_clk          ), // Global clock
.g_resetn       (g_resetn       ), // Global reset.
.lsu_valid      (lsu_valid      ), // Inputs are valid.
.lsu_ready      (lsu_ready      ), // Outputs are valid / instruction complete.
.lsu_a_error    (lsu_a_error    ), // Address error.
.lsu_b_error    (lsu_b_error    ), // Bus error.
.lsu_addr       (lsu_addr       ), // Memory address to access.
.lsu_wdata      (lsu_wdata      ), // Data to write to memory.
.lsu_rdata      (lsu_rdata      ), // Data read from memory.
.lsu_load       (lsu_load       ), // Load instruction.
.lsu_store      (lsu_store      ), // Store instruction.
.lsu_byte       (lsu_byte       ), // Byte operation width.
.lsu_half       (lsu_half       ), // Halfword operation width.
.lsu_word       (lsu_word       ), // Word operation width.
.lsu_signed     (lsu_signed     ), // Sign extend loaded data?
.dmem_cen       (dmem_cen       ), // Chip enable
.dmem_wen       (dmem_wen       ), // Write enable
.dmem_error     (dmem_error     ), // Error
.dmem_stall     (dmem_stall     ), // Memory stall
.dmem_strb      (dmem_strb      ), // Write strobe
.dmem_addr      (dmem_addr      ), // Read/Write address
.dmem_rdata     (dmem_rdata     ), // Read data
.dmem_wdata     (dmem_wdata     )  // Write data
);

//
// Pipeline Register
// -------------------------------------------------------------------------

endmodule

