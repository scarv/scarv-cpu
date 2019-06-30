
//
// module: rvfi_wrapper
//
//  A wrapper around the core which allows it to interface with the
//  riscv-formal framework.
//
module rvfi_wrapper (
	input         clock,
	input         reset,
	`RVFI_OUTPUTS
);

wire         trs_valid       ; // Trace output valid.
wire [31:0]  trs_pc          ; // Trace program counter object.
wire [31:0]  trs_instr       ; // Instruction traced out.

wire         g_resetn = !reset;

(*keep*) `rvformal_rand_reg         int_external; // External interrupt
(*keep*) `rvformal_rand_reg         int_software; // Software interrupt

(*keep*) wire                       imem_cen  ; // Chip enable
(*keep*) wire                       imem_wen  ; // Write enable
(*keep*) `rvformal_rand_reg         imem_error; // Error
(*keep*) `rvformal_rand_reg         imem_stall; // Memory stall
(*keep*) wire               [3:0]   imem_strb ; // Write strobe
(*keep*) wire               [31:0]  imem_addr ; // Read/Write address
(*keep*) `rvformal_rand_reg [31:0]  imem_rdata; // Read data
(*keep*) wire               [31:0]  imem_wdata; // Write data

(*keep*) wire                       dmem_cen  ; // Chip enable
(*keep*) wire                       dmem_wen  ; // Write enable
(*keep*) `rvformal_rand_reg         dmem_error; // Error
(*keep*) `rvformal_rand_reg         dmem_stall; // Memory stall
(*keep*) wire               [3:0]   dmem_strb ; // Write strobe
(*keep*) wire               [31:0]  dmem_addr ; // Read/Write address
(*keep*) `rvformal_rand_reg [31:0]  dmem_rdata; // Read data
(*keep*) wire               [31:0]  dmem_wdata; // Write data

always @(posedge clock) begin
    // riscv-formal has no notion of a memory bus error.
    if(imem_cen) assume(imem_error == 1'b0);
    if(dmem_cen) assume(dmem_error == 1'b0);
end

mrv_cpu i_mrv_cpu(
.g_clk           (clock           ), // global clock
.g_resetn        (g_resetn        ), // synchronous reset
.trs_valid       (trs_valid       ), // Trace output valid.
.trs_pc          (trs_pc          ), // Trace program counter object.
.trs_instr       (trs_instr       ), // Instruction traced out.
.rvfi_valid      (rvfi_valid      ),
.rvfi_order      (rvfi_order      ),
.rvfi_insn       (rvfi_insn       ),
.rvfi_trap       (rvfi_trap       ),
.rvfi_halt       (rvfi_halt       ),
.rvfi_intr       (rvfi_intr       ),
.rvfi_mode       (rvfi_mode       ),
.rvfi_rs1_addr   (rvfi_rs1_addr   ),
.rvfi_rs2_addr   (rvfi_rs2_addr   ),
.rvfi_rs1_rdata  (rvfi_rs1_rdata  ),
.rvfi_rs2_rdata  (rvfi_rs2_rdata  ),
.rvfi_rd_addr    (rvfi_rd_addr    ),
.rvfi_rd_wdata   (rvfi_rd_wdata   ),
.rvfi_pc_rdata   (rvfi_pc_rdata   ),
.rvfi_pc_wdata   (rvfi_pc_wdata   ),
.rvfi_mem_addr   (rvfi_mem_addr   ),
.rvfi_mem_rmask  (rvfi_mem_rmask  ),
.rvfi_mem_wmask  (rvfi_mem_wmask  ),
.rvfi_mem_rdata  (rvfi_mem_rdata  ),
.rvfi_mem_wdata  (rvfi_mem_wdata  ),
.int_external    (int_external    ),
.int_software    (int_software    ),
.imem_cen        (imem_cen        ), // Chip enable
.imem_wen        (imem_wen        ), // Write enable
.imem_error      (imem_error      ), // Error
.imem_stall      (imem_stall      ), // Memory stall
.imem_strb       (imem_strb       ), // Write strobe
.imem_addr       (imem_addr       ), // Read/Write address
.imem_rdata      (imem_rdata      ), // Read data
.imem_wdata      (imem_wdata      ), // Write data
.dmem_cen        (dmem_cen        ), // Chip enable
.dmem_wen        (dmem_wen        ), // Write enable
.dmem_error      (dmem_error      ), // Error
.dmem_stall      (dmem_stall      ), // Memory stall
.dmem_strb       (dmem_strb       ), // Write strobe
.dmem_addr       (dmem_addr       ), // Read/Write address
.dmem_rdata      (dmem_rdata      ), // Read data
.dmem_wdata      (dmem_wdata      )  // Write data
);

endmodule
