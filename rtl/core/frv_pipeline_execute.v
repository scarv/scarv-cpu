
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

output wire [ 4:0] fwd_s3_rd       , // Writeback stage destination reg.
output wire [XL:0] fwd_s3_wdata    , // Write data for writeback stage.
output wire        fwd_s3_load     , // Writeback stage has load in it.
output wire        fwd_s3_csr      , // Writeback stage has CSR op in it.

`ifdef RVFI
input  wire [XL:0] rvfi_s3_rs1_rdata, // Source register data 1
input  wire [XL:0] rvfi_s3_rs2_rdata, // Source register data 2
input  wire [ 4:0] rvfi_s3_rs1_addr , // Source register address 1
input  wire [ 4:0] rvfi_s3_rs2_addr , // Source register address 2
output reg  [XL:0] rvfi_s4_rs1_rdata, // Source register data 1
output reg  [XL:0] rvfi_s4_rs2_rdata, // Source register data 2
output reg  [ 4:0] rvfi_s4_rs1_addr , // Source register address 1
output reg  [ 4:0] rvfi_s4_rs2_addr , // Source register address 2
`endif

output wire [ 4:0] s4_rd           , // Destination register address
output wire [XL:0] s4_opr_a        , // Operand A
output wire [XL:0] s4_opr_b        , // Operand B
output wire [31:0] s4_pc           , // Program counter
output wire [ 4:0] s4_uop          , // Micro-op code
output wire [ 4:0] s4_fu           , // Functional Unit
output wire        s4_trap         , // Raise a trap?
output wire [ 1:0] s4_size         , // Size of the instruction.
output wire [31:0] s4_instr        , // The instruction word
input  wire        s4_p_busy       , // Can this stage accept new inputs?
output wire        s4_p_valid      , // Is this input valid?

input  wire        hold_lsu_req    , // Don't make LSU requests yet.

output wire        dmem_req        , // Start memory request
output wire        dmem_wen        , // Write enable
output wire [3:0]  dmem_strb       , // Write strobe
output wire [XL:0] dmem_wdata      , // Write data
output wire [XL:0] dmem_addr       , // Read/Write address
input  wire        dmem_gnt          // request accepted

);


