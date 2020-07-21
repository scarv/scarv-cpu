
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
input  wire        s2_trap         , // Raise a trap?
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word
output wire        s2_busy         , // Can this stage accept new inputs?
input  wire        s2_valid        , // Is this input valid?

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
// Operation Decoding
// -------------------------------------------------------------------------

wire fu_alu = s2_fu[P_FU_ALU];
wire fu_mul = s2_fu[P_FU_MUL];
wire fu_lsu = s2_fu[P_FU_LSU];
wire fu_cfu = s2_fu[P_FU_CFU];
wire fu_csr = s2_fu[P_FU_CSR];

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

wire        alu_op_sll      = fu_alu && s2_uop == ALU_SLL   ;
wire        alu_op_srl      = fu_alu && s2_uop == ALU_SRL   ;
wire        alu_op_sra      = fu_alu && s2_uop == ALU_SRA   ;

wire        alu_op_slt      = fu_alu && s2_uop == ALU_SLT   ;
wire        alu_op_sltu     = fu_alu && s2_uop == ALU_SLTU  ;

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
wire [XL:0] imul_rs1        = s2_opr_a; // Source register 1
wire [XL:0] imul_rs2        = s2_opr_b; // Source register 2

wire [XL:0] imul_rd         ;
wire [XL:0] n_s3_opr_a_mul  = imul_rd;
wire [XL:0] n_s3_opr_b_mul  = 32'b0;

//
// Functional Unit Interfacing: LSU
// -------------------------------------------------------------------------

wire        lsu_valid  = fu_lsu         ; // Inputs are valid.
wire        lsu_a_error= 1'b0           ; // Address error. TODO
wire        lsu_ready  = lsu_valid      ; // Load/Store instruction complete.

wire        lsu_load   = fu_lsu && s2_uop[LSU_LOAD ];
wire        lsu_store  = fu_lsu && s2_uop[LSU_STORE];

wire [XL:0] n_s3_opr_a_lsu = alu_add_out    ;
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
    cond_beq  &&  alu_cmp_eq    ||
    cond_bge  && !alu_cmp_lt    ||  // Same signal for (un)signed inputs.
    cond_bgeu && !alu_cmp_ltu   ||  // - see alu_op_unsigned signal.
    cond_blt  &&  alu_cmp_lt    ||
    cond_bltu &&  alu_cmp_ltu   ||
    cond_bne  && !alu_cmp_eq    ;

wire        cfu_always_take= cfu_jalr || cfu_jali || cfu_jalr;

wire [4:0]  n_s3_uop_cfu   =
    cfu_cond        ? (cfu_cond_taken ? CFU_TAKEN : CFU_NOT_TAKEN)  :
    cfu_always_take ? s2_uop                                        :
                      s2_uop                                        ;

wire [XL:0] n_s3_opr_a_cfu = 
    cfu_jalr    ? {alu_add_out   [XL:1],1'b0} :
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
// Stalling / Pipeline Progression
// -------------------------------------------------------------------------

// Input into pipeline register, which then drives s3_p_valid;
wire   p_valid   = s2_valid && !s2_busy;

// Is this stage currently busy?
assign s2_busy = p_busy                    ||
                 lsu_valid  && !lsu_ready  ||
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
.op_slt     (alu_op_slt     ), // Set less than
.op_sltu    (alu_op_sltu    ), //                Unsigned
.op_srl     (alu_op_srl     ), // Shift right logical
.op_sll     (alu_op_sll     ), // Shift left logical
.op_sra     (alu_op_sra     ), // Shift right arithmetic
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
.rs1        (imul_rs1       ), // Source register 1
.rs2        (imul_rs2       ), // Source register 2
.ready      (imul_ready     ), // Finished computing
.rd         (imul_rd        )  // Result
);


//
// Pipeline Register
// -------------------------------------------------------------------------

localparam RL = 42 + OP + FU;

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

wire opra_ld_en = p_valid && (
    fu_alu || fu_mul || fu_lsu || fu_cfu || fu_csr 
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

