
`include "xcfi_macros.sv"

//
// module: xcfi_testbench
//
//  The toplevel testbench for the XCFI checking.
//
module xcfi_testbench (
    input clock,
    input reset
);

parameter XCFI_CHECK_CYCLE  = 15       ;

parameter ILEN              = 32       ;
parameter NRET              = 1        ;
parameter XLEN              = 32       ;
parameter XL                = XLEN - 1 ;

assume property (reset == $initstate);

reg [7:0] cycle_reg = 0;

always @(posedge clock) begin
    cycle_reg <= reset ? 1 : cycle_reg + (cycle_reg != 255);
end

wire    check = cycle_reg == XCFI_CHECK_CYCLE;

// All `rvfi_*` wires.
`XCFI_TRACE_WIRES

xcfi_insn_checker i_insn_checker(
.clock            (clock            ),
.reset            (reset            ),
.check            (check            ),
.rvfi_valid       (rvfi_valid       ),
.rvfi_order       (rvfi_order       ),
.rvfi_insn        (rvfi_insn        ),
.rvfi_trap        (rvfi_trap        ),
.rvfi_halt        (rvfi_halt        ),
.rvfi_intr        (rvfi_intr        ),
.rvfi_mode        (rvfi_mode        ),
.rvfi_ixl         (rvfi_ixl         ),
.rvfi_rs1_addr    (rvfi_rs1_addr    ),
.rvfi_rs2_addr    (rvfi_rs2_addr    ),
.rvfi_rs3_addr    (rvfi_rs3_addr    ),
.rvfi_aux         (rvfi_aux         ),
.rvfi_rng_data    (rvfi_rng_data    ), 
.rvfi_rng_stat    (rvfi_rng_stat    ), 
.rvfi_rs1_rdata   (rvfi_rs1_rdata   ),
.rvfi_rs2_rdata   (rvfi_rs2_rdata   ),
.rvfi_rs3_rdata   (rvfi_rs3_rdata   ),
.rvfi_rd_addr     (rvfi_rd_addr     ),
.rvfi_rd_wide     (rvfi_rd_wide     ),
.rvfi_rd_wdata    (rvfi_rd_wdata    ),
.rvfi_rd_wdatahi  (rvfi_rd_wdatahi  ),
.rvfi_pc_rdata    (rvfi_pc_rdata    ),
.rvfi_pc_wdata    (rvfi_pc_wdata    ),
.rvfi_mem_addr    (rvfi_mem_addr    ),
.rvfi_mem_rmask   (rvfi_mem_rmask   ),
.rvfi_mem_wmask   (rvfi_mem_wmask   ),
.rvfi_mem_rdata   (rvfi_mem_rdata   ),
.rvfi_mem_wdata   (rvfi_mem_wdata   ) 
);

//
// instance: xcfi_wrapper
//
//  Wrapper module around the DUT.
//
xcfi_wrapper i_wrapper(
.clock            (clock            ),
.reset            (reset            ),
.rvfi_valid       (rvfi_valid       ),
.rvfi_order       (rvfi_order       ),
.rvfi_insn        (rvfi_insn        ),
.rvfi_trap        (rvfi_trap        ),
.rvfi_halt        (rvfi_halt        ),
.rvfi_intr        (rvfi_intr        ),
.rvfi_mode        (rvfi_mode        ),
.rvfi_ixl         (rvfi_ixl         ),
.rvfi_rs1_addr    (rvfi_rs1_addr    ),
.rvfi_rs2_addr    (rvfi_rs2_addr    ),
.rvfi_rs3_addr    (rvfi_rs3_addr    ),
.rvfi_aux         (rvfi_aux         ),
.rvfi_rng_data    (rvfi_rng_data    ), 
.rvfi_rng_stat    (rvfi_rng_stat    ), 
.rvfi_rs1_rdata   (rvfi_rs1_rdata   ),
.rvfi_rs2_rdata   (rvfi_rs2_rdata   ),
.rvfi_rs3_rdata   (rvfi_rs3_rdata   ),
.rvfi_rd_addr     (rvfi_rd_addr     ),
.rvfi_rd_wide     (rvfi_rd_wide     ),
.rvfi_rd_wdata    (rvfi_rd_wdata    ),
.rvfi_rd_wdatahi  (rvfi_rd_wdatahi  ),
.rvfi_pc_rdata    (rvfi_pc_rdata    ),
.rvfi_pc_wdata    (rvfi_pc_wdata    ),
.rvfi_mem_addr    (rvfi_mem_addr    ),
.rvfi_mem_rmask   (rvfi_mem_rmask   ),
.rvfi_mem_wmask   (rvfi_mem_wmask   ),
.rvfi_mem_rdata   (rvfi_mem_rdata   ),
.rvfi_mem_wdata   (rvfi_mem_wdata   ) 
);

endmodule
