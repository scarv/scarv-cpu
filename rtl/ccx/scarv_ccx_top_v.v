
//
// module: scarv_ccx_top_v
//
//  Top level module of the core complex with no top-level interface ports.
//  This gets round restrictions in Verilator and Vivado.
//
module scarv_ccx_top_v (

input  wire         f_clk           , // Free-running clock.
input  wire         g_resetn        , // Synchronous active low reset.

input  wire         int_ext         , // External interrupt.
input  wire [31:0]  int_ext_cause   , // External interrupt cause.

output wire [31: 0] cpu_trs_pc      , // Trace program counter.
output wire [31: 0] cpu_trs_instr   , // Trace instruction.
output wire         cpu_trs_valid   , // Trace output valid.

output wire         if_ext_req      , // Start memory request
output wire         if_ext_wen      , // Write enable
output wire [ 3:0]  if_ext_strb     , // Write strobe
output wire [31:0]  if_ext_wdata    , // Write data
output wire [31:0]  if_ext_addr     , // Read/Write address
input  wire         if_ext_gnt      , // request accepted
input  wire         if_ext_error    , // Error
input  wire [31:0]  if_ext_rdata      // Read data

);

//
// CCX Parameters
// ------------------------------------------------------------

parameter   ROM_BASE    = 32'h0000_0000; //! Base address of ROM
parameter   ROM_SIZE    = 32'h0000_0400; //! Size in bytes of ROM.
parameter   RAM_BASE    = 32'h0001_0000; //! Base address of RAM
parameter   RAM_SIZE    = 32'h0001_0000; //! Size in bytes of RAM.
parameter   MMIO_BASE   = 32'h0002_0000; //! Base address of MMIO.
parameter   MMIO_SIZE   = 32'h0000_0100; //! Size in bytes of MMIO
parameter   EXT_BASE    = 32'h1000_0000; //! Base address of EXT Mem.
parameter   EXT_SIZE    = 32'h1000_0000; //! Size in bytes of EXT Mem.

// Reset value for the mtimecmp memory mapped register.
parameter   MTIMECMP_RESET = 64'hFFFF_FFFF_FFFF_FFFF;

// Reset value for the program counter.
parameter   PC_RESET       = 32'b0;

/* verilator lint_off WIDTH */
//! Memory initialisation file for the ROM.
parameter [255*8-1:0] ROM_INIT_FILE = "rom.hex";
parameter [255*8-1:0] RAM_INIT_FILE = "ram.hex";
/* verilator lint_on WIDTH */

//
// External memory interface un-packing
// ------------------------------------------------------------

scarv_ccx_memif #() if_ext();

assign  if_ext_req   = if_ext.req   ;  // Start memory request
assign  if_ext_wen   = if_ext.wen   ;  // Write enable
assign  if_ext_strb  = if_ext.strb  ;  // Write strobe
assign  if_ext_wdata = if_ext.wdata ;  // Write data
assign  if_ext_addr  = if_ext.addr  ;  // Read/Write address
assign  if_ext.gnt   = if_ext_gnt   ;  // request accepted
assign  if_ext.error = if_ext_error ;  // Error
assign  if_ext.rdata = if_ext_rdata ;  // Read data

//
// Actual CCX Instance.
// ------------------------------------------------------------

scarv_ccx_top #(
.ROM_BASE       (ROM_BASE       ), //! Base address of ROM
.ROM_SIZE       (ROM_SIZE       ), //! Size in bytes of ROM.
.RAM_BASE       (RAM_BASE       ), //! Base address of RAM
.RAM_SIZE       (RAM_SIZE       ), //! Size in bytes of RAM.
.MMIO_BASE      (MMIO_BASE      ), //! Base address of MMIO.
.MMIO_SIZE      (MMIO_SIZE      ), //! Size in bytes of MMIO
.EXT_BASE       (EXT_BASE       ), //! Base address of EXT Mem.
.EXT_SIZE       (EXT_SIZE       ), //! Size in bytes of EXT Mem.
.MTIMECMP_RESET (MTIMECMP_RESET ),
.ROM_INIT_FILE  (ROM_INIT_FILE  ),
.RAM_INIT_FILE  (RAM_INIT_FILE  ),
.PC_RESET       (PC_RESET       )  //! Program counter reset value.
) i_scarv_ccx_top (
.f_clk         (f_clk         ), // Free-running clock.
.g_resetn      (g_resetn      ), // Synchronous active low reset.
.int_ext       (int_ext       ), // External interrupt.
.int_ext_cause (int_ext_cause ), // External interrupt cause.
.cpu_trs_pc    (cpu_trs_pc    ), // Trace program counter.
.cpu_trs_instr (cpu_trs_instr ), // Trace instruction.
.cpu_trs_valid (cpu_trs_valid ), // Trace output valid.
.if_ext        (if_ext        )  // External memory requests.
);

endmodule
