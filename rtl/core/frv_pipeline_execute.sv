
import sme_pkg::*;

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
input  wire [ 4:0] s2_rs1_addr     , // Source regsiter addresses.
input  wire [ 4:0] s2_rs2_addr     , // Source regsiter addresses.
input  wire [OP:0] s2_uop          , // Micro-op code
input  wire [FU:0] s2_fu           , // Functional Unit
input  wire        s2_trap         , // Raise a trap?
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word
output wire        s2_busy         , // Can this stage accept new inputs?
input  wire        s2_valid        , // Is this input valid?

input  wire [XL:0] csr_smectl      , // SME CSR
input  wire [XL:0] sme_bank_rdata  , // SME bank read data (for stores).
output  sme_data_t sme_input_data  , // Input oeprands.
output             sme_alu_valid   , // Accept new input instruction.
input              sme_alu_ready   , // Ready for new input instruction.
output  sme_alu_t  sme_alu_op      , // Input instruction details.
output             sme_cry_valid   , // Accept new input instruction.
input              sme_cry_ready   , // Ready for new input instruction.
output  sme_cry_t  sme_cry_op      , // Input instruction details.
input  [      XL:0]sme_alu_result  , // ALU    0'th share result.
input  [      XL:0]sme_cry_result  , // Crypto 0'th share result.

input  wire        flush           , // Flush this pipeline stage.

output wire [ 4:0] fwd_s2_rd       , // Writeback stage destination reg.
output wire [XL:0] fwd_s2_wdata    , // Write data for writeback stage.
output wire        fwd_s2_load     , // Writeback stage has load in it.
output wire        fwd_s2_csr      , // Writeback stage has CSR op in it.

`ifdef RVFI
input  wire [XL:0] rvfi_s2_rs1_rdata, // Source register data 1
input  wire [XL:0] rvfi_s2_rs2_rdata, // Source register data 2
input  wire [ 4:0] rvfi_s2_rs1_addr , // Source register address 1
input  wire [ 4:0] rvfi_s2_rs2_addr , // Source register address 2
output reg  [XL:0] rvfi_s3_rs1_rdata, // Source register data 1
output reg  [XL:0] rvfi_s3_rs2_rdata, // Source register data 2
output reg  [ 4:0] rvfi_s3_rs1_addr , // Source register address 1
output reg  [ 4:0] rvfi_s3_rs2_addr , // Source register address 2
output reg  [XL:0] rvfi_s3_aux      , // Auxiliary needed information.
`endif

output wire [ 4:0] s3_rd           , // Destination register address
output wire [XL:0] s3_opr_a        , // Operand A
output wire [XL:0] s3_opr_b        , // Operand B
output wire [ 4:0] s3_rs1_addr     , // Source regsiter addresses.
output wire [ 4:0] s3_rs2_addr     , // Source regsiter addresses.
output wire [OP:0] s3_uop          , // Micro-op code
output wire [FU:0] s3_fu           , // Functional Unit
output wire        s3_trap         , // Raise a trap?
output wire [ 1:0] s3_size         , // Size of the instruction.
output wire [31:0] s3_instr        , // The instruction word
input  wire        s3_busy         , // Can this stage accept new inputs?
output wire        s3_valid          // Is this input valid?

);


