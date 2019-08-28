
//
// module: frv_pipeline_execute
//
//  Execute stage of the pipeline, responsible for ALU / LSU / Branch compare.
//
module frv_pipeline_execute (

input              g_clk           , // global clock
input              g_resetn        , // synchronous reset

input  wire [ 4:0] s2_rd           , // Destination register address
input  wire [XL:0] s2_opr_a        , // Operand A
input  wire [XL:0] s2_opr_b        , // Operand B
input  wire [XL:0] s2_opr_c        , // Operand C
input  wire [OP:0] s2_uop          , // Micro-op code
input  wire [FU:0] s2_fu           , // Functional Unit
input  wire [PW:0] s2_pw           , // IALU pack width specifer.
input  wire        s2_trap         , // Raise a trap?
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word
output wire        s2_busy         , // Can this stage accept new inputs?
input  wire        s2_valid        , // Is this input valid?

input  wire        flush           , // Flush this pipeline stage.

output wire [ 4:0] fwd_s2_rd       , // Writeback stage destination reg.
output wire        fwd_s2_wide     , // stage wide writeback
output wire [XL:0] fwd_s2_wdata    , // Write data for writeback stage.
output wire [XL:0] fwd_s2_wdata_hi , // Write data for writeback stage.
output wire        fwd_s2_load     , // Writeback stage has load in it.
output wire        fwd_s2_csr      , // Writeback stage has CSR op in it.

`ifdef RVFI
input  wire [XL:0] rvfi_s2_rs1_rdata, // Source register data 1
input  wire [XL:0] rvfi_s2_rs2_rdata, // Source register data 2
input  wire [XL:0] rvfi_s2_rs3_rdata, // Source register data 3
input  wire [ 4:0] rvfi_s2_rs1_addr , // Source register address 1
input  wire [ 4:0] rvfi_s2_rs2_addr , // Source register address 2
input  wire [ 4:0] rvfi_s2_rs3_addr , // Source register address 3
output reg  [XL:0] rvfi_s3_rs1_rdata, // Source register data 1
output reg  [XL:0] rvfi_s3_rs2_rdata, // Source register data 2
output reg  [XL:0] rvfi_s3_rs3_rdata, // Source register data 3
output reg  [ 4:0] rvfi_s3_rs1_addr , // Source register address 1
output reg  [ 4:0] rvfi_s3_rs2_addr , // Source register address 2
output reg  [ 4:0] rvfi_s3_rs3_addr , // Source register address 3
`endif

output wire [ 4:0] s3_rd           , // Destination register address
output wire [XL:0] s3_opr_a        , // Operand A
output wire [XL:0] s3_opr_b        , // Operand B
output wire [OP:0] s3_uop          , // Micro-op code
output wire [FU:0] s3_fu           , // Functional Unit
output wire        s3_trap         , // Raise a trap?
output wire [ 1:0] s3_size         , // Size of the instruction.
output wire [31:0] s3_instr        , // The instruction word
input  wire        s3_busy         , // Can this stage accept new inputs?
output wire        s3_valid          // Is this input valid?

);