// Common core parameters and constants
`include "frv_common.vh"

wire pipe_progress = !s3_p_busy && s3_p_valid;

//
// Operation Decoding
// -------------------------------------------------------------------------

wire fu_alu = s3_fu[P_FU_ALU];
wire fu_mul = s3_fu[P_FU_MUL];
wire fu_lsu = s3_fu[P_FU_LSU];
wire fu_cfu = s3_fu[P_FU_CFU];
wire fu_csr = s3_fu[P_FU_CSR];

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
                                         s3_uop == ALU_SLTU )   ||
                              cfu_cond;

wire        alu_op_unsigned = fu_alu && (s3_uop == ALU_SLTU) ||
                              cond_bgeu || cond_bltu        ;

wire        alu_lt                      ; // Is LHS < RHS?
wire        alu_eq                      ; // Is LHS = RHS?
wire [XL:0] alu_add_result              ; // Result of adding LHS,RHS.

wire [XL:0] alu_lhs         = s3_opr_a  ; // left hand operand
wire [XL:0] alu_rhs         = s3_opr_b  ; // right hand operand
wire [XL:0] alu_result                  ; // result of the ALU operation

wire [XL:0] n_s4_opr_a_alu = alu_result;
wire [XL:0] n_s4_opr_b_alu = 32'b0;

//
// Functional Unit Interfacing: Multiplier
// -------------------------------------------------------------------------

wire        imul_valid      = fu_mul;
wire        imul_div        = fu_mul && s3_uop == MUL_DIV   ;
wire        imul_divu       = fu_mul && s3_uop == MUL_DIVU  ;
wire        imul_mul        = fu_mul && s3_uop == MUL_MUL   ;
wire        imul_mulh       = fu_mul && s3_uop == MUL_MULH  ;
wire        imul_mulhsu     = fu_mul && s3_uop == MUL_MULHSU;
wire        imul_mulhu      = fu_mul && s3_uop == MUL_MULHU ;
wire        imul_rem        = fu_mul && s3_uop == MUL_REM   ;
wire        imul_remu       = fu_mul && s3_uop == MUL_REMU  ;

wire [31:0] imul_lhs        = s3_opr_a;
wire [31:0] imul_rhs        = s3_opr_b;

wire        imul_ready      ;
wire [31:0] imul_result     ;

wire [XL:0] n_s4_opr_a_mul  = imul_result;
wire [XL:0] n_s4_opr_b_mul  = 32'b0;

//
// Functional Unit Interfacing: LSU
// -------------------------------------------------------------------------

wire        lsu_valid  = fu_lsu         ; // Inputs are valid.
wire        lsu_a_error                 ; // Address error.
wire        lsu_ready                   ; // Load/Store instruction complete.

wire [XL:0] lsu_addr   = s3_opr_a+s3_opr_b; // Memory address to access.
wire [XL:0] lsu_wdata  = s3_opr_c       ; // Data to write to memory.
wire        lsu_load   = s3_uop[LSU_LOAD]    ;
wire        lsu_store  = s3_uop[LSU_STORE]   ;
wire        lsu_byte   = s3_uop[2:1] == LSU_BYTE;
wire        lsu_half   = s3_uop[2:1] == LSU_HALF;
wire        lsu_word   = s3_uop[2:1] == LSU_WORD;
wire        lsu_signed = s3_uop[LSU_SIGNED]  ;

wire [XL:0] n_s4_opr_a_lsu = {28'b0,dmem_strb};
wire [XL:0] n_s4_opr_b_lsu = lsu_addr  ;

//
// Functional Unit Interfacing: CFU
// -------------------------------------------------------------------------

wire        cfu_valid   = fu_cfu        ; // Inputs are valid.
wire        cfu_ready   = cfu_valid     ; // Instruction complete.

wire        cfu_cond    = cfu_valid && s3_uop[4:3] == 2'b00;
wire        cfu_uncond  = cfu_valid && s3_uop[4:3] == 2'b10;
wire        cfu_jmp     = cfu_valid && s3_uop      == CFU_JMP ;
wire        cfu_jali    = cfu_valid && s3_uop      == CFU_JALI;
wire        cfu_jalr    = cfu_valid && s3_uop      == CFU_JALR;


wire        cond_beq    = cfu_valid && s3_uop == CFU_BEQ ;
wire        cond_bge    = cfu_valid && s3_uop == CFU_BGE ;
wire        cond_bgeu   = cfu_valid && s3_uop == CFU_BGEU;
wire        cond_blt    = cfu_valid && s3_uop == CFU_BLT ;
wire        cond_bltu   = cfu_valid && s3_uop == CFU_BLTU;
wire        cond_bne    = cfu_valid && s3_uop == CFU_BNE ;

wire        cfu_cond_taken =
    cond_beq  &&  alu_eq    ||
    cond_bge  && !alu_lt    ||  // Same signal for (un)signed inputs.
    cond_bgeu && !alu_lt    ||  // - see alu_op_unsigned signal.
    cond_blt  &&  alu_lt    ||
    cond_bltu &&  alu_lt    ||
    cond_bne  && !alu_eq    ;

wire        cfu_always_take= cfu_jalr || cfu_jali || cfu_jalr;

wire [4:0]  n_s4_uop_cfu   =
    cfu_cond        ? (cfu_cond_taken ? CFU_TAKEN : CFU_NOT_TAKEN)  :
    cfu_always_take ? s3_uop                                        :
                      s3_uop                                        ;

wire [XL:0] n_s4_opr_a_cfu = 
    cfu_jalr    ? {alu_add_result[XL:1],1'b0} :
                  {s3_opr_c      [XL:1],1'b0} ;

wire [XL:0] n_s4_opr_b_cfu = 32'b0;

//
// Functional Unit Interfacing: CSR
// -------------------------------------------------------------------------

wire        csr_valid  = fu_csr         ; // Inputs are valid.
wire        csr_ready  = csr_valid      ; // Instruction complete.

wire [XL:0] n_s4_opr_a_csr = s3_opr_a;
wire [XL:0] n_s4_opr_b_csr = s3_opr_c;

//
// Stalling / Pipeline Progression
// -------------------------------------------------------------------------

// Input into pipeline register, which then drives s4_p_valid;
wire   p_valid   = s3_p_valid && !s3_p_busy;

// Is this stage currently busy?
assign s3_p_busy = p_busy                   ||
                   lsu_valid  && !lsu_ready ||
                   imul_valid && !imul_ready;

// Is the next stage currently busy?
wire   p_busy    ;

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
.pipe_prog      (pipe_progress  ), // Pipeline progressing this cycle.
.lsu_a_error    (lsu_a_error    ), // Address error.
.lsu_addr       (lsu_addr       ), // Memory address to access.
.lsu_wdata      (lsu_wdata      ), // Data to write to memory.
.lsu_load       (lsu_load       ), // Load instruction.
.lsu_store      (lsu_store      ), // Store instruction.
.lsu_byte       (lsu_byte       ), // Byte operation width.
.lsu_half       (lsu_half       ), // Halfword operation width.
.lsu_word       (lsu_word       ), // Word operation width.
.lsu_signed     (lsu_signed     ), // Sign extend loaded data?
.hold_lsu_req   (hold_lsu_req   ), // Don't make LSU requests yet.
.dmem_req       (dmem_req       ), // Start memory request
.dmem_wen       (dmem_wen       ), // Write enable
.dmem_strb      (dmem_strb      ), // Write strobe
.dmem_wdata     (dmem_wdata     ), // Write data
.dmem_addr      (dmem_addr      ), // Read/Write address
.dmem_gnt       (dmem_gnt       )  // request accepted
);

frv_alu_muldiv i_alu_muldiv(
.g_clk        (g_clk        ), // Global clock
.g_resetn     (g_resetn     ), // Global negative level triggered reset
.exu_stall    (s3_p_busy    ), // stalled due to other stages
.exu_flush    (flush        ), // should flush everything.
.pipe_progress(pipe_progress), // Pipe is progressing.
.imul_valid   (imul_valid   ), // IMUL instruction / op valid
.imul_mul     (imul_mul     ), // 
.imul_mulh    (imul_mulh    ), // 
.imul_mulhu   (imul_mulhu   ), // 
.imul_mulhsu  (imul_mulhsu  ), // 
.imul_div     (imul_div     ), // 
.imul_divu    (imul_divu    ), // 
.imul_rem     (imul_rem     ), // 
.imul_remu    (imul_remu    ), // 
.imul_lhs     (imul_lhs     ), // Left hand operand
.imul_rhs     (imul_rhs     ), // Left hand operand
.imul_ready   (imul_ready   ), // ready to progress
.imul_result  (imul_result  )  // Result of the IMUL operation.
);

//
// Pipeline Register
// -------------------------------------------------------------------------

localparam PIPE_REG_W = 146;

wire [31:0] n_s4_pc    = s3_pc   ; // Program counter
wire [ 4:0] n_s4_rd    = s3_rd   ; // Functional Unit
wire [ 4:0] n_s4_fu    = s3_fu   ; // Functional Unit
wire [ 1:0] n_s4_size  = s3_size ; // Size of the instruction.
wire [31:0] n_s4_instr = s3_instr; // The instruction word

wire [ 4:0] n_s4_uop   = cfu_valid ? n_s4_uop_cfu : s3_uop  ; // Micro-op code

wire        n_s4_trap  = s3_trap || 
                         fu_lsu && (lsu_a_error);

wire [5:0]  n_trap_cause =
    s3_trap                             ? {1'b0, s3_rd} :
    fu_lsu && lsu_a_error && lsu_load   ? TRAP_LDALIGN  :
    fu_lsu && lsu_a_error && lsu_store  ? TRAP_STALIGN  :
                                          6'b0          ;

wire [XL:0] n_s4_opr_a = 
    {XLEN{fu_alu}} & n_s4_opr_a_alu |
    {XLEN{fu_mul}} & n_s4_opr_a_mul |
    {XLEN{fu_lsu}} & n_s4_opr_a_lsu |
    {XLEN{fu_cfu}} & n_s4_opr_a_cfu |
    {XLEN{fu_csr}} & n_s4_opr_a_csr ;

wire [XL:0] n_s4_opr_b =
    n_s4_trap ? {26'b0,n_trap_cause} : (
        {XLEN{fu_alu}} & n_s4_opr_b_alu |
        {XLEN{fu_mul}} & n_s4_opr_b_mul |
        {XLEN{fu_lsu}} & n_s4_opr_b_lsu |
        {XLEN{fu_cfu}} & n_s4_opr_b_cfu |
        {XLEN{fu_csr}} & n_s4_opr_b_csr 
    );


// Forwaring / bubbling signals.
assign fwd_s3_rd    = s3_rd             ; // Writeback stage destination reg.
assign fwd_s3_wdata = alu_result | imul_result ;
assign fwd_s3_load  = fu_lsu && lsu_load; // Writeback stage has load in it.
assign fwd_s3_csr   = fu_csr            ; // Writeback stage has CSR op in it.


wire [PIPE_REG_W-1:0] pipe_reg_out;

wire [PIPE_REG_W-1:0] pipe_reg_in = {
    n_s4_rd           , // Destination register address
    n_s4_opr_a        , // Operand A
    n_s4_opr_b        , // Operand B
    n_s4_pc           , // Program counter
    n_s4_uop          , // Micro-op code
    n_s4_fu           , // Functional Unit
    n_s4_trap         , // Raise a trap?
    n_s4_size         , // Size of the instruction.
    n_s4_instr          // The instruction word
};


assign {
    s4_rd             , // Destination register address
    s4_opr_a          , // Operand A
    s4_opr_b          , // Operand B
    s4_pc             , // Program counter
    s4_uop            , // Micro-op code
    s4_fu             , // Functional Unit
    s4_trap           , // Raise a trap?
    s4_size           , // Size of the instruction.
    s4_instr            // The instruction word
} = pipe_reg_out;

frv_pipeline_register #(
.RLEN(PIPE_REG_W),
.BUFFER_HANDSHAKE(1'b0)
) i_dispatch_pipe_reg(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (pipe_reg_in      ), // Input data from stage N
.i_valid  (p_valid          ), // Input data valid?
.o_busy   (p_busy           ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Most recent data into the stage.
.flush    (flush            ), // Flush the contents of the pipeline
.o_data   (pipe_reg_out     ), // Output data for stage N+1
.o_valid  (s4_p_valid       ), // Input data from stage N valid?
.i_busy   (s4_p_busy        )  // Stage N+1 ready to continue?
);


//
// RISC-V Formal
// -------------------------------------------------------------------------

`ifdef RVFI

always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        rvfi_s4_rs1_rdata <= 0; // Source register data 1
        rvfi_s4_rs2_rdata <= 0; // Source register data 2
        rvfi_s4_rs1_addr  <= 0; // Source register address 1
        rvfi_s4_rs2_addr  <= 0; // Source register address 2
    end else if(p_valid && !p_busy) begin
        rvfi_s4_rs1_rdata <= rvfi_s3_rs1_rdata;
        rvfi_s4_rs2_rdata <= rvfi_s3_rs2_rdata;
        rvfi_s4_rs1_addr  <= rvfi_s3_rs1_addr ;
        rvfi_s4_rs2_addr  <= rvfi_s3_rs2_addr ;
    end
end

`endif

endmodule

