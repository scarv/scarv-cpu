
//
// module: frv_pipeline_writeback
//
//  Responsible for finalising all instruction writeback behaviour.
//  - Jumps/control flow changes
//  - CSR accesses
//  - GPR writeback.
//
module frv_pipeline_writeback (

input              g_clk           , // global clock
input              g_resetn        , // synchronous reset

input  wire [ 4:0] s4_rd           , // Destination register address
input  wire [XL:0] s4_opr_a        , // Operand A
input  wire [XL:0] s4_opr_b        , // Operand B
input  wire [31:0] s4_pc           , // Program counter
input  wire [ 4:0] s4_uop          , // Micro-op code
input  wire [ 4:0] s4_fu           , // Functional Unit
input  wire        s4_trap         , // Raise a trap?
input  wire [ 1:0] s4_size         , // Size of the instruction.
input  wire [31:0] s4_instr        , // The instruction word
output wire        s4_p_busy       , // Can this stage accept new inputs?
input  wire        s4_p_valid      , // Are the stage inputs valid?

output wire [ 4:0] fwd_s4_rd       , // Writeback stage destination reg.
output wire [XL:0] fwd_s4_wdata    , // Write data for writeback stage.
output wire        fwd_s4_load     , // Writeback stage has load in it.
output wire        fwd_s4_csr      , // Writeback stage has CSR op in it.

output wire        gpr_wen         , // GPR write enable.
output wire [ 4:0] gpr_rd          , // GPR destination register.
output wire [XL:0] gpr_wdata       , // GPR write data.

output wire        trap_cpu        , // A trap occured due to CPU
output wire        trap_int        , // A trap occured due to interrupt
output wire [ 5:0] trap_cause      , // A trap occured due to interrupt
output wire [XL:0] trap_mtval      , // Value associated with the trap.
output wire [XL:0] trap_pc         , // PC value associated with the trap.

input  wire [XL:0] csr_mepc        ,
input  wire [XL:0] csr_mtvec       ,

output wire [XL:0] trs_pc          , // Trace program counter.
output wire [31:0] trs_instr       , // Trace instruction.
output wire        trs_valid       , // Trace output valid.

output wire        csr_en          , // CSR Access Enable
output wire        csr_wr          , // CSR Write Enable
output wire        csr_wr_set      , // CSR Write - Set
output wire        csr_wr_clr      , // CSR Write - Clear
output wire [11:0] csr_addr        , // Address of the CSR to access.
output wire [XL:0] csr_wdata       , // Data to be written to a CSR
input  wire [XL:0] csr_rdata       , // CSR read data

output wire        cf_req          , // Control flow change request
output wire [XL:0] cf_target       , // Control flow change target
input  wire        cf_ack            // Control flow change acknowledge.

);


// Common core parameters and constants
`include "frv_common.vh"

wire  pipe_progress = s4_p_valid && !s4_p_busy;

assign s4_p_busy = fu_cfu ? cfu_busy    : 1'b0;

//
// Operation Decoding
// -------------------------------------------------------------------------

wire fu_alu = s4_fu[P_FU_ALU];
wire fu_mul = s4_fu[P_FU_MUL];
wire fu_lsu = s4_fu[P_FU_LSU];
wire fu_cfu = s4_fu[P_FU_CFU];
wire fu_csr = s4_fu[P_FU_CSR];

//
// Functional Unit: ALU
// -------------------------------------------------------------------------

wire        alu_gpr_wen     = fu_alu;
wire [XL:0] alu_gpr_wdata   = s4_opr_a;

//
// Functional Unit: LSU
// -------------------------------------------------------------------------

wire        lsu_gpr_wen     = fu_lsu && s4_uop[LSU_LOAD];
wire [XL:0] lsu_gpr_wdata   = s4_opr_a;

//
// Functional Unit: CSR
// -------------------------------------------------------------------------

assign      csr_en          = fu_csr;
assign      csr_wr          = fu_csr && s4_uop[CSR_WRITE];
assign      csr_wr_set      = fu_csr && s4_uop[CSR_SET  ];
assign      csr_wr_clr      = fu_csr && s4_uop[CSR_CLEAR];
assign      csr_addr        = s4_opr_b[11:0];
assign      csr_wdata       = s4_opr_a;

wire        csr_gpr_wen     = fu_csr && s4_uop[CSR_READ];
wire [XL:0] csr_gpr_wdata   = csr_rdata;

//
// Functional Unit: CFU
// -------------------------------------------------------------------------

wire cfu_cf_taken   = fu_cfu &&  s4_uop == CFU_TAKEN;
wire cfu_trap       = fu_cfu && (s4_uop == CFU_EBREAK || s4_uop == CFU_ECALL);
wire cfu_mret       = fu_cfu &&  s4_uop == CFU_MRET;

wire cfu_tgt_trap   = cfu_trap || s4_trap;

assign cf_req       = cfu_cf_taken || cfu_trap || cfu_mret || s4_trap;

// CFU operation finishing this cycle.
wire cfu_finish_now = cf_req && cf_ack;

assign cf_target    = 
    {XLEN{cfu_cf_taken}}  & s4_opr_a  |
    {XLEN{cfu_tgt_trap}}  & csr_mtvec |
    {XLEN{cfu_mret    }}  & csr_mepc  ;

// CFU operation finished, but pipeline still stalled.
reg     cfu_done;
wire    n_cfu_done = !pipe_progress && (cfu_done || cfu_finish_now) ;

// The CFU operation is complete and the pipeline can progress.
wire    cfu_busy = fu_cfu && 
                   !(cfu_done || cfu_finish_now) &&
                   (cfu_cf_taken ||cfu_trap || cfu_mret);

always @(posedge g_clk) if(!g_resetn) begin
    cfu_done <= 1'b0;
end else begin
    cfu_done <= n_cfu_done;
end

wire cfu_gpr_wen = fu_cfu && (s4_uop == CFU_JALI || s4_uop == CFU_JALR);

wire [XL:0] cfu_gpr_wdata = s4_opr_b;

//
// GPR writeback and forwarding
// -------------------------------------------------------------------------

assign gpr_rd   = s4_rd;

assign gpr_wen  = csr_gpr_wen || alu_gpr_wen || lsu_gpr_wen || cfu_gpr_wen;

assign gpr_wdata= {32{csr_gpr_wen}} & csr_gpr_wdata |
                  {32{alu_gpr_wen}} & alu_gpr_wdata |
                  {32{lsu_gpr_wen}} & lsu_gpr_wdata |
                  {32{cfu_gpr_wen}} & cfu_gpr_wdata ;

assign fwd_s4_rd    = gpr_rd;
assign fwd_s4_wdata = gpr_wdata;
assign fwd_s4_load  = 1'b0;
assign fwd_s4_csr   = fu_csr;

//
// It's a trap!
// -------------------------------------------------------------------------

assign trap_cpu   = 1'b0    ; // A trap occured due to CPU
assign trap_int   = s4_trap ; // A trap occured due to interrupt
assign trap_cause = 0       ; // Cause of the trap.
assign trap_mtval = 32'b0   ; // Value associated with the trap.
assign trap_pc    = s4_pc   ; // PC value associated with the trap.

//
// Instruction Tracing
// -------------------------------------------------------------------------

assign trs_pc   = s4_pc;
assign trs_instr= s4_instr;
assign trs_valid= s4_p_valid && !s4_p_busy || (cfu_trap || cfu_mret);

endmodule
