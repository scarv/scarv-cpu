
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
input  wire [XL:0] s2_opr_d        , // Operand D
input  wire [OP:0] s2_uop          , // Micro-op code
input  wire [FU:0] s2_fu           , // Functional Unit
input  wire [PW:0] s2_pw           , // IALU pack width specifer.
input  wire        s2_trap         , // Raise a trap?
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word
output wire        s2_busy         , // Can this stage accept new inputs?
input  wire        s2_valid        , // Is this input valid?

input  wire [XL:0] leak_prng       , // Current PRNG value.
input  wire [12:0] leak_lkgcfg      , // Current lkgcfg register value.

output wire        rng_req_valid   , // Signal a new request to the RNG
output wire [ 2:0] rng_req_op      , // Operation to perform on the RNG
output wire [31:0] rng_req_data    , // Suplementary seed/init data
input  wire        rng_req_ready   , // RNG accepts request
input  wire        rng_rsp_valid   , // RNG response data valid
input  wire [ 2:0] rng_rsp_status  , // RNG status
input  wire [31:0] rng_rsp_data    , // RNG response / sample data.
output wire        rng_rsp_ready   , // CPU accepts response.

input  wire        uxcrypto_ct     , // UXCrypto constant time bit.
input  wire [ 7:0] uxcrypto_b0     , // UXCrypto lookup table 0.
input  wire [ 7:0] uxcrypto_b1     , // UXCrypto lookup table 1.

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
input  wire [XL:0] rvfi_s2_rs1_rdata_hi, // Source register data 1
input  wire [XL:0] rvfi_s2_rs2_rdata_hi, // Source register data 2
input  wire [XL:0] rvfi_s2_rs3_rdata, // Source register data 3
input  wire [ 4:0] rvfi_s2_rs1_addr , // Source register address 1
input  wire [ 4:0] rvfi_s2_rs2_addr , // Source register address 2
input  wire [ 4:0] rvfi_s2_rs3_addr , // Source register address 3
output reg  [XL:0] rvfi_s3_rs1_rdata, // Source register data 1
output reg  [XL:0] rvfi_s3_rs2_rdata, // Source register data 2
output reg  [XL:0] rvfi_s3_rs1_rdata_hi, // Source register data 1
output reg  [XL:0] rvfi_s3_rs2_rdata_hi, // Source register data 2
output reg  [XL:0] rvfi_s3_rs3_rdata, // Source register data 3
output reg  [ 4:0] rvfi_s3_rs1_addr , // Source register address 1
output reg  [ 4:0] rvfi_s3_rs2_addr , // Source register address 2
output reg  [ 4:0] rvfi_s3_rs3_addr , // Source register address 3
output reg  [XL:0] rvfi_s3_aux      , // Auxiliary needed information.
output wire [XL:0] rvfi_s3_mask_data, // Mask output data
output reg  [31:0] rvfi_s3_rng_data , // RNG read data
output reg  [ 2:0] rvfi_s3_rng_stat , // RNG status
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
parameter XC_CLASS_MASK       = 1'b1;

// Single cycle implementations of AES instructions?
parameter AES_SUB_FAST = 1'b1;
parameter AES_MIX_FAST = 1'b1;

//
// Partial Bitmanip Extension Support
parameter BITMANIP_BASELINE   = 1'b1;

//
// Masking ISE - Use a TRNG (1) or a PRNG (0)
parameter MASKING_ISE_TRNG    = 1'b0;

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
wire fu_msk = s2_fu[P_FU_MSK];

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

wire [PW:0] alu_pw          = XC_CLASS_PACKED ? s2_pw : PW_32 ;

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

wire        imul_pmul       = 
    (s2_uop == MUL_PMUL_L   || s2_uop == MUL_PMUL_H)   && XC_CLASS_PACKED;

wire        imul_pclmul     =
    (s2_uop == MUL_PCLMUL_L || s2_uop == MUL_PCLMUL_H) && XC_CLASS_PACKED;

wire        imul_clmul_r    = s2_uop == MUL_CLMUL_R     ;
wire        imul_clmul      = s2_uop == MUL_CLMUL_L     || 
                              s2_uop == MUL_CLMUL_H     ||
                              imul_clmul_r              ;
wire        imul_madd       = XC_CLASS_MULTIARITH && s2_uop == MUL_MADD;
wire        imul_msub       = XC_CLASS_MULTIARITH && s2_uop == MUL_MSUB;
wire        imul_macc       = XC_CLASS_MULTIARITH && s2_uop == MUL_MACC;
wire        imul_mmul       = XC_CLASS_MULTIARITH && s2_uop == MUL_MMUL;

