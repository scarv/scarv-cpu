
`include "defines.svh"
`include "rvfi_macros.vh"

//
// module: design_assertions_wrapper
//
//  Wraps the core in the required assumptions and trivial logic needed to
//  interface with the designer assertions proof environment.
//
module design_assertions_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);

wire         trs_valid      ; // Trace output valid.
wire [31:0]  trs_pc         ; // Trace program counter object.
wire [31:0]  trs_instr      ; // Instruction traced out.
wire         instr_ret      ; // Instruction retired.

wire         g_resetn = !reset;

parameter NRET = 1       ;
parameter XLEN = 32      ;
parameter XL   = XLEN - 1;

(*keep*) reg         int_nmi      = $anyseq ; // Non-maskable interrupt
(*keep*) reg         int_external = $anyseq ; // External interrupt
(*keep*) reg [ 3:0]  int_extern_cause= $anyseq ; // External interrupt
(*keep*) reg         int_software = $anyseq ; // Software interrupt
(*keep*) reg         int_mtime    = $anyseq ; // Machine timer interrupt.

(*keep*) reg [63:0]  ctr_time     = $anyseq ; // mtime counter value.
(*keep*) reg [63:0]  ctr_cycle    = $anyseq ; // cycle counter value.
(*keep*) reg [63:0]  ctr_instret  = $anyseq ; // Instructions retired.
(*keep*) wire        ctr_inhibit_cy         ; // Stop cycle counter.
(*keep*) wire        ctr_inhibit_ir         ; // Stop instret incrementing.

(*keep*) wire        imem_req               ; // Start memory request
(*keep*) wire        imem_wen               ; // Write enable
(*keep*) wire [3:0]  imem_strb              ; // Write strobe
(*keep*) wire [XL:0] imem_wdata             ; // Write data
(*keep*) wire [XL:0] imem_addr              ; // Read/Write address
(*keep*) reg         imem_gnt     = $anyseq ; // request accepted
(*keep*) reg         imem_error   = $anyseq ; // Error
(*keep*) reg  [XL:0] imem_rdata   = $anyseq ; // Read data

(*keep*) wire        dmem_req               ; // Start memory request
(*keep*) wire        dmem_wen               ; // Write enable
(*keep*) wire [3:0]  dmem_strb              ; // Write strobe
(*keep*) wire [31:0] dmem_wdata             ; // Write data
(*keep*) wire [31:0] dmem_addr              ; // Read/Write address
(*keep*) reg         dmem_gnt     = $anyseq ; // request accepted
(*keep*) reg         dmem_error   = $anyseq ; // Error
(*keep*) reg  [XL:0] dmem_rdata   = $anyseq ; // Read data

//
// Fairness Assumptions / Restrictions
// --------------------------------------------------------------------


design_assertions_fairness i_design_assertions_fairness (
.g_clk          (clock          ), // Global clock
.g_resetn       (g_resetn       ), // Global active low sync reset.
.int_ext        (int_external   ), // hardware interrupt
.imem_req       (imem_req       ), // Memory request
.imem_addr      (imem_addr      ), // Memory request address
.imem_wen       (imem_wen       ), // Memory request write enable
.imem_strb      (imem_strb      ), // Memory request write strobe
.imem_wdata     (imem_wdata     ), // Memory write data.
.imem_gnt       (imem_gnt       ), // Memory response valid
.imem_err       (imem_error     ), // Memory response error
.imem_rdata     (imem_rdata     ), // Memory response read data
.dmem_req       (dmem_req       ), // Memory request
.dmem_addr      (dmem_addr      ), // Memory request address
.dmem_wen       (dmem_wen       ), // Memory request write enable
.dmem_strb      (dmem_strb      ), // Memory request write strobe
.dmem_wdata     (dmem_wdata     ), // Memory write data.
.dmem_gnt       (dmem_gnt       ), // Memory response valid
.dmem_err       (dmem_error     ), // Memory response error
.dmem_rdata     (dmem_rdata     ), // Memory response read data
.trs_valid      (trs_valid      ), // Instruction trace valid
.trs_instr      (trs_instr      ), // Instruction trace data
.trs_pc         (trs_pc         )  // Instruction trace PC
);