// Common core parameters and constants
`include "frv_common.vh"

wire pipe_progress = !s2_busy && s2_valid;

//
// XCrypto feature class config bits.
parameter XC_CLASS_RANDOMNESS = 1'b1;
parameter XC_CLASS_MEMORY     = 1'b1;
parameter XC_CLASS_BIT        = 1'b1;
parameter XC_CLASS_PACKED     = 1'b1;
parameter XC_CLASS_MULTIARITH = 1'b1;
parameter XC_CLASS_AES        = 1'b1;
parameter XC_CLASS_SHA2       = 1'b1;
parameter XC_CLASS_SHA3       = 1'b1;

//
// Partial Bitmanip Extension Support
parameter BITMANIP_BASELINE   = 1'b1;

//
// Operation Decoding
// -------------------------------------------------------------------------

wire fu_alu = s2_fu[P_FU_ALU];
wire fu_mul = s2_fu[P_FU_MUL];
wire fu_lsu = s2_fu[P_FU_LSU];
wire fu_cfu = s2_fu[P_FU_CFU];
wire fu_csr = s2_fu[P_FU_CSR];
wire fu_asi = s2_fu[P_FU_ASI];
wire fu_bit = s2_fu[P_FU_BIT];
wire fu_rng = s2_fu[P_FU_RNG];

//
// Functional Unit Interfacing: ALU
// -------------------------------------------------------------------------

wire        alu_valid       = fu_alu    ; // Stall this stage
wire        alu_flush       = flush     ; // flush the stage
wire        alu_ready                   ; // stage ready to progress

wire        alu_op_add      = fu_alu && s2_uop == ALU_ADD;
wire        alu_op_sub      = fu_alu && s2_uop == ALU_SUB;
wire        alu_op_xor      = fu_alu && s2_uop == ALU_XOR;
wire        alu_op_or       = fu_alu && s2_uop == ALU_OR ;
wire        alu_op_and      = fu_alu && s2_uop == ALU_AND;

wire        alu_op_shf      = fu_alu && (s2_uop == ALU_SLL ||
                                         s2_uop == ALU_SRL ||
                                         s2_uop == ALU_SRA );
wire        alu_op_rot      = fu_alu && (s2_uop == ALU_ROR );

wire        alu_op_shf_left = fu_alu && s2_uop == ALU_SLL;
wire        alu_op_shf_arith= fu_alu && s2_uop == ALU_SRA;

wire        alu_op_cmp      = fu_alu && (s2_uop == ALU_SLT  ||
                                         s2_uop == ALU_SLTU )   ||
                              cfu_cond;

wire        alu_op_unsigned = fu_alu && (s2_uop == ALU_SLTU) ||
                              cond_bgeu || cond_bltu        ;

wire        alu_lt                      ; // Is LHS < RHS?
wire        alu_eq                      ; // Is LHS = RHS?
wire [XL:0] alu_add_result              ; // Result of adding LHS,RHS.

wire [XL:0] alu_lhs         = s2_opr_a  ; // left hand operand
wire [XL:0] alu_rhs         = s2_opr_b  ; // right hand operand
wire [XL:0] alu_result                  ; // result of the ALU operation

wire [XL:0] n_s3_opr_a_alu = alu_result;
wire [XL:0] n_s3_opr_b_alu = 32'b0;

//
// Functional Unit Interfacing: Multiplier
// -------------------------------------------------------------------------

wire        imul_valid      = fu_mul                    ;
wire        imul_div        = s2_uop == MUL_DIV         ;
wire        imul_divu       = s2_uop == MUL_DIVU        ;
wire        imul_mul        = s2_uop == MUL_MUL         ||
                              s2_uop == MUL_MULH        ;
wire        imul_mulhsu     = s2_uop == MUL_MULHSU      ;
wire        imul_mulhu      = s2_uop == MUL_MULHU       ;
wire        imul_rem        = s2_uop == MUL_REM         ;
wire        imul_remu       = s2_uop == MUL_REMU        ;
wire        imul_pmul       = s2_uop == MUL_PMUL_L      ||
                              s2_uop == MUL_PMUL_H      ;
wire        imul_pclmul     = s2_uop == MUL_PCLMUL_L    ||
                              s2_uop == MUL_PCLMUL_H    ;
wire        imul_clmul      = s2_uop == MUL_CLMUL_L     || 
                              s2_uop == MUL_CLMUL_H     ||
                              s2_uop == MUL_CLMUL_R     ;
wire        imul_madd       = s2_uop == MUL_MADD        ;
wire        imul_msub       = s2_uop == MUL_MSUB        ;
wire        imul_macc       = s2_uop == MUL_MACC        ;
wire        imul_mmul       = s2_uop == MUL_MMUL        ;

wire [31:0] imul_rs1        = s2_opr_a;
wire [31:0] imul_rs2        = s2_opr_b;
wire [31:0] imul_rs3        = s2_opr_c;

wire        imul_flush      = pipe_progress || flush;

wire        imul_pw_2       = s2_pw == PW_2 ;
wire        imul_pw_4       = s2_pw == PW_4 ;
wire        imul_pw_8       = s2_pw == PW_8 ;
wire        imul_pw_16      = s2_pw == PW_16;
wire        imul_pw_32      = s2_pw == PW_32;

wire        imul_ready      ;
wire [63:0] imul_result_wide;

// Source the high 32-bits of the multiplier output.
wire        imul_result_hi  = imul_mulhu || imul_mulhsu ||
                              s2_uop == MUL_PMUL_H    ||
                              s2_uop == MUL_MULH      ||
                              s2_uop == MUL_PCLMUL_H  ||
                              s2_uop == MUL_CLMUL_H   ||
                              s2_uop == MUL_CLMUL_R   ; // TODO: shift right 1

wire [31:0] imul_result     = imul_result_hi ? imul_result_wide[63:32]  :
                                               imul_result_wide[31: 0]  ;

wire [XL:0] n_s3_opr_a_mul  = imul_result;

// Always source the high half of the result. Whether it gets written
// back is decided in the writeback stage.
wire [XL:0] n_s3_opr_b_mul  = imul_result_wide[63:32];

//
// Functional Unit Interfacing: LSU
// -------------------------------------------------------------------------

wire        lsu_valid  = fu_lsu         ; // Inputs are valid.
wire        lsu_a_error= 1'b0           ; // Address error. TODO
wire        lsu_ready  = lsu_valid      ; // Load/Store instruction complete.

wire        lsu_load   = fu_lsu && s2_uop[LSU_LOAD ];
wire        lsu_store  = fu_lsu && s2_uop[LSU_STORE];

wire [XL:0] n_s3_opr_a_lsu = alu_add_result ;
wire [XL:0] n_s3_opr_b_lsu = s2_opr_c       ;

//
// Functional Unit Interfacing: CFU
// -------------------------------------------------------------------------

wire        cfu_valid   = fu_cfu        ; // Inputs are valid.
wire        cfu_ready   = cfu_valid     ; // Instruction complete.

wire        cfu_cond    = cfu_valid && s2_uop[4:3] == 2'b00;
wire        cfu_uncond  = cfu_valid && s2_uop[4:3] == 2'b10;
wire        cfu_jmp     = cfu_valid && s2_uop      == CFU_JMP ;
wire        cfu_jali    = cfu_valid && s2_uop      == CFU_JALI;
wire        cfu_jalr    = cfu_valid && s2_uop      == CFU_JALR;


wire        cond_beq    = cfu_valid && s2_uop == CFU_BEQ ;
wire        cond_bge    = cfu_valid && s2_uop == CFU_BGE ;
wire        cond_bgeu   = cfu_valid && s2_uop == CFU_BGEU;
wire        cond_blt    = cfu_valid && s2_uop == CFU_BLT ;
wire        cond_bltu   = cfu_valid && s2_uop == CFU_BLTU;
wire        cond_bne    = cfu_valid && s2_uop == CFU_BNE ;

wire        cfu_cond_taken =
    cond_beq  &&  alu_eq    ||
    cond_bge  && !alu_lt    ||  // Same signal for (un)signed inputs.
    cond_bgeu && !alu_lt    ||  // - see alu_op_unsigned signal.
    cond_blt  &&  alu_lt    ||
    cond_bltu &&  alu_lt    ||
    cond_bne  && !alu_eq    ;

wire        cfu_always_take= cfu_jalr || cfu_jali || cfu_jalr;

wire [4:0]  n_s3_uop_cfu   =
    cfu_cond        ? (cfu_cond_taken ? CFU_TAKEN : CFU_NOT_TAKEN)  :
    cfu_always_take ? s2_uop                                        :
                      s2_uop                                        ;

wire [XL:0] n_s3_opr_a_cfu = 
    cfu_jalr    ? {alu_add_result[XL:1],1'b0} :
                  {s2_opr_c      [XL:1],1'b0} ;

wire [XL:0] n_s3_opr_b_cfu = 32'b0;

//
// Functional Unit Interfacing: CSR
// -------------------------------------------------------------------------

wire        csr_valid  = fu_csr         ; // Inputs are valid.
wire        csr_ready  = csr_valid      ; // Instruction complete.

wire [XL:0] n_s3_opr_a_csr = s2_opr_a;
wire [XL:0] n_s3_opr_b_csr = s2_opr_c;

//
// Functional Unit Interfacing: Algorithm Specific Instructions
// -------------------------------------------------------------------------

wire        asi_valid  = fu_asi;
wire        asi_ready  ;
wire [XL:0] asi_result ;

wire [XL:0] n_s3_opr_a_asi = asi_result ;

//
// Stalling / Pipeline Progression
// -------------------------------------------------------------------------

// Input into pipeline register, which then drives s3_p_valid;
wire   p_valid   = s2_valid && !s2_busy;

// Is this stage currently busy?
assign s2_busy = p_busy                   ||
                 lsu_valid  && !lsu_ready ||
                 imul_valid && !imul_ready;

// Is the next stage currently busy?
wire   p_busy    ;

//
// Submodule instances
// -------------------------------------------------------------------------

frv_asi i_asi(
.g_clk     (g_clk           ), // global clock
.g_resetn  (g_resetn        ), // synchronous reset
.asi_valid (asi_valid       ), // Stall this stage
.asi_flush (flush           ), // flush the stage
.asi_ready (asi_ready       ), // stage ready to progress
.asi_uop   (s2_uop          ), // Exactly which operation to perform.
.asi_rs1   (s2_opr_a        ), // Source register 1
.asi_rs2   (s2_opr_c        ), // Source register 2
.asi_shamt (s2_opr_b[1:0]   ), // Shift amount for SHA3 instructions.
.asi_result(asi_result      )  // Instruction result.
);

frv_alu i_alu (
.g_clk           (g_clk           ), // global clock
.g_resetn        (g_resetn        ), // synchronous reset
.alu_valid       (alu_valid       ), // Stall this stage
.alu_flush       (alu_flush       ), // flush the stage
.alu_ready       (alu_ready       ), // stage ready to progress
.alu_pw          (s2_pw           ), // Pack width specifier.
.alu_op_add      (alu_op_add      ), // 
.alu_op_sub      (alu_op_sub      ), // 
.alu_op_xor      (alu_op_xor      ), // 
.alu_op_or       (alu_op_or       ), // 
.alu_op_and      (alu_op_and      ), // 
.alu_op_shf      (alu_op_shf      ), // 
.alu_op_rot      (alu_op_rot      ), // 
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

//
// instance: xc_malu
//
//  Implements a multi-cycle arithmetic logic unit for some of
//  the bigger / more complex instructions in XCrypto.
//
//  Instructions handled:
//  - div, divu, rem, remu
//  - mul, mulh, mulhu, mulhsu
//  - pmul.l, pmul.h
//  - clmul, clmulr, clmulh
//  - madd, msub, macc, mmul
//
xc_malu i_xc_malu (
.clock      (g_clk           ),
.resetn     (g_resetn        ),
.rs1        (imul_rs1        ), //
.rs2        (imul_rs2        ), //
.rs3        (imul_rs3        ), //
.flush      (imul_flush      ), // Flush state / pipeline progress
.valid      (imul_valid      ), // Inputs valid.
.uop_div    (imul_div        ), //
.uop_divu   (imul_divu       ), //
.uop_rem    (imul_rem        ), //
.uop_remu   (imul_remu       ), //
.uop_mul    (imul_mul        ), //
.uop_mulu   (imul_mulhu      ), //
.uop_mulsu  (imul_mulhsu     ), //
.uop_clmul  (imul_clmul      ), //
.uop_pmul   (imul_pmul       ), //
.uop_pclmul (imul_pclmul     ), //
.uop_madd   (imul_madd       ), //
.uop_msub   (imul_msub       ), //
.uop_macc   (imul_macc       ), //
.uop_mmul   (imul_mmul       ), //
.pw_32      (imul_pw_32      ), // 32-bit width packed elements.
.pw_16      (imul_pw_16      ), // 16-bit width packed elements.
.pw_8       (imul_pw_8       ), //  8-bit width packed elements.
.pw_4       (imul_pw_4       ), //  4-bit width packed elements.
.pw_2       (imul_pw_2       ), //  2-bit width packed elements.
.result     (imul_result_wide), // 64-bit result
.ready      (imul_ready      )  // Outputs ready.
);


//
// Pipeline Register
// -------------------------------------------------------------------------

localparam PIPE_REG_W = 106 + OP + FU;

wire [ 4:0] n_s3_rd    = s2_rd   ; // Functional Unit
wire [FU:0] n_s3_fu    = s2_fu   ; // Functional Unit
wire [ 1:0] n_s3_size  = s2_size ; // Size of the instruction.
wire [31:0] n_s3_instr = s2_instr; // The instruction word

wire [ 4:0] n_s3_uop   = cfu_valid ? n_s3_uop_cfu : s2_uop  ; // Micro-op code

wire        n_s3_trap  = s2_trap || 
                         fu_lsu && (lsu_a_error);

wire [5:0]  n_trap_cause =
    s2_trap                             ? {1'b0, s2_rd} :
    fu_lsu && lsu_a_error && lsu_load   ? TRAP_LDALIGN  :
    fu_lsu && lsu_a_error && lsu_store  ? TRAP_STALIGN  :
                                          6'b0          ;

wire [XL:0] n_s3_opr_a = 
    {XLEN{fu_asi}} & n_s3_opr_a_asi |
    {XLEN{fu_alu}} & n_s3_opr_a_alu |
    {XLEN{fu_mul}} & n_s3_opr_a_mul |
    {XLEN{fu_lsu}} & n_s3_opr_a_lsu |
    {XLEN{fu_cfu}} & n_s3_opr_a_cfu |
    {XLEN{fu_csr}} & n_s3_opr_a_csr ;

wire [XL:0] n_s3_opr_b =
    n_s3_trap ? {26'b0,n_trap_cause} : (
        {XLEN{fu_alu}} & n_s3_opr_b_alu |
        {XLEN{fu_mul}} & n_s3_opr_b_mul |
        {XLEN{fu_lsu}} & n_s3_opr_b_lsu |
        {XLEN{fu_cfu}} & n_s3_opr_b_cfu |
        {XLEN{fu_csr}} & n_s3_opr_b_csr 
    );


// Forwaring / bubbling signals.
assign fwd_s2_rd    = s2_rd             ; // Writeback stage destination reg.
assign fwd_s2_wdata = alu_result | imul_result | asi_result;
assign fwd_s2_wdata_hi = fu_mul ? imul_result_wide[63:32] : 32'b0;
assign fwd_s2_wide  = fu_mul && (
    imul_madd || imul_msub || imul_madd || imul_mmul
);
assign fwd_s2_load  = fu_lsu && lsu_load; // Writeback stage has load in it.
assign fwd_s2_csr   = fu_csr            ; // Writeback stage has CSR op in it.


wire [PIPE_REG_W-1:0] pipe_reg_out;

wire [PIPE_REG_W-1:0] pipe_reg_in = {
    n_s3_rd           , // Destination register address
    n_s3_opr_a        , // Operand A
    n_s3_opr_b        , // Operand B
    n_s3_uop          , // Micro-op code
    n_s3_fu           , // Functional Unit
    n_s3_trap         , // Raise a trap?
    n_s3_size         , // Size of the instruction.
    n_s3_instr          // The instruction word
};


assign {
    s3_rd             , // Destination register address
    s3_opr_a          , // Operand A
    s3_opr_b          , // Operand B
    s3_uop            , // Micro-op code
    s3_fu             , // Functional Unit
    s3_trap           , // Raise a trap?
    s3_size           , // Size of the instruction.
    s3_instr            // The instruction word
} = pipe_reg_out;

frv_pipeline_register #(
.RLEN(PIPE_REG_W),
.BUFFER_HANDSHAKE(1'b0)
) i_execute_pipe_reg(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (pipe_reg_in      ), // Input data from stage N
.i_valid  (p_valid          ), // Input data valid?
.o_busy   (p_busy           ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Most recent data into the stage.
.flush    (flush            ), // Flush the contents of the pipeline
.o_data   (pipe_reg_out     ), // Output data for stage N+1
.o_valid  (s3_valid         ), // Input data from stage N valid?
.i_busy   (s3_busy          )  // Stage N+1 ready to continue?
);


//
// RISC-V Formal
// -------------------------------------------------------------------------

`ifdef RVFI

always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        rvfi_s3_rs1_rdata <= 0; // Source register data 1
        rvfi_s3_rs2_rdata <= 0; // Source register data 2
        rvfi_s3_rs3_rdata <= 0; // Source register data 3
        rvfi_s3_rs1_addr  <= 0; // Source register address 1
        rvfi_s3_rs2_addr  <= 0; // Source register address 2
        rvfi_s3_rs3_addr  <= 0; // Source register address 3
    end else if(pipe_progress) begin
        rvfi_s3_rs1_rdata <= rvfi_s2_rs1_rdata;
        rvfi_s3_rs2_rdata <= rvfi_s2_rs2_rdata;
        rvfi_s3_rs3_rdata <= rvfi_s2_rs3_rdata;
        rvfi_s3_rs1_addr  <= rvfi_s2_rs1_addr ;
        rvfi_s3_rs2_addr  <= rvfi_s2_rs2_addr ;
        rvfi_s3_rs3_addr  <= rvfi_s2_rs3_addr ;
    end
end

`endif

endmodule