wire [31:0] imul_rs1        = s2_opr_a;
wire [31:0] imul_rs2        = s2_opr_b;
wire [31:0] imul_rs3        = s2_opr_c;

wire        imul_flush      = pipe_progress || flush ||
                              leak_fence && leak_lkgcfg[LEAK_CFG_FU_MULT];

wire        imul_pw_2       = XC_CLASS_PACKED && s2_pw == PW_2 ;
wire        imul_pw_4       = XC_CLASS_PACKED && s2_pw == PW_4 ;
wire        imul_pw_8       = XC_CLASS_PACKED && s2_pw == PW_8 ;
wire        imul_pw_16      = XC_CLASS_PACKED && s2_pw == PW_16;
wire        imul_pw_32      = s2_pw == PW_32;

wire        imul_ready      ;
wire [63:0] imul_result_wide;

// Source the high 32-bits of the multiplier output.
wire        imul_result_hi  = imul_mulhu || imul_mulhsu ||
                              s2_uop == MUL_PMUL_H    ||
                              s2_uop == MUL_MULH      ||
                              s2_uop == MUL_PCLMUL_H  ||
                              s2_uop == MUL_CLMUL_H   ||
                              s2_uop == MUL_CLMUL_R   ;

wire [31:0] imul_result     = imul_result_hi ? imul_result_wide[63:32]  :
                                               imul_result_wide[31: 0]  ;

wire        imul_gpr_wide   = imul_madd || imul_msub || imul_macc || imul_mmul;

