
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

parameter NRET = 1       ;
parameter XLEN = 32      ;
parameter XL   = XLEN - 1;

(*keep*) `rvformal_rand_reg         int_external; // External interrupt
(*keep*) `rvformal_rand_reg         int_software; // Software interrupt

(*keep*) wire                       imem_req  ; // Start memory request
(*keep*) wire                       imem_wen  ; // Write enable
(*keep*) wire [3:0]                 imem_strb ; // Write strobe
(*keep*) wire [XL:0]                imem_wdata; // Write data
(*keep*) wire [XL:0]                imem_addr ; // Read/Write address
(*keep*) `rvformal_rand_reg         imem_gnt  ; // request accepted
(*keep*) `rvformal_rand_reg         imem_recv ; // memory recieve response.
(*keep*) wire                       imem_ack  ; // memory ack response.
(*keep*) `rvformal_rand_reg         imem_error; // Error
(*keep*) `rvformal_rand_reg [XL:0]  imem_rdata; // Read data

(*keep*) wire                       dmem_req  ; // Start memory request
(*keep*) wire                       dmem_wen  ; // Write enable
(*keep*) wire [3:0]                 dmem_strb ; // Write strobe
(*keep*) wire [31:0]                dmem_wdata; // Write data
(*keep*) wire [31:0]                dmem_addr ; // Read/Write address
(*keep*) `rvformal_rand_reg         dmem_gnt  ; // request accepted
(*keep*) `rvformal_rand_reg         dmem_recv ; // memory recieve response.
(*keep*) wire                       dmem_ack  ; // memory ack response.
(*keep*) `rvformal_rand_reg         dmem_error; // Error
(*keep*) `rvformal_rand_reg [XL:0]  dmem_rdata; // Read data

(*keep*) wire        rng_req_valid  ; // Signal a new request to the RNG
(*keep*) wire [ 2:0] rng_req_op     ; // Operation to perform on the RNG
(*keep*) wire [31:0] rng_req_data   ; // Suplementary seed/init data
(*keep*) reg         rng_req_ready  = $anyseq; // RNG accepts request
(*keep*) reg         rng_rsp_valid  = $anyseq; // RNG response data valid
(*keep*) reg  [ 2:0] rng_rsp_status = $anyseq; // RNG status
(*keep*) reg  [31:0] rng_rsp_data   = $anyseq; // RNG response / sample data.
(*keep*) wire        rng_rsp_ready  ; // CPU accepts response.

// Unused by RVFI, but used by XCrypto formal checkers.
wire [NRET *    5 - 1 : 0] rvfi_rs3_addr  ;
wire [NRET * XLEN - 1 : 0] rvfi_rs3_rdata ;

//
// Fairness Assumptions / Restrictions
// --------------------------------------------------------------------

//
// Assume that we never get a wide writeback in the RVFI checking
// environment, since the RVFI checks can't handle this.
// Write writebacks are checked in the XCFI environment for consistency.
always @(posedge clock) begin
    assume(rvfi_rd_wide == 1'b0);
end


fi_fairness i_fairness (
.clock       (clock       ),
.reset       (reset       ),
.rng_req_valid(rng_req_valid), // Signal a new request to the RNG
.rng_req_ready(rng_req_ready), // RNG accepts request
.rng_rsp_valid(rng_rsp_valid), // RNG response data valid
.rng_rsp_ready(rng_rsp_ready), // CPU accepts response.
.imem_req    (imem_req    ),
.imem_gnt    (imem_gnt    ),
.imem_recv   (imem_recv   ),
.imem_ack    (imem_ack    ),
.imem_error  (imem_error  ),
.dmem_req    (dmem_req    ),
.dmem_gnt    (dmem_gnt    ),
.dmem_recv   (dmem_recv   ),
.dmem_ack    (dmem_ack    ),
.dmem_error  (dmem_error  ) 
);

//
// DUT instance
// --------------------------------------------------------------------

frv_core #(
.TRACE_INSTR_WORD(1'b1), // Require tracing of instruction words.
.XC_CLASS_MEMORY (1'b0)  // Scatter/gather not implemented
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
.rvfi_rs3_addr  (rvfi_rs3_addr  ),
.rvfi_rs1_rdata (rvfi_rs1_rdata ),
.rvfi_rs2_rdata (rvfi_rs2_rdata ),
.rvfi_rs3_rdata (rvfi_rs3_rdata ),
.rvfi_rd_addr   (rvfi_rd_addr   ),
.rvfi_rd_wide   (rvfi_rd_wide   ),
.rvfi_rd_wdata  (rvfi_rd_wdata  ),
.rvfi_rd_wdatahi(rvfi_rd_wdatahi),
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
.rng_req_valid  (rng_req_valid  ), // Signal a new request to the RNG
.rng_req_op     (rng_req_op     ), // Operation to perform on the RNG
.rng_req_data   (rng_req_data   ), // Suplementary seed/init data
.rng_req_ready  (rng_req_ready  ), // RNG accepts request
.rng_rsp_valid  (rng_rsp_valid  ), // RNG response data valid
.rng_rsp_status (rng_rsp_status ), // RNG status
.rng_rsp_data   (rng_rsp_data   ), // RNG response / sample data.
.rng_rsp_ready  (rng_rsp_ready  ), // CPU accepts response.
.int_external   (int_external   ), // External interrupt trigger line.
.int_software   (int_software   ), // Software interrupt trigger line.
.imem_req       (imem_req       ), // Start memory request
.imem_wen       (imem_wen       ), // Write enable
.imem_strb      (imem_strb      ), // Write strobe
.imem_wdata     (imem_wdata     ), // Write data
.imem_addr      (imem_addr      ), // Read/Write address
.imem_gnt       (imem_gnt       ), // request accepted
.imem_recv      (imem_recv      ), // Instruction memory recieve response.
.imem_ack       (imem_ack       ), // Instruction memory ack response.
.imem_error     (imem_error     ), // Error
.imem_rdata     (imem_rdata     ), // Read data
.dmem_req       (dmem_req       ), // Start memory request
.dmem_wen       (dmem_wen       ), // Write enable
.dmem_strb      (dmem_strb      ), // Write strobe
.dmem_wdata     (dmem_wdata     ), // Write data
.dmem_addr      (dmem_addr      ), // Read/Write address
.dmem_gnt       (dmem_gnt       ), // request accepted
.dmem_recv      (dmem_recv      ), // Data memory recieve response.
.dmem_ack       (dmem_ack       ), // Data memory ack response.
.dmem_error     (dmem_error     ), // Error
.dmem_rdata     (dmem_rdata     )  // Read data
);

endmodule
