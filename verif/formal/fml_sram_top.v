
//
// module: fml_sram_top
//
//  Top level module for running proofs on the SRAM interfaces of
//  the mrv_cpu module.
//
module fml_sram_top (
	input         clock,
	input         reset
);


wire         g_resetn = !reset;
wire         g_clk    =  clock;

(*keep*) wire         int_external = $anyseq; // External interrupt
(*keep*) wire         int_software = $anyseq; // Software interrupt

(*keep*) wire         imem_cen              ; // Chip enable
(*keep*) wire         imem_wen              ; // Write enable
(*keep*) wire         imem_error = $anyseq  ; // Error
(*keep*) wire         imem_stall = $anyseq  ; // Memory stall
(*keep*) wire [3:0]   imem_strb             ; // Write strobe
(*keep*) wire [31:0]  imem_addr             ; // Read/Write address
(*keep*) wire [31:0]  imem_rdata = $anyseq  ; // Read data
(*keep*) wire [31:0]  imem_wdata            ; // Write data

(*keep*) wire         dmem_cen              ; // Chip enable
(*keep*) wire         dmem_wen              ; // Write enable
(*keep*) wire         dmem_error = $anyseq  ; // Error
(*keep*) wire         dmem_stall = $anyseq  ; // Memory stall
(*keep*) wire [3:0]   dmem_strb             ; // Write strobe
(*keep*) wire [31:0]  dmem_addr             ; // Read/Write address
(*keep*) wire [31:0]  dmem_rdata = $anyseq  ; // Read data
(*keep*) wire [31:0]  dmem_wdata            ; // Write data


//
// SRAM interface checker for the instruction interface.
//
fml_sram_if fml_imem_checker(
.g_clk    (g_clk     ), // global clock
.g_resetn (g_resetn  ), // synchronous reset
.mem_cen  (imem_cen  ), // Chip enable
.mem_wen  (imem_wen  ), // Write enable
.mem_error(imem_error), // Error
.mem_stall(imem_stall), // Memory stall
.mem_strb (imem_strb ), // Write strobe
.mem_addr (imem_addr ), // Read/Write address
.mem_rdata(imem_rdata), // Read data
.mem_wdata(imem_wdata)  // Write data
);


//
// SRAM interface checker for the data interface.
//
fml_sram_if fml_dmem_checker(
.g_clk    (g_clk     ), // global clock
.g_resetn (g_resetn  ), // synchronous reset
.mem_cen  (dmem_cen  ), // Chip enable
.mem_wen  (dmem_wen  ), // Write enable
.mem_error(dmem_error), // Error
.mem_stall(dmem_stall), // Memory stall
.mem_strb (dmem_strb ), // Write strobe
.mem_addr (dmem_addr ), // Read/Write address
.mem_rdata(dmem_rdata), // Read data
.mem_wdata(dmem_wdata)  // Write data
);


//
// Top level of the CPU
//
mrv_cpu i_mrv_cpu(
.g_clk           (clock           ), // global clock
.g_resetn        (g_resetn        ), // synchronous reset
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