wire [XL:0] n_s3_opr_a_mul  = imul_clmul_r ? {1'b0,imul_result_wide[63:33]} :
                                             imul_result                    ;

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
// Functional Unit Interfacing: Masking ISE
// -------------------------------------------------------------------------


// Bit to stop a very heavily delayed masked ALU instruction re-starting
// accidentally.
reg         msk_valid_en_r  ;
wire        msk_valid_en    = 
    msk_valid_en_r ? !(fu_msk && msk_ready && !pipe_progress) :
                                               pipe_progress  ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        msk_valid_en_r <= 1'b1;
    end else begin
        msk_valid_en_r <= msk_valid_en;
    end
end

// Mask ALU input valid.
wire        msk_valid       = fu_msk && msk_valid_en_r  ;
wire        msk_flush       = flush                     ;
wire        msk_ready       ; // Mask ALU operation complete.
    
wire        msk_op_b2a      = s2_uop == MSK_B2A     ;
wire        msk_op_a2b      = s2_uop == MSK_A2B     ;
wire        msk_op_b_mask   = s2_uop == MSK_B_MASK  ;
wire        msk_op_b_unmask = s2_uop == MSK_B_UNMASK;
wire        msk_op_b_remask = s2_uop == MSK_B_REMASK;
wire        msk_op_a_mask   = s2_uop == MSK_A_MASK  ;
wire        msk_op_a_unmask = s2_uop == MSK_A_UNMASK;
wire        msk_op_a_remask = s2_uop == MSK_A_REMASK;
wire        msk_op_b_not    = s2_uop == MSK_B_NOT   ;
wire        msk_op_b_and    = s2_uop == MSK_B_AND   ;
wire        msk_op_b_ior    = s2_uop == MSK_B_IOR   ;
wire        msk_op_b_xor    = s2_uop == MSK_B_XOR   ;
wire        msk_op_b_add    = s2_uop == MSK_B_ADD   ;
wire        msk_op_b_sub    = s2_uop == MSK_B_SUB   ;

wire [XL:0] msk_rs1_s0      = s2_opr_a;
wire [XL:0] msk_rs1_s1      = s2_opr_c;
wire [XL:0] msk_rs2_s0      = s2_opr_b;
wire [XL:0] msk_rs2_s1      = s2_opr_d;

wire [XL:0] msk_rd_s0       ; // Outputs from masked ALU
wire [XL:0] msk_rd_s1       ; // Outputs from masked ALU

wire [XL:0] msk_mask        ; // The mask. Used for verification.

wire [XL:0] n_s3_opr_a_msk  = msk_rd_s0;
wire [XL:0] n_s3_opr_b_msk  = msk_rd_s1;

wire        msk_gpr_wide    =
    fu_msk && !(msk_op_b_unmask || msk_op_a_unmask);


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

reg         asi_done   ;

wire        asi_finished = (asi_valid && asi_ready) || asi_done;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        asi_done <= 1'b0;
    end else begin
        asi_done <= (asi_done || (asi_valid && asi_ready)) && !pipe_progress;
    end
end

wire        asi_flush_aessub = leak_fence && leak_lkgcfg[LEAK_CFG_FU_AESSUB];
wire        asi_flush_aesmix = leak_fence && leak_lkgcfg[LEAK_CFG_FU_AESMIX];
wire [31:0] asi_flush_data   = leak_prng;

wire [XL:0] n_s3_opr_a_asi = asi_result ;

//
// Functional Unit Interfacing: Bitwise instructions.
// -------------------------------------------------------------------------

wire [31:0]  bitw_rs1         = s2_opr_a; //
wire [31:0]  bitw_rs2         = s2_opr_b; //
wire [31:0]  bitw_rs3         = s2_opr_c; //

// LSB of pipeline pw field switches between LUTs.
wire [ 7:0]  bitw_bop_lut     = s2_pw[0] ? uxcrypto_b1 : uxcrypto_b0 ;

wire         bitw_flush       = flush || pipe_progress;
wire         bitw_valid       = fu_bit;

wire         bitw_fsl         = fu_bit && s2_uop == BIT_FSL ;
wire         bitw_fsr         = fu_bit && s2_uop == BIT_FSR ;
wire         bitw_mror        = fu_bit && s2_uop == BIT_RORW;
wire         bitw_cmov        = fu_bit && s2_uop == BIT_CMOV;
wire         bitw_lut         = XC_CLASS_BIT && fu_bit && s2_uop == BIT_LUT ;
wire         bitw_bop         = XC_CLASS_BIT && fu_bit && s2_uop == BIT_BOP ;
wire [63:0]  bitw_result_wide ; // 64-bit result
wire         bitw_ready       ; // Outputs ready.

wire [31:0]  n_s3_opr_a_bit   = bitw_result_wide[31: 0];
wire [31:0]  n_s3_opr_b_bit   = bitw_result_wide[63:32];

wire         bitw_gpr_wide    = bitw_mror;

//
// Functional Unit Interfacing: Randomness Interface
// -------------------------------------------------------------------------

wire [XL:0]  rng_rs1          = s2_opr_a;
wire         rng_valid        = XC_CLASS_RANDOMNESS && fu_rng && s2_uop != RNG_ALFENCE;

wire         rng_uop_test     = XC_CLASS_RANDOMNESS && fu_rng && s2_uop == RNG_RNGTEST;
wire         rng_uop_seed     = XC_CLASS_RANDOMNESS && fu_rng && s2_uop == RNG_RNGSEED;
wire         rng_uop_samp     = XC_CLASS_RANDOMNESS && fu_rng && s2_uop == RNG_RNGSAMP;

wire         rng_if_ready     ;
wire         rng_ready = rng_if_ready || leak_fence;
wire [XL:0]  rng_result       ;

wire [XL:0]  n_s3_opr_a_rng   = rng_result ;

//
// Stalling / Pipeline Progression
// -------------------------------------------------------------------------

// Input into pipeline register, which then drives s3_p_valid;
wire   p_valid   = s2_valid && !s2_busy;

// Is this stage currently busy?
assign s2_busy = p_busy                    ||
                 asi_valid  && !asi_finished||
                 lsu_valid  && !lsu_ready  ||
                 rng_valid  && !rng_ready  ||
                 imul_valid && !imul_ready ||
                 bitw_valid && !bitw_ready ||
                 msk_valid  && !msk_ready  ;

// Is the next stage currently busy?
wire   p_busy    ;

//
// Submodule instances
// -------------------------------------------------------------------------

frv_asi #(
.AES_SUB_FAST (AES_SUB_FAST ),
.AES_MIX_FAST (AES_MIX_FAST ),
.XC_CLASS_AES (XC_CLASS_AES ),
.XC_CLASS_SHA2(XC_CLASS_SHA2),
.XC_CLASS_SHA3(XC_CLASS_SHA3)
) i_asi(
.g_clk     (g_clk           ), // global clock
.g_resetn  (g_resetn        ), // synchronous reset
.asi_valid (asi_valid       ), // Stall this stage
.asi_ready (asi_ready       ), // stage ready to progress
.asi_flush_aessub(asi_flush_aessub), // Flush any state in AES sub submodule
.asi_flush_aesmix(asi_flush_aesmix), // Flush any state in AES mix submodule
.asi_flush_data  (asi_flush_data  ), // Data to flush into the submodules.
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
.alu_pw          (alu_pw          ), // Pack width specifier.
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
// instance: frv_masked_alu
//
//  Implements all of the masked ALU functionality.
//
frv_masked_alu #(
.MASKING_ISE_TRNG(MASKING_ISE_TRNG)
) i_frv_masked_alu (
.g_clk       (g_clk           ), // Global clock
.g_resetn    (g_resetn        ), // Synchronous, active low reset.
.valid       (msk_valid       ), // Inputs valid
.flush       (msk_flush       ), // Flush state
.op_b2a      (msk_op_b2a      ), // Binary to arithmetic mask covert
.op_a2b      (msk_op_a2b      ), // Arithmetic to binary mask convert
.op_b_mask   (msk_op_b_mask   ), // Binary mask
.op_b_unmask (msk_op_b_unmask ), // Binary unmask
.op_b_remask (msk_op_b_remask ), // Binary remask
.op_a_mask   (msk_op_a_mask   ), // Arithmetic mask
.op_a_unmask (msk_op_a_unmask ), // Arithmetic unmask
.op_a_remask (msk_op_a_remask ), // Arithmetic remask
.op_b_not    (msk_op_b_not    ), // Binary masked not
.op_b_and    (msk_op_b_and    ), // Binary masked and
.op_b_ior    (msk_op_b_ior    ), // Binary masked or
.op_b_xor    (msk_op_b_xor    ), // Binary masked xor
.op_b_add    (msk_op_b_add    ), // Binary masked addition
.op_b_sub    (msk_op_b_sub    ), // Binary masked subtraction
.rs1_s0      (msk_rs1_s0      ), // RS1 Share 0
.rs1_s1      (msk_rs1_s1      ), // RS1 Share 1
.rs2_s0      (msk_rs2_s0      ), // RS2 Share 0
.rs2_s1      (msk_rs2_s1      ), // RS2 Share 1
.ready       (msk_ready       ), // Outputs ready
.mask        (msk_mask        ), // Mask used to en-mask. For Verification.
.rd_s0       (msk_rd_s0       ), // Output share 0
.rd_s1       (msk_rd_s1       )  // Output share 1
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
.flush_data (leak_prng       ), //
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
// instance: frv_bitwise
//
//  This module is responsible for many of the bitwise operations the
//  core performs, both from XCrypto and Bitmanip
//
frv_bitwise #(
.XC_CLASS_BIT(XC_CLASS_BIT)
) i_frv_bitwise (
.rs1     (bitw_rs1        ), //
.rs2     (bitw_rs2        ), //
.rs3     (bitw_rs3        ), //
.bop_lut (bitw_bop_lut    ), // LUT for xc.bop
.flush   (bitw_flush      ), // Flush state / pipeline progress
.valid   (bitw_valid      ), // Inputs valid.
.uop_fsl (bitw_fsl        ), // Funnel shift Left
.uop_fsr (bitw_fsr        ), // Funnel shift right
.uop_mror(bitw_mror       ), // Wide rotate right
.uop_cmov(bitw_cmov       ), // Conditional move
.uop_lut (bitw_lut        ), // xc.lut
.uop_bop (bitw_bop        ), // xc.bop
.result  (bitw_result_wide), // 64-bit result
.ready   (bitw_ready      )  // Outputs ready.
);

