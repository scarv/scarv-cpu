
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

parameter XL = 31;

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

// Unused by RVFI, but used by XCrypto formal checkers.
wire [NRET *    5 - 1 : 0] rvfi_rs3_addr  ;
wire [NRET * XLEN - 1 : 0] rvfi_rs3_rdata ;

//
// Memory request/response counters
// --------------------------------------------------------------------

reg [31:0] imem_reqs;
reg [31:0] imem_rsps;
        
wire [31:0] n_imem_reqs = imem_reqs + (imem_req  && imem_gnt);
wire [31:0] n_imem_rsps = imem_rsps + (imem_recv && imem_ack);

reg [31:0] dmem_reqs;
reg [31:0] dmem_rsps;

wire [31:0] n_dmem_reqs = dmem_reqs + (dmem_req  && dmem_gnt);
wire [31:0] n_dmem_rsps = dmem_rsps + (dmem_recv && dmem_ack);

reg  [31:0] imem_outstanding;
wire [31:0] n_imem_outstanding = imem_outstanding + (imem_reqs > imem_rsps);

reg  [31:0] dmem_outstanding;
wire [31:0] n_dmem_outstanding = dmem_outstanding + (dmem_reqs > dmem_rsps);

// Instruction memory request/response counter.
always @(posedge clock) begin
    if(reset) begin
        imem_reqs <= 0;
        imem_rsps <= 0;
    end else begin
        imem_reqs <= imem_reqs + (imem_req  && imem_gnt);
        imem_rsps <= imem_rsps + (imem_recv && imem_ack);
    end
end

// Time for which there is >0 outstanding instruction memory requests.
always @(posedge clock) begin
    if(reset || imem_reqs <= imem_rsps) begin
        imem_outstanding <= 0;
    end else begin
        imem_outstanding <= n_imem_outstanding;
    end
end

// Time for which there is >0 outstanding data memory requests.
always @(posedge clock) begin
    if(reset || dmem_reqs <= dmem_rsps) begin
        dmem_outstanding <= 0;
    end else begin
        dmem_outstanding <= n_dmem_outstanding;
    end
end

// Data memory request/response counter.
always @(posedge clock) begin
    if(reset) begin
        dmem_reqs <= 0;
        dmem_rsps <= 0;
    end else begin
        dmem_reqs <= dmem_reqs + (dmem_req  && dmem_gnt);
        dmem_rsps <= dmem_rsps + (dmem_recv && dmem_ack);
    end
end

// Instruction memory request grant stall counter.
reg  [4:0] imem_req_gnt_stall;
wire [4:0] n_imem_req_gnt_stall = imem_req_gnt_stall + (imem_req&&!imem_gnt);

always @(posedge clock) begin
    if(reset || imem_gnt) begin
        imem_req_gnt_stall <= 0;
    end else begin
        imem_req_gnt_stall <= n_imem_req_gnt_stall;
    end
end


// Data memory request grant stall counter.
reg  [4:0] dmem_req_gnt_stall;
wire [4:0] n_dmem_req_gnt_stall = dmem_req_gnt_stall + (dmem_req&&!dmem_gnt);


always @(posedge clock) begin
    if(reset || dmem_gnt) begin
        dmem_req_gnt_stall <= 0;
    end else begin
        dmem_req_gnt_stall <= n_dmem_req_gnt_stall;
    end
end


//
// Fairness restrictions
// --------------------------------------------------------------------

//
// Don't allow memory *requests* to be ignored for more than N cycles.
always @(posedge clock) begin
    restrict(imem_req_gnt_stall < 3);
    restrict(dmem_req_gnt_stall < 3);
end

//
// Don't allow memory requests to "back up" without being acknowledged.
// Maximum of N cycles spent with outstanding requests.
always @(posedge clock) begin
    restrict(imem_outstanding <= 3);
    restrict(dmem_outstanding <= 3);
end

//
// Fairness restrictions so we never get a memory response we
// didn't issue a request for.
always @(posedge clock) begin
    restrict(dmem_rsps <= dmem_reqs);
    restrict(imem_rsps <= imem_reqs);

    // If num responses >= num requests, *mem_recv is clear. Else True.
    restrict(dmem_rsps >= dmem_reqs ? dmem_recv == 1'b0 : 1'b1);
    restrict(imem_rsps >= imem_reqs ? imem_recv == 1'b0 : 1'b1);
end

//
// RVFI can't handle propagation of bus errors properly, so assume
// they don't happen. *gulp*.
always @(posedge clock) begin
    if(imem_recv) begin
        assume(imem_error == 1'b0);
    end
    if(dmem_recv) begin
        assume(dmem_error == 1'b0);
    end
end


//
// DUT instance
// --------------------------------------------------------------------

frv_core #(
.TRACE_INSTR_WORD(1'b1) // Require tracing of instruction words.
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