// Common core parameters and constants
`include "frv_common.svh"

parameter ZKAES     = 1; // Support the Crypto AES instructions?
parameter ZKSHA256  = 1; // Support the Crypto SHA256 instructions?
parameter ZKSHA512  = 1; // Support the Crypto SHA512 instructions?
parameter ZKSM3     = 1; // Support the Crypto SM3 instructions?
parameter ZKSM4     = 1; // Support the Crypto SM4 instructions?
parameter ZKBIT     = 1; // Support the Crypto Bitmanip instructions?
parameter ZKPOLL    = 1; // Support the Crypto poll entropy instruction?
parameter ZBB       = 1; // Support the ZBB Bitmanip Base instructions.
parameter ZBP       = 1; // Support the ZBP Bitmanip permutation instructions.
parameter ZBC       = 1; // Support the ZBC Bitmanip CLMUL instrs.
parameter  COMBINE_AES_SM4 =0 ; // Enable combined RV32 AES/SM4 module.

parameter SME_SMAX = 3; // Max shares supported by the SME implementation.

wire pipe_progress = !s2_busy && s2_valid;

//
// Operation Decoding
// -------------------------------------------------------------------------

wire fu_alu = s2_fu[P_FU_ALU];
wire fu_mul = s2_fu[P_FU_MUL];
wire fu_lsu = s2_fu[P_FU_LSU];
wire fu_cfu = s2_fu[P_FU_CFU];
wire fu_csr = s2_fu[P_FU_CSR];
wire fu_cry = s2_fu[P_FU_CRY];
wire fu_sme = s2_fu[P_FU_SME];

//
// Functional Unit Interfacing: ALU
// -------------------------------------------------------------------------

wire        alu_valid       = fu_alu    ; // Stall this stage
wire        alu_flush       = flush     ; // flush the stage
wire        alu_ready                   ; // stage ready to progress

wire        alu_op_add      = fu_alu && s2_uop == ALU_ADD   ;
wire        alu_op_sub      = fu_alu && s2_uop == ALU_SUB   ;
wire        alu_op_xor      = fu_alu && s2_uop == ALU_XOR   ;
wire        alu_op_or       = fu_alu && s2_uop == ALU_OR    ;
wire        alu_op_and      = fu_alu && s2_uop == ALU_AND   ;
wire        alu_op_xnor     = fu_alu && s2_uop == ALU_XNOR&&(ZBP||ZKBIT||ZBB);
wire        alu_op_orn      = fu_alu && s2_uop == ALU_ORN &&(ZBP||ZKBIT||ZBB);
wire        alu_op_andn     = fu_alu && s2_uop == ALU_ANDN&&(ZBP||ZKBIT||ZBB);

wire        alu_op_sll      = fu_alu && s2_uop == ALU_SLL   ;
wire        alu_op_srl      = fu_alu && s2_uop == ALU_SRL   ;
wire        alu_op_sra      = fu_alu && s2_uop == ALU_SRA   ;
wire        alu_op_ror      = fu_alu && s2_uop == ALU_ROR &&(ZBP||ZKBIT||ZBB);
wire        alu_op_rol      = fu_alu && s2_uop == ALU_ROL &&(ZBP||ZKBIT||ZBB);
wire        alu_op_slo      = fu_alu && s2_uop == ALU_SLO && ZBP;
wire        alu_op_sro      = fu_alu && s2_uop == ALU_SRO && ZBP;

wire        alu_op_pack     = fu_alu && s2_uop == ALU_PACK &&(ZBB||ZKBIT||ZBB);
wire        alu_op_packh    = fu_alu && s2_uop == ALU_PACKH&&(ZBB||ZKBIT||ZBB);
wire        alu_op_packu    = fu_alu && s2_uop == ALU_PACKU&&(ZBB||ZKBIT||ZBB);

wire        alu_op_grev     = fu_alu && s2_uop == ALU_GREV  &&(ZBP||ZKBIT);
wire        alu_op_shfl     = fu_alu && s2_uop == ALU_SHFL  &&(ZBP||ZKBIT);
wire        alu_op_unshfl   = fu_alu && s2_uop == ALU_UNSHFL&&(ZBP||ZKBIT);
wire        alu_op_gorc     = fu_alu && s2_uop == ALU_GORC  &&(ZBP||ZKBIT);

wire        alu_op_slt      = fu_alu && s2_uop == ALU_SLT   ;
wire        alu_op_sltu     = fu_alu && s2_uop == ALU_SLTU  ;
wire        alu_op_max      = fu_alu && s2_uop == ALU_MAX   && ZBB;
wire        alu_op_maxu     = fu_alu && s2_uop == ALU_MAXU  && ZBB;
wire        alu_op_min      = fu_alu && s2_uop == ALU_MIN   && ZBB;
wire        alu_op_minu     = fu_alu && s2_uop == ALU_MINU  && ZBB;

wire        alu_op_clz      = fu_alu && s2_uop == ALU_CLZ   && ZBB;
wire        alu_op_ctz      = fu_alu && s2_uop == ALU_CTZ   && ZBB;
wire        alu_op_pcnt     = fu_alu && s2_uop == ALU_PCNT  && ZBB;
wire        alu_op_sextb    = fu_alu && s2_uop == ALU_SEXTB && ZBB;
wire        alu_op_sexth    = fu_alu && s2_uop == ALU_SEXTH && ZBB;

wire        alu_op_xpermn   = fu_alu && s2_uop == ALU_XPERMN && (ZBP||ZKBIT);
wire        alu_op_xpermb   = fu_alu && s2_uop == ALU_XPERMB && (ZBP||ZKBIT);

wire        alu_cmp_lt      ; // Is LHS < RHS?
wire        alu_cmp_ltu     ; // Is LHS < RHS?
wire        alu_cmp_eq      ; // Is LHS = RHS?
wire [XL:0] alu_add_out     ; // Result of adding LHS,RHS.

wire [XL:0] alu_opr_a       = s2_opr_a      ; // left hand operand
wire [XL:0] alu_opr_b       = s2_opr_b      ; // right hand operand
wire [ 4:0] alu_shamt       = s2_opr_b[4:0] ; // shift/rotate amount.
wire [XL:0] alu_result                      ; // result of the ALU operation

wire [XL:0] n_s3_opr_a_alu = alu_result;
wire [XL:0] n_s3_opr_b_alu = 32'b0;

//
// Functional Unit Interfacing: Multiplier
// -------------------------------------------------------------------------

wire        imul_valid      = fu_mul                    ;
wire        imul_flush      = pipe_progress || flush;
wire        imul_ready      ;

wire        imul_clk_req    ; // Clock Request

wire        imul_op_mul     = fu_mul && s2_uop == MUL_MUL   ;
wire        imul_op_mulh    = fu_mul && s2_uop == MUL_MULH  ;
wire        imul_op_mulhu   = fu_mul && s2_uop == MUL_MULHU ;
wire        imul_op_mulhsu  = fu_mul && s2_uop == MUL_MULHSU;
wire        imul_op_div     = fu_mul && s2_uop == MUL_DIV   ;
wire        imul_op_divu    = fu_mul && s2_uop == MUL_DIVU  ;
wire        imul_op_rem     = fu_mul && s2_uop == MUL_REM   ;
wire        imul_op_remu    = fu_mul && s2_uop == MUL_REMU  ;
wire        imul_op_clmul   = fu_mul && s2_uop == MUL_CLMUL  && (ZKBIT||ZBC);
wire        imul_op_clmulh  = fu_mul && s2_uop == MUL_CLMULH && (ZKBIT||ZBC);
wire        imul_op_clmulr  = fu_mul && s2_uop == MUL_CLMULR && (ZKBIT||ZBC);

wire [XL:0] imul_rs1        = s2_opr_a; // Source register 1
wire [XL:0] imul_rs2        = s2_opr_b; // Source register 2

wire [XL:0] imul_rd         ;
wire [XL:0] n_s3_opr_a_mul  = imul_rd;
wire [XL:0] n_s3_opr_b_mul  = 32'b0;

//
// Functional Unit Interfacing: SME
// -------------------------------------------------------------------------

wire       sme_on   = sme_is_on(csr_smectl);
wire [3:0] smectl_b = csr_smectl[3:0];

wire       sme_mask      = sme_on && fu_sme && s2_uop==SME_MASK;
wire       sme_unmask    = sme_on && fu_sme && s2_uop==SME_UNMASK;
wire       sme_remask    = sme_on && fu_sme && s2_uop==SME_REMASK;
wire       sme_maskop    = sme_mask || sme_unmask || sme_remask;

wire       alu_nonlinear_op = alu_op_and || alu_op_andn ||
                              alu_op_or  || alu_op_orn  ;

wire       sme_wb_result =
    sme_maskop ||
    sme_on && sme_operands_ok && alu_nonlinear_op;

wire [XL:0]n_s3_opr_a_sme= sme_alu_result;

wire    sme_rs1_is_share = sme_is_share_reg(s2_rs1_addr[4:0]) || sme_maskop;
wire    sme_rs2_is_share = sme_is_share_reg(s2_rs2_addr[4:0]) || sme_maskop;
wire    sme_rd_is_share  = sme_is_share_reg(s2_rd      [4:0]);

wire    sme_operands_ok  =
    sme_rs1_is_share && sme_rd_is_share;

// Do we need to source an SME share for storing to memory?
wire    store_sme_share = sme_on && |smectl_b && 
                         sme_rs2_is_share &&
                         lsu_valid && lsu_store;

assign  sme_input_data.rs1_addr   = {4{sme_on && sme_rs1_is_share}} & s2_rs1_addr[3:0];
assign  sme_input_data.rs2_addr   = {4{sme_on && sme_rs2_is_share}} & s2_rs2_addr[3:0];
assign  sme_input_data.rd_addr    = s2_rd[3:0];

assign  sme_input_data.rs1_rdata  = s2_opr_a ;
assign  sme_input_data.rs2_rdata  = s2_opr_b ;
assign  sme_input_data.shamt      = alu_shamt;

wire    is_sme_alu_op             = 
    alu_op_xor  || alu_op_xnor || alu_op_and  || alu_op_andn   ||
    alu_op_or   || alu_op_orn  || alu_op_sll  || alu_op_srl    ||
    alu_op_ror  || alu_op_rol  || alu_op_add  || alu_op_sub    ||
    sme_maskop  ;

assign  sme_alu_valid             = is_sme_alu_op && sme_on && sme_operands_ok;

// None of these do anything unless sme_alu_valid is also high.
// See inside sme_alu for why/how.
assign  sme_alu_op.op_xor     = alu_op_xor || alu_op_xnor;
assign  sme_alu_op.op_and     = alu_op_and || alu_op_andn;
assign  sme_alu_op.op_or      = alu_op_or  || alu_op_orn ;
assign  sme_alu_op.op_notrs2  = alu_op_xnor|| alu_op_andn || alu_op_orn;
assign  sme_alu_op.op_shift   = alu_op_sll || alu_op_srl ;
assign  sme_alu_op.op_rotate  = alu_op_ror || alu_op_rol ;
assign  sme_alu_op.op_left    = alu_op_sll || alu_op_rol ;
assign  sme_alu_op.op_right   = alu_op_srl || alu_op_ror ; 
assign  sme_alu_op.op_add     = alu_op_add ;
assign  sme_alu_op.op_sub     = alu_op_sub ;
assign  sme_alu_op.op_mask    = sme_mask   ;
assign  sme_alu_op.op_unmask  = sme_unmask ;
assign  sme_alu_op.op_remask  = sme_remask ;

//
// Crypto SME stuff

wire    is_sme_cry_op             = 
    cry_op_saes32_encs  || cry_op_saes32_encsm  ||
    cry_op_saes32_decs  || cry_op_saes32_decsm  ;

assign sme_cry_valid          = is_sme_cry_op && sme_on && sme_operands_ok;

assign sme_cry_op.bs          = cry_bs[1:0]         ;
assign sme_cry_op.op_aeses    = cry_op_saes32_encs  ;
assign sme_cry_op.op_aesesm   = cry_op_saes32_encsm ;
assign sme_cry_op.op_aesds    = cry_op_saes32_decs  ;
assign sme_cry_op.op_aesdsm   = cry_op_saes32_decsm ;

//
// SME based Stalling

wire    sme_busy    = sme_alu_valid && !sme_alu_ready ||
                      sme_cry_valid && !sme_cry_ready ;


//
// Functional Unit Interfacing: LSU
// -------------------------------------------------------------------------

wire        lsu_valid  = fu_lsu         ; // Inputs are valid.
wire        lsu_a_error= 1'b0           ; // Address error. TODO
wire        lsu_ready  = lsu_valid      ; // Load/Store instruction complete.

wire        lsu_load   = fu_lsu && s2_uop[LSU_LOAD ];
wire        lsu_store  = fu_lsu && s2_uop[LSU_STORE];

wire [XL:0] n_s3_opr_a_lsu = alu_add_out     ;
wire [XL:0] n_s3_opr_b_lsu = store_sme_share ? sme_bank_rdata : s2_opr_c ;

//
// Functional Unit Interfacing: CFU
// -------------------------------------------------------------------------

wire        cfu_valid   = fu_cfu        ; // Inputs are valid.
wire        cfu_ready   = cfu_valid     ; // Instruction complete.

wire        cfu_cond    = cfu_valid && s2_uop[OP:OP-1] == 2'b00;
wire        cfu_uncond  = cfu_valid && s2_uop[OP:OP-1] == 2'b10;
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
    cond_beq  &&  alu_cmp_eq    ||
    cond_bge  && !alu_cmp_lt    ||  // Same signal for (un)signed inputs.
    cond_bgeu && !alu_cmp_ltu   ||  // - see alu_op_unsigned signal.
    cond_blt  &&  alu_cmp_lt    ||
    cond_bltu &&  alu_cmp_ltu   ||
    cond_bne  && !alu_cmp_eq    ;

wire        cfu_always_take= cfu_jalr || cfu_jali || cfu_jalr;

wire [OP:0]  n_s3_uop_cfu   =
    cfu_cond        ? (cfu_cond_taken ? CFU_TAKEN : CFU_NOT_TAKEN)  :
    cfu_always_take ? s2_uop                                        :
                      s2_uop                                        ;

wire [XL:0] n_s3_opr_a_cfu = 
    cfu_jalr    ? {alu_add_out   [XL:1],1'b0} :
                  {s2_opr_c      [XL:1],1'b0} ;

wire [XL:0] n_s3_opr_b_cfu = 32'b0;

//
// Functional Unit Interfacing: Crypto FU
// -------------------------------------------------------------------------

localparam LUT4_EN         = 1; // Enable lut4 instructions.
localparam SAES_EN         = ZKAES; // Enable saes32/64 instructions.
localparam SAES_DEC_EN     = ZKAES; // Enable saes32/64 decrypt instructions.
localparam SSHA256_EN      = ZKSHA256; // Enable ssha256.* instructions.
localparam SSHA512_EN      = ZKSHA512; // Enable ssha256.* instructions.
localparam SSM3_EN         = ZKSM3; // Enable ssm3.* instructions.
localparam SSM4_EN         = ZKSM4; // Enable ssm4.* instructions.
localparam LOGIC_GATING    = 1; // Gate sub-module inputs to save toggling

wire        cry_valid      = fu_cry         ; // Inputs valid.
wire [XL:0] cry_rs1        = s2_opr_a       ; // Source register 1
wire [XL:0] cry_rs2        = s2_opr_b       ; // Source register 2
wire [ 3:0] cry_bs         = {2'b00,s2_uop[OP:OP-1]}; // bs for saes32.
wire [OP:0] cry_uop        = {2'b00, s2_uop[OP-2:0]};

wire cry_op_lut4lo        = 1'b0                                 ;
wire cry_op_lut4hi        = 1'b0                                 ;
wire cry_op_saes32_encs   = fu_cry && cry_uop == CRY_SAES32_ENCS  && ZKAES;
wire cry_op_saes32_encsm  = fu_cry && cry_uop == CRY_SAES32_ENCSM && ZKAES;
wire cry_op_saes32_decs   = fu_cry && cry_uop == CRY_SAES32_DECS  && ZKAES;
wire cry_op_saes32_decsm  = fu_cry && cry_uop == CRY_SAES32_DECSM && ZKAES;
wire cry_op_ssm4_ks       = fu_cry && cry_uop == CRY_SSM4_KS      && ZKSM4;
wire cry_op_ssm4_ed       = fu_cry && cry_uop == CRY_SSM4_ED      && ZKSM4;
wire cry_op_ssha256_sig0  = fu_cry && s2_uop == CRY_SSHA256_SIG0  && ZKSHA256;
wire cry_op_ssha256_sig1  = fu_cry && s2_uop == CRY_SSHA256_SIG1  && ZKSHA256;
wire cry_op_ssha256_sum0  = fu_cry && s2_uop == CRY_SSHA256_SUM0  && ZKSHA256;
wire cry_op_ssha256_sum1  = fu_cry && s2_uop == CRY_SSHA256_SUM1  && ZKSHA256;
wire cry_op_ssha512_sum0r = fu_cry && s2_uop == CRY_SSHA512_SUM0R && ZKSHA512;
wire cry_op_ssha512_sum1r = fu_cry && s2_uop == CRY_SSHA512_SUM1R && ZKSHA512;
wire cry_op_ssha512_sig0l = fu_cry && s2_uop == CRY_SSHA512_SIG0L && ZKSHA512;
wire cry_op_ssha512_sig0h = fu_cry && s2_uop == CRY_SSHA512_SIG0H && ZKSHA512;
wire cry_op_ssha512_sig1l = fu_cry && s2_uop == CRY_SSHA512_SIG1L && ZKSHA512;
wire cry_op_ssha512_sig1h = fu_cry && s2_uop == CRY_SSHA512_SIG1H && ZKSHA512;
wire cry_op_ssm3_p0       = fu_cry && s2_uop == CRY_SSM3_P0       && ZKSM3;
wire cry_op_ssm3_p1       = fu_cry && s2_uop == CRY_SSM3_P1       && ZKSM3;

wire        cry_ready            ; // Outputs ready.
wire [XL:0] cry_rd               ;

wire [XL:0] n_s3_opr_a_cry       = sme_cry_valid ? sme_cry_result : cry_rd;
wire [XL:0] n_s3_opr_b_cry       = {XLEN{1'b0}};

//
// Functional Unit Interfacing: CSR
// -------------------------------------------------------------------------

wire        csr_valid  = fu_csr         ; // Inputs are valid.
wire        csr_ready  = csr_valid      ; // Instruction complete.

wire [XL:0] n_s3_opr_a_csr = s2_opr_a;
wire [XL:0] n_s3_opr_b_csr = s2_opr_c;

//
// Stalling / Pipeline Progression
// -------------------------------------------------------------------------

// Input into pipeline register, which then drives s3_p_valid;
wire   p_valid   = s2_valid && !s2_busy;

// Is this stage currently busy?
assign s2_busy = p_busy                    ||
                 sme_busy                  ||
                 lsu_valid  && !lsu_ready  ||
                 cry_valid  && !cry_ready  ||
                 imul_valid && !imul_ready ;

// Is the next stage currently busy?
wire   p_busy    ;

//
// Submodule instances
// -------------------------------------------------------------------------

frv_alu i_alu (
.opr_a      (alu_opr_a      ), // Input operand A
.opr_b      (alu_opr_b      ), // Input operand B
.shamt      (alu_shamt      ), // Shift amount.
.op_add     (alu_op_add     ), // Select output of adder
.op_sub     (alu_op_sub     ), // Subtract opr_a from opr_b else add
.op_xor     (alu_op_xor     ), // Select XOR operation result
.op_or      (alu_op_or      ), // Select OR
.op_and     (alu_op_and     ), //        AND
.op_xnor    (alu_op_xnor    ), // XNOR
.op_orn     (alu_op_orn     ), // OR-Not
.op_andn    (alu_op_andn    ), // AND-Not
.op_slt     (alu_op_slt     ), // Set less than
.op_sltu    (alu_op_sltu    ), //                Unsigned
.op_srl     (alu_op_srl     ), // Shift right logical
.op_sll     (alu_op_sll     ), // Shift left logical
.op_sra     (alu_op_sra     ), // Shift right arithmetic
.op_ror     (alu_op_ror     ), // Rotate right
.op_rol     (alu_op_rol     ), // "      Left
.op_pack    (alu_op_pack    ), // Pack
.op_packh   (alu_op_packh   ), // "
.op_packu   (alu_op_packu   ), // "
.op_grev    (alu_op_grev    ), // Generalized reverse
.op_shfl    (alu_op_shfl    ), // Shuffle
.op_unshfl  (alu_op_unshfl  ), // Unshuffle
.op_clz     (alu_op_clz     ), // Count leading zeros
.op_ctz     (alu_op_ctz     ), // Count trailing zeros
.op_gorc    (alu_op_gorc    ), // Generalised OR combine
.op_max     (alu_op_max     ), // Max
.op_maxu    (alu_op_maxu    ), // Max (unsigned)
.op_min     (alu_op_min     ), // Min
.op_minu    (alu_op_minu    ), // Min (unsigned)
.op_pcnt    (alu_op_pcnt    ), // Popcount
.op_sextb   (alu_op_sextb   ), // Sign extend byte
.op_sexth   (alu_op_sexth   ), // Sign extend halfword
.op_slo     (alu_op_slo     ), // Shift left ones
.op_sro     (alu_op_sro     ), // Shift right ones.
.op_xpermn  (alu_op_xpermn  ), // Crossbar permutation: Nibbles
.op_xpermb  (alu_op_xpermb  ), // Crossbar permutation: Bytes
.add_out    (alu_add_out    ), // Result of adding opr_a and opr_b
.cmp_eq     (alu_cmp_eq     ), // Result of opr_a == opr_b
.cmp_lt     (alu_cmp_lt     ), // Result of opr_a <  opr_b
.cmp_ltu    (alu_cmp_ltu    ), // Result of opr_a <  opr_b
.result     (alu_result     )  // Operation result
);

frv_mdu i_frv_mdu (
.g_clk      (g_clk          ), // Clock
.g_clk_req  (imul_clk_req   ), // Clock Request
.g_resetn   (g_resetn       ), // Active low synchronous reset.
.flush      (imul_flush     ), // Flush and stop any execution.
.valid      (imul_valid     ), // Inputs are valid.
.op_mul     (imul_op_mul    ), //
.op_mulh    (imul_op_mulh   ), //
.op_mulhu   (imul_op_mulhu  ), //
.op_mulhsu  (imul_op_mulhsu ), //
.op_div     (imul_op_div    ), //
.op_divu    (imul_op_divu   ), //
.op_rem     (imul_op_rem    ), //
.op_remu    (imul_op_remu   ), //
.op_clmul   (imul_op_clmul  ), //
.op_clmulh  (imul_op_clmulh ), //
.op_clmulr  (imul_op_clmulr ), //
.rs1        (imul_rs1       ), // Source register 1
.rs2        (imul_rs2       ), // Source register 2
.ready      (imul_ready     ), // Finished computing
.rd         (imul_rd        )  // Result
);


riscv_crypto_fu #(
.XLEN           (XLEN           ),
.LUT4_EN        (LUT4_EN        ), // Enable lut4 instructions.
.SAES_EN        (SAES_EN        ), // Enable saes32/64 instructions.
.SAES_DEC_EN    (SAES_DEC_EN    ), // Enable saes32/64 decrypt instructions.
.SSHA256_EN     (SSHA256_EN     ), // Enable ssha256.* instructions.
.SSHA512_EN     (SSHA512_EN     ), // Enable ssha256.* instructions.
.SSM3_EN        (SSM3_EN        ), // Enable ssm3.* instructions.
.SSM4_EN        (SSM4_EN        ), // Enable ssm4.* instructions.
.COMBINE_AES_SM4(COMBINE_AES_SM4), // Enable combined RV32 AES/SM4 module.
.LOGIC_GATING   (LOGIC_GATING   )  // Gate sub-module inputs to save toggling
) i_frv_crypto (
.g_clk           (g_clk               ), // Global clock
.g_resetn        (g_resetn            ), // Synchronous active low reset.
.valid           (cry_valid           ), // Inputs valid.
.rs1             (cry_rs1             ), // Source register 1
.rs2             (cry_rs2             ), // Source register 2
.imm             (cry_bs              ), // bs, enc_rcon for aes32/64.
.op_lut4lo       (cry_op_lut4lo       ), // RV32 lut4-lo instruction
.op_lut4hi       (cry_op_lut4hi       ), // RV32 lut4-hi instruction
.op_saes32_encs  (cry_op_saes32_encs  ), // RV32 AES Encrypt SBox
.op_saes32_encsm (cry_op_saes32_encsm ), // RV32 AES Encrypt SBox + MixCols
.op_saes32_decs  (cry_op_saes32_decs  ), // RV32 AES Decrypt SBox
.op_saes32_decsm (cry_op_saes32_decsm ), // RV32 AES Decrypt SBox + MixCols
.op_ssha256_sig0 (cry_op_ssha256_sig0 ), //      SHA256 Sigma 0
.op_ssha256_sig1 (cry_op_ssha256_sig1 ), //      SHA256 Sigma 1
.op_ssha256_sum0 (cry_op_ssha256_sum0 ), //      SHA256 Sum 0
.op_ssha256_sum1 (cry_op_ssha256_sum1 ), //      SHA256 Sum 1
.op_ssha512_sum0r(cry_op_ssha512_sum0r), // RV32 SHA512 Sum 0
.op_ssha512_sum1r(cry_op_ssha512_sum1r), // RV32 SHA512 Sum 1
.op_ssha512_sig0l(cry_op_ssha512_sig0l), // RV32 SHA512 Sigma 0 low
.op_ssha512_sig0h(cry_op_ssha512_sig0h), // RV32 SHA512 Sigma 0 high
.op_ssha512_sig1l(cry_op_ssha512_sig1l), // RV32 SHA512 Sigma 1 low
.op_ssha512_sig1h(cry_op_ssha512_sig1h), // RV32 SHA512 Sigma 1 high
.op_ssm3_p0      (cry_op_ssm3_p0      ), //      SSM3 P0
.op_ssm3_p1      (cry_op_ssm3_p1      ), //      SSM3 P1
.op_ssm4_ks      (cry_op_ssm4_ks      ), //      SSM4 KeySchedule
.op_ssm4_ed      (cry_op_ssm4_ed      ), //      SSM4 Encrypt/Decrypt
.ready           (cry_ready           ), // Outputs ready.
.rd              (cry_rd              )
);


//
// Pipeline Register
// -------------------------------------------------------------------------

localparam RL = 10 + 42 + OP + FU;

wire [ 4:0] n_s3_rd    = s2_rd   ; // Functional Unit
wire [FU:0] n_s3_fu    = s2_fu   ; // Functional Unit
wire [ 1:0] n_s3_size  = s2_size ; // Size of the instruction.
wire [31:0] n_s3_instr = s2_instr; // The instruction word

wire [OP:0] n_s3_uop   = cfu_valid ? n_s3_uop_cfu : s2_uop  ; // Micro-op code

wire        n_s3_trap  = s2_trap || 
                         fu_lsu && (lsu_a_error);

wire [5:0]  n_trap_cause =
    s2_trap                             ? {1'b0, s2_rd} :
    fu_lsu && lsu_a_error && lsu_load   ? TRAP_LDALIGN  :
    fu_lsu && lsu_a_error && lsu_store  ? TRAP_STALIGN  :
                                          6'b0          ;

wire [XL:0] n_s3_opr_a =  sme_wb_result ? n_s3_opr_a_sme :
    {XLEN{fu_alu}} & n_s3_opr_a_alu |
    {XLEN{fu_mul}} & n_s3_opr_a_mul |
    {XLEN{fu_lsu}} & n_s3_opr_a_lsu |
    {XLEN{fu_cfu}} & n_s3_opr_a_cfu |
    {XLEN{fu_csr}} & n_s3_opr_a_csr |
    {XLEN{fu_cry}} & n_s3_opr_a_cry ;

wire [XL:0] n_s3_opr_b =
    n_s3_trap ? {26'b0,n_trap_cause} : (
        {XLEN{fu_alu}} & n_s3_opr_b_alu |
        {XLEN{fu_mul}} & n_s3_opr_b_mul |
        {XLEN{fu_lsu}} & n_s3_opr_b_lsu |
        {XLEN{fu_cfu}} & n_s3_opr_b_cfu |
        {XLEN{fu_csr}} & n_s3_opr_b_csr 
    );

wire opra_ld_en = p_valid && (
    fu_alu || fu_mul || fu_lsu || fu_cfu || fu_csr || fu_cry || fu_sme
); 

wire oprb_ld_en = p_valid && (
    (fu_lsu && lsu_store    )  ||
     fu_csr                    ); 

// Forwaring / bubbling signals.
assign fwd_s2_rd    = s2_rd             ; // Writeback stage destination reg.
assign fwd_s2_wdata = n_s3_opr_a;
assign fwd_s2_load  = fu_lsu && lsu_load; // Writeback stage has load in it.
assign fwd_s2_csr   = fu_csr            ; // Writeback stage has CSR op in it.


wire [RL-1:0] pipe_reg_out;

wire [RL-1:0] pipe_reg_in = {
    n_s3_rd           , // Destination register address
    n_s3_uop          , // Micro-op code
    n_s3_fu           , // Functional Unit
    n_s3_trap         , // Raise a trap?
    n_s3_size         , // Size of the instruction.
    n_s3_instr        , // The instruction word
    s2_rs1_addr       , 
    s2_rs2_addr
};


assign {
    s3_rd             , // Destination register address
    s3_uop            , // Micro-op code
    s3_fu             , // Functional Unit
    s3_trap           , // Raise a trap?
    s3_size           , // Size of the instruction.
    s3_instr          , // The instruction word
    s3_rs1_addr       , 
    s3_rs2_addr
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
.flush    (1'b0             ), // Flush the contents of the pipeline
.flush_dat(32'b0            ), // Data flushed into the pipeline.
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
.flush    (1'b0             ), // Flush the contents of the pipeline
.flush_dat(32'b0            ), // Data flushed into the pipeline.
.o_data   (s3_opr_b         ), // Output data for stage N+1
.o_valid  (                 ), // Input data from stage N valid?
.i_busy   (s3_busy          )  // Stage N+1 ready to continue?
);


//
// RISC-V Formal
// -------------------------------------------------------------------------

`ifdef RVFI

// Only use aux signal to carry EX stage aligned uxcrypto content for now.
wire [XL:0] n_rvfi_s3_aux = 32'b0;

always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        rvfi_s3_rs1_rdata <= 0; // Source register data 1
        rvfi_s3_rs2_rdata <= 0; // Source register data 2
        rvfi_s3_rs1_addr  <= 0; // Source register address 1
        rvfi_s3_rs2_addr  <= 0; // Source register address 2
        rvfi_s3_aux       <= 0; // Auxiliary data
    end else if(pipe_progress) begin
        rvfi_s3_rs1_rdata <= rvfi_s2_rs1_rdata;
        rvfi_s3_rs2_rdata <= rvfi_s2_rs2_rdata;
        rvfi_s3_rs1_addr  <= rvfi_s2_rs1_addr ;
        rvfi_s3_rs2_addr  <= rvfi_s2_rs2_addr ;
        rvfi_s3_aux       <= n_rvfi_s3_aux    ;
    end
end

`endif

endmodule

