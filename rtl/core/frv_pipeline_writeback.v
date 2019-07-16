
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

output wire        gpr_wen         , // GPR write enable.
output wire [ 4:0] gpr_rd          , // GPR destination register.
output wire [XL:0] gpr_wdata       , // GPR write data.

output wire        trap_cpu        , // A trap occured due to CPU
output wire        trap_int        , // A trap occured due to interrupt
output wire [ 5:0] trap_cause      , // A trap occured due to interrupt
output wire [XL:0] trap_mtval      , // Value associated with the trap.
output wire [XL:0] trap_pc         , // PC value associated with the trap.

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
// Functional Unit: CSR
// -------------------------------------------------------------------------

wire [XL:0] csr_mepc = 32'b0;
wire [XL:0] csr_mtvec= 32'b0;

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
wire    cfu_busy = fu_cfu && !(cfu_done || cfu_finish_now);

always @(posedge g_clk) if(!g_resetn) begin
    cfu_done <= 1'b0;
end else begin
    cfu_done <= n_cfu_done;
end

//
// GPR writeback
// -------------------------------------------------------------------------

assign gpr_rd   = s4_rd;
assign gpr_wen  = 1'b0;
assign gpr_wdata= s4_opr_a;

//
// It's a trap!
// -------------------------------------------------------------------------

assign trap_cpu   = 1'b0    ; // A trap occured due to CPU
assign trap_int   = s4_trap ; // A trap occured due to interrupt
assign trap_cause = 0       ; // Cause of the trap.
assign trap_mtval = 32'b0   ; // Value associated with the trap.
assign trap_pc    = s4_pc   ; // PC value associated with the trap.

endmodule
