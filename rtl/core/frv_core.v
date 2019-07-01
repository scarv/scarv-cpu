
//
// module: frv_core
//
//  The top level of the CPU
//
module frv_core(

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

`ifdef FORMAL
output [NRET        - 1 : 0] rvfi_valid     ,
output [NRET *   64 - 1 : 0] rvfi_order     ,
output [NRET * ILEN - 1 : 0] rvfi_insn      ,
output [NRET        - 1 : 0] rvfi_trap      ,
output [NRET        - 1 : 0] rvfi_halt      ,
output [NRET        - 1 : 0] rvfi_intr      ,
output [NRET * 2    - 1 : 0] rvfi_mode      ,

output [NRET *    5 - 1 : 0] rvfi_rs1_addr  ,
output [NRET *    5 - 1 : 0] rvfi_rs2_addr  ,
output [NRET * XLEN - 1 : 0] rvfi_rs1_rdata ,
output [NRET * XLEN - 1 : 0] rvfi_rs2_rdata ,
output [NRET *    5 - 1 : 0] rvfi_rd_addr   ,
output [NRET * XLEN - 1 : 0] rvfi_rd_wdata  ,

output [NRET * XLEN - 1 : 0] rvfi_pc_rdata  ,
output [NRET * XLEN - 1 : 0] rvfi_pc_wdata  ,

output [NRET * XLEN  - 1: 0] rvfi_mem_addr  ,
output [NRET * XLEN/8- 1: 0] rvfi_mem_rmask ,
output [NRET * XLEN/8- 1: 0] rvfi_mem_wmask ,
output [NRET * XLEN  - 1: 0] rvfi_mem_rdata ,
output [NRET * XLEN  - 1: 0] rvfi_mem_wdata ,
`endif

input  wire         int_external    , // External interrupt trigger line.
input  wire         int_software    , // Software interrupt trigger line.

output wire         imem_cen        , // Chip enable
output wire         imem_wen        , // Write enable
input  wire         imem_error      , // Error
input  wire         imem_stall      , // Memory stall
output wire [3:0]   imem_strb       , // Write strobe
output wire [31:0]  imem_addr       , // Read/Write address
input  wire [31:0]  imem_rdata      , // Read data
output wire [31:0]  imem_wdata      , // Write data

output wire         dmem_cen        , // Chip enable
output wire         dmem_wen        , // Write enable
input  wire         dmem_error      , // Error
input  wire         dmem_stall      , // Memory stall
output wire [3:0]   dmem_strb       , // Write strobe
output wire [31:0]  dmem_addr       , // Read/Write address
input  wire [31:0]  dmem_rdata      , // Read data
output wire [31:0]  dmem_wdata        // Write data

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Use a BRAM/DMEM friendly register file?
parameter BRAM_REGFILE = 0;

// Common core parameters and constants
`include "frv_common.vh"

// -------------------------------------------------------------------------

//
// instance: frv_pipeline
//
//  The top level of the CPU data pipeline
//
frv_pipeline #(
.FRV_PC_RESET_VALUE(FRV_PC_RESET_VALUE),
.BRAM_REGFILE(BRAM_REGFILE)
) i_pipeline(
.g_clk         (g_clk         ), // global clock
.g_resetn      (g_resetn      ), // synchronous reset
`ifdef FORMAL
.rvfi_valid    (rvfi_valid    ),
.rvfi_order    (rvfi_order    ),
.rvfi_insn     (rvfi_insn     ),
.rvfi_trap     (rvfi_trap     ),
.rvfi_halt     (rvfi_halt     ),
.rvfi_intr     (rvfi_intr     ),
.rvfi_mode     (rvfi_mode     ),
.rvfi_rs1_addr (rvfi_rs1_addr ),
.rvfi_rs2_addr (rvfi_rs2_addr ),
.rvfi_rs1_rdata(rvfi_rs1_rdata),
.rvfi_rs2_rdata(rvfi_rs2_rdata),
.rvfi_rd_addr  (rvfi_rd_addr  ),
.rvfi_rd_wdata (rvfi_rd_wdata ),
.rvfi_pc_rdata (rvfi_pc_rdata ),
.rvfi_pc_wdata (rvfi_pc_wdata ),
.rvfi_mem_addr (rvfi_mem_addr ),
.rvfi_mem_rmask(rvfi_mem_rmask),
.rvfi_mem_wmask(rvfi_mem_wmask),
.rvfi_mem_rdata(rvfi_mem_rdata),
.rvfi_mem_wdata(rvfi_mem_wdata),
`endif
.imem_cen      (imem_cen      ), // Chip enable
.imem_wen      (imem_wen      ), // Write enable
.imem_error    (imem_error    ), // Error
.imem_stall    (imem_stall    ), // Memory stall
.imem_strb     (imem_strb     ), // Write strobe
.imem_addr     (imem_addr     ), // Read/Write address
.imem_rdata    (imem_rdata    ), // Read data
.imem_wdata    (imem_wdata    ), // Write data
.dmem_cen      (dmem_cen      ), // Chip enable
.dmem_wen      (dmem_wen      ), // Write enable
.dmem_error    (dmem_error    ), // Error
.dmem_stall    (dmem_stall    ), // Memory stall
.dmem_strb     (dmem_strb     ), // Write strobe
.dmem_addr     (dmem_addr     ), // Read/Write address
.dmem_rdata    (dmem_rdata    ), // Read data
.dmem_wdata    (dmem_wdata    )  // Write data
);

endmodule