//
// DUT instance
// --------------------------------------------------------------------

frv_core #(
.TRACE_INSTR_WORD(1'b1)  // Require tracing of instruction words.
) i_dut(
.g_clk          (clock          ), // global clock
.g_resetn       (g_resetn       ), // synchronous reset
.rvfi_valid     (rvfi_valid     ),
.rvfi_order     (rvfi_order     ),
.rvfi_insn      (rvfi_insn      ),
.rvfi_trap      (rvfi_trap      ),
.rvfi_halt      (rvfi_halt      ),
.rvfi_intr      (rvfi_intr      ),
.rvfi_mode      (rvfi_mode      ),
.rvfi_rs1_addr  (rvfi_rs1_addr  ),
.rvfi_rs2_addr  (rvfi_rs2_addr  ),
.rvfi_rs1_rdata (rvfi_rs1_rdata ),
.rvfi_rs2_rdata (rvfi_rs2_rdata ),
.rvfi_rd_addr   (rvfi_rd_addr   ),
.rvfi_rd_wdata  (rvfi_rd_wdata  ),
.rvfi_pc_rdata  (rvfi_pc_rdata  ),
.rvfi_pc_wdata  (rvfi_pc_wdata  ),
.rvfi_mem_addr  (rvfi_mem_addr  ),
.rvfi_mem_rmask (rvfi_mem_rmask ),
.rvfi_mem_wmask (rvfi_mem_wmask ),
.rvfi_mem_rdata (rvfi_mem_rdata ),
.rvfi_mem_wdata (rvfi_mem_wdata ),
.trs_pc         (trs_pc         ), // Trace program counter.
.trs_instr      (trs_instr      ), // Trace instruction.
.trs_valid      (trs_valid      ), // Trace output valid.
.instr_ret      (instr_ret      ), // Instruction retired
.int_nmi        (int_nmi        ), // Non-maskable interrupt trigger line.
.int_mtime      (int_mtime      ), // Non-maskable interrupt trigger line.
.int_external   (int_external   ), // External interrupt trigger line.
.int_extern_cause(int_extern_cause), // External interrupt trigger line.
.int_software   (int_software   ), // Software interrupt trigger line.
.int_mtime      (int_mtime      ), // Machine timer interrupt triggered.
.ctr_time       (ctr_time       ), // Current mtime counter value.
.ctr_cycle      (ctr_cycle      ), // Current cycle counter value.
.ctr_instret    (ctr_instret    ), // Instruction retired counter value.
.ctr_inhibit_cy (ctr_inhibit_cy ), // Stop cycle counter incrementing.
.ctr_inhibit_ir (ctr_inhibit_ir ), // Stop instret incrementing.
.imem_req       (imem_req       ), // Start memory request
.imem_wen       (imem_wen       ), // Write enable
.imem_strb      (imem_strb      ), // Write strobe
.imem_wdata     (imem_wdata     ), // Write data
.imem_addr      (imem_addr      ), // Read/Write address
.imem_gnt       (imem_gnt       ), // request accepted
.imem_error     (imem_error     ), // Error
.imem_rdata     (imem_rdata     ), // Read data
.dmem_req       (dmem_req       ), // Start memory request
.dmem_wen       (dmem_wen       ), // Write enable
.dmem_strb      (dmem_strb      ), // Write strobe
.dmem_wdata     (dmem_wdata     ), // Write data
.dmem_addr      (dmem_addr      ), // Read/Write address
.dmem_gnt       (dmem_gnt       ), // request accepted
.dmem_error     (dmem_error     ), // Error
.dmem_rdata     (dmem_rdata     )  // Read data
);

endmodule