//
// instance: frv_rng_if
//
//  Handles interfacing with the external random number generator.
//
frv_rngif i_frv_rngif (
.g_clk            (g_clk            ), // global clock
.g_resetn         (g_resetn         ), // synchronous reset
.flush            (flush            ), // Flush any internal resources.
.pipeline_progress(pipe_progress    ), // Pipeline is progressing this cycle.
.valid            (rng_valid        ), // Inputs valid
.rs1              (rng_rs1          ), // Input source register 1.
.rng_req_valid    (rng_req_valid    ), // Signal a new request to the RNG
.rng_req_op       (rng_req_op       ), // Operation to perform on the RNG
.rng_req_data     (rng_req_data     ), // Suplementary seed/init data
.rng_req_ready    (rng_req_ready    ), // RNG accepts request
.rng_rsp_valid    (rng_rsp_valid    ), // RNG response data valid
.rng_rsp_status   (rng_rsp_status   ), // RNG status
.rng_rsp_data     (rng_rsp_data     ), // RNG response / sample data.
.rng_rsp_ready    (rng_rsp_ready    ), // CPU accepts response.
.uop_test         (rng_uop_test     ), // Test the RNG status
.uop_seed         (rng_uop_seed     ), // Seed the RNG with new entropy
.uop_samp         (rng_uop_samp     ), // Sample from the RNG
.result           (rng_result       ), // Result to write back
.ready            (rng_if_ready     )  // Result ready.
);

