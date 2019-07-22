
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
input  wire [ 7:0] s2_opr_src      , // Operand sources for dispatch stage.
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word

output wire        cf_req          , // Control flow change request
output wire [XL:0] cf_target       , // Control flow change target
input  wire        cf_ack          , // Control flow change acknowledge.

output wire        trap_cpu        , // A trap occured due to CPU
output wire        trap_int        , // A trap occured due to interrupt
output wire [ 5:0] trap_cause      , // A trap occured due to interrupt
output wire [XL:0] trap_mtval      , // Value associated with the trap.
output wire [XL:0] trap_pc         , // PC value associated with the trap.

input  wire [XL:0] csr_mepc        ,
input  wire [XL:0] csr_mtvec       ,

output wire        csr_en          , // CSR Access Enable
output wire        csr_wr          , // CSR Write Enable
output wire        csr_wr_set      , // CSR Write - Set
output wire        csr_wr_clr      , // CSR Write - Clear
output wire [11:0] csr_addr        , // Address of the CSR to access.
output wire [XL:0] csr_wdata       , // Data to be written to a CSR
input  wire [XL:0] csr_rdata       , // CSR read data

output wire [XL:0] trs_pc          , // Trace program counter.
output wire [31:0] trs_instr       , // Trace instruction.
output wire        trs_valid       , // Trace output valid.

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

// Use an FPGA BRAM style register file.
parameter BRAM_REGFILE = 0;

//
// Event detection
// -------------------------------------------------------------------------

// A control flow change has completed this cycle.
wire cf_change_now = cf_req && cf_ack;

//
// Inter-stage wiring
// -------------------------------------------------------------------------

wire        flush_dispatch  = cf_change_now;
wire        flush_execute   = cf_change_now;

wire [ 4:0] fwd_s4_rd       ; // Writeback stage destination reg.
wire [XL:0] fwd_s4_wdata    ; // Write data for writeback stage.
wire        fwd_s4_load     ; // Writeback stage has load in it.
wire        fwd_s4_csr      ; // Writeback stage has CSR op in it.

wire [ 4:0] fwd_s3_rd       ; // Writeback stage destination reg.
wire [XL:0] fwd_s3_wdata    ; // Write data for writeback stage.
wire        fwd_s3_load     ; // Writeback stage has load in it.
wire        fwd_s3_csr      ; // Writeback stage has CSR op in it.

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

wire [ 4:0] s4_rd           ; // Destination register address
wire [XL:0] s4_opr_a        ; // Operand A
wire [XL:0] s4_opr_b        ; // Operand B
wire [31:0] s4_pc           ; // Program counter
wire [ 4:0] s4_uop          ; // Micro-op code
wire [ 4:0] s4_fu           ; // Functional Unit
wire        s4_trap         ; // Raise a trap?
wire [ 1:0] s4_size         ; // Size of the instruction.
wire [31:0] s4_instr        ; // The instruction word
wire        s4_p_busy       ; // Can this stage accept new inputs?
wire        s4_p_valid      ; // Is this input valid?

//
// Sub-module instances.
// -------------------------------------------------------------------------

