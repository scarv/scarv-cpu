
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

scarv_ccx_memif #() if_ext();

assign  if_ext_req   = if_ext.req   ;  // Start memory request
assign  if_ext_wen   = if_ext.wen   ;  // Write enable
assign  if_ext_strb  = if_ext.strb  ;  // Write strobe
assign  if_ext_wdata = if_ext.wdata ;  // Write data
assign  if_ext_addr  = if_ext.addr  ;  // Read/Write address
assign  if_ext.gnt   = if_ext_gnt   ;  // request accepted
assign  if_ext.error = if_ext_error ;  // Error
assign  if_ext.rdata = if_ext_rdata ;  // Read data

scarv_ccx_top i_scarv_ccx_top (
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