//
// Pipeline Register
// -------------------------------------------------------------------------

localparam RL = 42 + OP + FU;

wire leak_fence    = fu_rng && s2_uop == RNG_ALFENCE;

wire opra_flush    = (pipe_progress && leak_fence && leak_lkgcfg[LEAK_CFG_S3_OPR_A]);
wire oprb_flush    = (pipe_progress && leak_fence && leak_lkgcfg[LEAK_CFG_S3_OPR_B]);

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
    {XLEN{fu_rng}} & n_s3_opr_a_rng |
    {XLEN{fu_alu}} & n_s3_opr_a_alu |
    {XLEN{fu_bit}} & n_s3_opr_a_bit |
    {XLEN{fu_mul}} & n_s3_opr_a_mul |
    {XLEN{fu_lsu}} & n_s3_opr_a_lsu |
    {XLEN{fu_cfu}} & n_s3_opr_a_cfu |
    {XLEN{fu_csr}} & n_s3_opr_a_csr |
    {XLEN{fu_msk}} & n_s3_opr_a_msk ;

wire [XL:0] n_s3_opr_b =
    n_s3_trap ? {26'b0,n_trap_cause} : (
        {XLEN{fu_alu}} & n_s3_opr_b_alu |
        {XLEN{fu_bit}} & n_s3_opr_b_bit |
        {XLEN{fu_mul}} & n_s3_opr_b_mul |
        {XLEN{fu_lsu}} & n_s3_opr_b_lsu |
        {XLEN{fu_cfu}} & n_s3_opr_b_cfu |
        {XLEN{fu_csr}} & n_s3_opr_b_csr |
        {XLEN{fu_msk}} & n_s3_opr_b_msk 
    );

wire opra_ld_en = p_valid && (
    fu_alu || fu_mul || fu_lsu || fu_cfu || fu_csr || fu_asi || fu_bit ||
    fu_rng || fu_msk ); 

wire oprb_ld_en = p_valid && (
    (fu_mul && imul_gpr_wide)  || 
    (fu_msk && msk_gpr_wide )  || 
    (fu_lsu && lsu_store    )  ||
     fu_csr                    ||
    (fu_bit && bitw_gpr_wide)  ); 

// Forwaring / bubbling signals.
assign fwd_s2_rd    = s2_rd             ; // Writeback stage destination reg.

assign fwd_s2_wdata = n_s3_opr_a;

assign fwd_s2_wdata_hi = fu_mul ? imul_result_wide[63:32]   :
                         fu_bit ? n_s3_opr_b_bit            :
                                  n_s3_opr_b_msk            ;
assign fwd_s2_wide  =
    fu_mul && (imul_gpr_wide) ||
    fu_msk && (msk_gpr_wide ) ||
    fu_bit && (bitw_gpr_wide  );

assign fwd_s2_load  = fu_lsu && lsu_load; // Writeback stage has load in it.
assign fwd_s2_csr   = fu_csr            ; // Writeback stage has CSR op in it.


wire [RL-1:0] pipe_reg_out;

wire [RL-1:0] pipe_reg_in = {
    n_s3_rd           , // Destination register address
    n_s3_uop          , // Micro-op code
    n_s3_fu           , // Functional Unit
    n_s3_trap         , // Raise a trap?
    n_s3_size         , // Size of the instruction.
    n_s3_instr          // The instruction word
};


assign {
    s3_rd             , // Destination register address
    s3_uop            , // Micro-op code
    s3_fu             , // Functional Unit
    s3_trap           , // Raise a trap?
    s3_size           , // Size of the instruction.
    s3_instr            // The instruction word
} = pipe_reg_out;

