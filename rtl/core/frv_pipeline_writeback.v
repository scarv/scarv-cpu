
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

input  wire [31:0] s3_pc           , // Next Program counter (for JAL[R])

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

output wire        exec_mret       , // MRET instruction executed.

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
input  wire        cf_ack          , // Control flow change acknowledge.

input  wire        dmem_recv       , // Instruction memory recieve response.
output wire        dmem_ack        , // Data memory ack response.
input  wire        dmem_error      , // Error
input  wire [XL:0] dmem_rdata        // Read data

);


// Common core parameters and constants
`include "frv_common.vh"

wire  pipe_progress = s4_p_valid && !s4_p_busy;

assign s4_p_busy = fu_cfu && cfu_busy ||
                   fu_lsu && lsu_busy ;

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
// Functional Unit: MUL
// -------------------------------------------------------------------------

wire        mul_gpr_wen     = fu_mul;
wire [XL:0] mul_gpr_wdata   = s4_opr_a;

//
// Functional Unit: CSR
// -------------------------------------------------------------------------

reg csr_done;

wire n_csr_done = !pipe_progress && (csr_done || csr_en);

always @(posedge g_clk) begin
    if(!g_resetn) begin
        csr_done <= 1'b0;
    end else begin
        csr_done <= n_csr_done;
    end
end

assign      csr_en          = fu_csr && !csr_done;
assign      csr_wr          = fu_csr && s4_uop[CSR_WRITE];
assign      csr_wr_set      = fu_csr && s4_uop[CSR_SET  ];
assign      csr_wr_clr      = fu_csr && s4_uop[CSR_CLEAR];
assign      csr_addr        = s4_opr_b[11:0];
assign      csr_wdata       = s4_opr_a;

wire        csr_read        = fu_csr && s4_uop[CSR_READ];

wire        csr_gpr_wen     = csr_read && !csr_done;
wire [XL:0] csr_gpr_wdata   = csr_rdata;

//
// Functional Unit: CFU
// -------------------------------------------------------------------------

wire cfu_cf_taken   = fu_cfu && (s4_uop == CFU_TAKEN  ||
                                 s4_uop == CFU_JALI   ||
                                 s4_uop == CFU_JALR   );

wire cfu_ebreak     = fu_cfu && s4_uop == CFU_EBREAK;
wire cfu_ecall      = fu_cfu && s4_uop == CFU_ECALL;

wire cfu_trap       = cfu_ebreak || cfu_ecall;
wire cfu_mret       = fu_cfu &&  s4_uop == CFU_MRET;

assign exec_mret    = cfu_mret && pipe_progress;

wire cfu_tgt_trap   = cfu_trap || s4_trap || lsu_trap;

wire cfu_link       = fu_cfu && (s4_uop == CFU_JALI || s4_uop == CFU_JALR);

assign cf_req       = cfu_cf_taken || cfu_trap || cfu_mret || s4_trap ||
                      lsu_trap      ;

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

wire cfu_gpr_wen = cfu_link;

wire [XL:0] cfu_gpr_wdata = s3_pc;


//
// Functional Unit: LSU
// -------------------------------------------------------------------------

wire        lsu_txn_recv    = fu_lsu    && s4_uop[LSU_LOAD] &&
                              dmem_recv && dmem_ack         &&
                              lsu_rsp_expected              ;

wire        n_lsu_rsp_seen  = 
    !pipe_progress && (lsu_rsp_seen || (dmem_recv && dmem_ack));

reg         lsu_rsp_seen;

wire        lsu_rsp_expected= fu_lsu    && !lsu_rsp_seen    ;

assign      dmem_ack    = lsu_rsp_expected;

wire        lsu_gpr_wen     = lsu_txn_recv && !dmem_error;
wire [XL:0] lsu_gpr_wdata   = lsu_rdata;

wire        lsu_load    = s4_uop[LSU_LOAD]    ;
wire        lsu_store   = s4_uop[LSU_STORE]   ;
wire        lsu_byte    = s4_uop[2:1] == LSU_BYTE;
wire        lsu_half    = s4_uop[2:1] == LSU_HALF;
wire        lsu_word    = s4_uop[2:1] == LSU_WORD;
wire        lsu_signed  = s4_uop[LSU_SIGNED]  ;
wire [XL:0] lsu_addr    = s4_opr_b;

wire        lsu_busy    =
    fu_lsu && !(lsu_rsp_seen || (dmem_recv && dmem_ack));

wire [ 7: 0] rdata_b0 =
    {8{lsu_byte && lsu_addr[1:0] == 2'b00}} & dmem_rdata[ 7: 0] |
    {8{lsu_half && lsu_addr[  1] == 1'b0 }} & dmem_rdata[ 7: 0] |
    {8{lsu_word                          }} & dmem_rdata[ 7: 0] |
    {8{lsu_byte && lsu_addr[1:0] == 2'b01}} & dmem_rdata[15: 8] |
    {8{lsu_byte && lsu_addr[1:0] == 2'b10}} & dmem_rdata[23:16] |
    {8{lsu_half && lsu_addr[  1] == 1'b1 }} & dmem_rdata[23:16] |
    {8{lsu_byte && lsu_addr[1:0] == 2'b11}} & dmem_rdata[31:24] ;

wire [ 7: 0] rdata_b1 =
    {8{lsu_byte && lsu_signed            }} & {8{rdata_b0[7] }} |
    {8{lsu_half && lsu_addr[  1] == 1'b0 }} & dmem_rdata[15: 8] |
    {8{lsu_word                          }} & dmem_rdata[15: 8] |
    {8{lsu_half && lsu_addr[  1] == 1'b1 }} & dmem_rdata[31:24] ;

wire [15: 0] rdata_h1 =
    {16{lsu_byte && lsu_signed           }} & {16{rdata_b1[7]}} |
    {16{lsu_half && lsu_signed           }} & {16{rdata_b1[7]}} |
    {16{lsu_word                         }} & dmem_rdata[31:16] ;

//                  31....16,15.....8,7......0
wire [XL:0] lsu_rdata   = {rdata_h1,rdata_b1,rdata_b0};

// LSU Bus error?
wire        lsu_b_error = lsu_rsp_expected && dmem_error;

wire        lsu_trap    = lsu_b_error;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        lsu_rsp_seen <= 1'b0;
    end else begin
        lsu_rsp_seen <= n_lsu_rsp_seen;
    end
end

//
// GPR writeback and forwarding
// -------------------------------------------------------------------------

assign gpr_rd   = s4_rd;

assign gpr_wen  = !s4_trap &&
    (csr_gpr_wen || alu_gpr_wen || lsu_gpr_wen ||
     cfu_gpr_wen || mul_gpr_wen );

assign gpr_wdata= {32{csr_gpr_wen}} & csr_gpr_wdata |
                  {32{alu_gpr_wen}} & alu_gpr_wdata |
                  {32{lsu_gpr_wen}} & lsu_gpr_wdata |
                  {32{cfu_gpr_wen}} & cfu_gpr_wdata |
                  {32{mul_gpr_wen}} & mul_gpr_wdata ;

assign fwd_s4_rd    = gpr_rd;
assign fwd_s4_wdata = gpr_wdata;
assign fwd_s4_load  = lsu_load;
assign fwd_s4_csr   = fu_csr;

//
// It's a trap!
// -------------------------------------------------------------------------

assign trap_cpu   = cfu_trap || lsu_trap;

assign trap_int   = s4_trap ; // A trap occured due to interrupt

assign trap_cause = // Cause of the trap.
    lsu_b_error && lsu_load     ? TRAP_LDACCESS :
    lsu_b_error && lsu_store    ? TRAP_STACCESS :
    cfu_ebreak                  ? TRAP_BREAKPT  :
    cfu_ecall                   ?   TRAP_ECALLM :
                                  s4_opr_a[5:0] ;

assign trap_mtval = 32'b0   ; // Value associated with the trap.

assign trap_pc    = s4_pc   ; // PC value associated with the trap.

//
// Instruction Tracing
// -------------------------------------------------------------------------

assign trs_pc   = s4_pc;
assign trs_instr= s4_instr;
assign trs_valid= |s4_size && s4_p_valid && !s4_p_busy || (cfu_trap || cfu_mret);

endmodule