//
// instance: frv_pipeline_dispatch
//
//  Part of the backend, responsible for clearing pipeline bubbles, RAW
//  hazards and gathering operands ready for execution.
//
frv_pipeline_dispatch #(
.BRAM_REGFILE(BRAM_REGFILE)
) i_pipeline_dispatch (
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
.s2_opr_src      (s2_opr_src      ), // Operand sourcing.
.s2_size         (s2_size         ), // Size of the instruction.
.s2_instr        (s2_instr        ), // The instruction word
.flush           (flush_dispatch  ), // Flush this pipeline stage.
.fwd_s4_rd       (fwd_s4_rd       ), // Writeback stage destination reg.
.fwd_s4_wdata    (fwd_s4_wdata    ), // Write data for writeback stage.
.fwd_s4_load     (fwd_s4_load     ), // Writeback stage has load in it.
.fwd_s4_csr      (fwd_s4_csr      ), // Writeback stage has CSR op in it.
.fwd_s3_rd       (fwd_s3_rd       ), // Writeback stage destination reg.
.fwd_s3_wdata    (fwd_s3_wdata    ), // Write data for writeback stage.
.fwd_s3_load     (fwd_s3_load     ), // Writeback stage has load in it.
.fwd_s3_csr      (fwd_s3_csr      ), // Writeback stage has CSR op in it.
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


//
// instance: frv_pipeline_execute
//
//  Execute stage of the pipeline, responsible for ALU / LSU / Branch compare.
//
frv_pipeline_execute i_pipeline_execute (
.g_clk          (g_clk          ) , // global clock
.g_resetn       (g_resetn       ) , // synchronous reset
.s3_rd          (s3_rd          ) , // Destination register address
.s3_opr_a       (s3_opr_a       ) , // Operand A
.s3_opr_b       (s3_opr_b       ) , // Operand B
.s3_opr_c       (s3_opr_c       ) , // Operand C
.s3_pc          (s3_pc          ) , // Program counter
.s3_uop         (s3_uop         ) , // Micro-op code
.s3_fu          (s3_fu          ) , // Functional Unit
.s3_trap        (s3_trap        ) , // Raise a trap?
.s3_size        (s3_size        ) , // Size of the instruction.
.s3_instr       (s3_instr       ) , // The instruction word
.s3_p_busy      (s3_p_busy      ) , // Can this stage accept new inputs?
.s3_p_valid     (s3_p_valid     ) , // Is this input valid?
.flush          (flush_execute  ) , // Flush this pipeline stage.
.fwd_s3_rd      (fwd_s3_rd      ) , // Writeback stage destination reg.
.fwd_s3_wdata   (fwd_s3_wdata   ) , // Write data for writeback stage.
.fwd_s3_load    (fwd_s3_load    ) , // Writeback stage has load in it.
.fwd_s3_csr     (fwd_s3_csr     ) , // Writeback stage has CSR op in it.
.s4_rd          (s4_rd          ) , // Destination register address
.s4_opr_a       (s4_opr_a       ) , // Operand A
.s4_opr_b       (s4_opr_b       ) , // Operand B
.s4_pc          (s4_pc          ) , // Program counter
.s4_uop         (s4_uop         ) , // Micro-op code
.s4_fu          (s4_fu          ) , // Functional Unit
.s4_trap        (s4_trap        ) , // Raise a trap?
.s4_size        (s4_size        ) , // Size of the instruction.
.s4_instr       (s4_instr       ) , // The instruction word
.s4_p_busy      (s4_p_busy      ) , // Can this stage accept new inputs?
.s4_p_valid     (s4_p_valid     ) , // Is this input valid?
.dmem_cen       (dmem_cen       ) , // Chip enable
.dmem_wen       (dmem_wen       ) , // Write enable
.dmem_error     (dmem_error     ) , // Error
.dmem_stall     (dmem_stall     ) , // Memory stall
.dmem_strb      (dmem_strb      ) , // Write strobe
.dmem_addr      (dmem_addr      ) , // Read/Write address
.dmem_rdata     (dmem_rdata     ) , // Read data
.dmem_wdata     (dmem_wdata     )   // Write data
);



//
// instance: frv_pipeline_writeback
//
//  Responsible for finalising all instruction writeback behaviour.
//  - Jumps/control flow changes
//  - CSR accesses
//  - GPR writeback.
//
frv_pipeline_writeback i_pipeline_writeback(
.g_clk         (g_clk          ) , // global clock
.g_resetn      (g_resetn       ) , // synchronous reset
.s3_pc         (s3_pc          ) , // Program counter for JAL[R]
.s4_rd         (s4_rd          ) , // Destination register address
.s4_opr_a      (s4_opr_a       ) , // Operand A
.s4_opr_b      (s4_opr_b       ) , // Operand B
.s4_pc         (s4_pc          ) , // Program counter
.s4_uop        (s4_uop         ) , // Micro-op code
.s4_fu         (s4_fu          ) , // Functional Unit
.s4_trap       (s4_trap        ) , // Raise a trap?
.s4_size       (s4_size        ) , // Size of the instruction.
.s4_instr      (s4_instr       ) , // The instruction word
.s4_p_busy     (s4_p_busy      ) , // Can this stage accept new inputs?
.s4_p_valid    (s4_p_valid     ) , // Is this input valid?
.fwd_s4_rd     (fwd_s4_rd      ), // Writeback stage destination reg.
.fwd_s4_wdata  (fwd_s4_wdata   ), // Write data for writeback stage.
.fwd_s4_load   (fwd_s4_load    ), // Writeback stage has load in it.
.fwd_s4_csr    (fwd_s4_csr     ), // Writeback stage has CSR op in it.
.gpr_wen       (gpr_wen        ) , // GPR write enable.
.gpr_rd        (gpr_rd         ) , // GPR destination register.
.gpr_wdata     (gpr_wdata      ) , // GPR write data.
.trap_cpu      (trap_cpu       ), // A trap occured due to CPU
.trap_int      (trap_int       ), // A trap occured due to interrupt
.trap_cause    (trap_cause     ), // Cause of a trap.
.trap_mtval    (trap_mtval     ), // Value associated with the trap.
.trap_pc       (trap_pc        ), // PC value associated with the trap.
.csr_mepc      (csr_mepc       ), // Current MEPC.
.csr_mtvec     (csr_mtvec      ), // Current MTVEC.
.trs_pc        (trs_pc         ), // Trace program counter.
.trs_instr     (trs_instr      ), // Trace instruction.
.trs_valid     (trs_valid      ), // Trace output valid.
.csr_en        (csr_en         ), // CSR Access Enable
.csr_wr        (csr_wr         ), // CSR Write Enable
.csr_wr_set    (csr_wr_set     ), // CSR Write - Set
.csr_wr_clr    (csr_wr_clr     ), // CSR Write - Clear
.csr_addr      (csr_addr       ), // Address of the CSR to access.
.csr_wdata     (csr_wdata      ), // Data to be written to a CSR
.csr_rdata     (csr_rdata      ), // CSR read data
.cf_req        (cf_req         ), // Control flow change request
.cf_target     (cf_target      ), // Control flow change target
.cf_ack        (cf_ack         )  // Control flow change acknowledge.
);

endmodule