frv_pipeline_register #(
.RLEN(RL),
.BUFFER_HANDSHAKE(1'b0)
) i_execute_pipe_reg(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (pipe_reg_in      ), // Input data from stage N
.i_valid  (p_valid          ), // Input data valid?
.o_busy   (p_busy           ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Most recent data into the stage.
.flush    (flush            ), // Flush the contents of the pipeline
.flush_dat({RL{1'b0}}       ), // Data flushed into the pipeline.
.o_data   (pipe_reg_out     ), // Output data for stage N+1
.o_valid  (s3_valid         ), // Input data from stage N valid?
.i_busy   (s3_busy          )  // Stage N+1 ready to continue?
);

frv_pipeline_register #(
.RLEN(XLEN),
.BUFFER_HANDSHAKE(1'b0)
) i_execute_pipe_reg_opr_a(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (n_s3_opr_a       ), // Input data from stage N
.i_valid  (opra_ld_en       ), // Input data valid?
.o_busy   (                 ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Most recent data into the stage.
.flush    (opra_flush       ), // Flush the contents of the pipeline
.flush_dat(leak_prng        ), // Data flushed into the pipeline.
.o_data   (s3_opr_a         ), // Output data for stage N+1
.o_valid  (                 ), // Input data from stage N valid?
.i_busy   (s3_busy          )  // Stage N+1 ready to continue?
);

frv_pipeline_register #(
.RLEN(XLEN),
.BUFFER_HANDSHAKE(1'b0)
) i_execute_pipe_reg_opr_b(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (n_s3_opr_b       ), // Input data from stage N
.i_valid  (oprb_ld_en       ), // Input data valid?
.o_busy   (                 ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Most recent data into the stage.
.flush    (oprb_flush       ), // Flush the contents of the pipeline
.flush_dat(leak_prng        ), // Data flushed into the pipeline.
.o_data   (s3_opr_b         ), // Output data for stage N+1
.o_valid  (                 ), // Input data from stage N valid?
.i_busy   (s3_busy          )  // Stage N+1 ready to continue?
);


//
// RISC-V Formal
// -------------------------------------------------------------------------

`ifdef RVFI

// Only use aux signal to carry EX stage aligned uxcrypto content for now.
wire [XL:0] n_rvfi_s3_aux = {16'b0, uxcrypto_b1, uxcrypto_b0};

reg [31:0] saved_rng_data;
reg [ 2:0] saved_rng_stat;
reg        use_saved_rng ;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        saved_rng_data <= 0;
        saved_rng_stat <= 0;
    end else if(rng_rsp_valid && rng_rsp_ready) begin
        saved_rng_data <= rng_rsp_data;
        saved_rng_stat <= rng_rsp_status;
    end
end

always @(posedge g_clk) begin
    if(!g_resetn) begin
        use_saved_rng <= 1'b0;
    end else if(pipe_progress || flush) begin
        use_saved_rng <= 1'b0;
    end else begin
        use_saved_rng <= rng_rsp_valid && rng_rsp_ready && !pipe_progress;
    end
end

assign rvfi_s3_mask_data = msk_mask;

always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        rvfi_s3_rs1_rdata <= 0; // Source register data 1
        rvfi_s3_rs2_rdata <= 0; // Source register data 2
        rvfi_s3_rs1_rdata_hi <= 0; // Source register data 1
        rvfi_s3_rs2_rdata_hi <= 0; // Source register data 2
        rvfi_s3_rs3_rdata <= 0; // Source register data 3
        rvfi_s3_rs1_addr  <= 0; // Source register address 1
        rvfi_s3_rs2_addr  <= 0; // Source register address 2
        rvfi_s3_rs3_addr  <= 0; // Source register address 3
        rvfi_s3_aux       <= 0; // Auxiliary data
        rvfi_s3_rng_data  <= 0; // RNG read data
        rvfi_s3_rng_stat  <= 0; // RNG Status
    end else if(pipe_progress) begin
        rvfi_s3_rs1_rdata <= rvfi_s2_rs1_rdata;
        rvfi_s3_rs2_rdata <= rvfi_s2_rs2_rdata;
        rvfi_s3_rs1_rdata_hi <= rvfi_s2_rs1_rdata_hi;
        rvfi_s3_rs2_rdata_hi <= rvfi_s2_rs2_rdata_hi;
        rvfi_s3_rs3_rdata <= rvfi_s2_rs3_rdata;
        rvfi_s3_rs1_addr  <= rvfi_s2_rs1_addr ;
        rvfi_s3_rs2_addr  <= rvfi_s2_rs2_addr ;
        rvfi_s3_rs3_addr  <= rvfi_s2_rs3_addr ;
        rvfi_s3_aux       <= n_rvfi_s3_aux    ;
        rvfi_s3_rng_data  <= use_saved_rng ? saved_rng_data : rng_rsp_data  ;
        rvfi_s3_rng_stat  <= use_saved_rng ? saved_rng_stat : rng_rsp_status;
    end
end

`endif

endmodule

