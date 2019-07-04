
//
// module: frv_pipeline
//
//  The top level of the CPU data pipeline
//
module frv_pipeline (

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

// Pipeline Register lengths
parameter RLEN_FD = 33;
parameter RLEN_DD = 33;
parameter RLEN_DE = 33;
parameter RLEN_EW = 33;

// Use buffered pipeline handshake protocol?
parameter BUFFER_HANDSHAKE = 0;

// Common core parameters and constants
`include "frv_common.vh"

// -------------------------------------------------------------------------

wire               cf_req   ; // Control flow change request
wire [XLEN-1:0]    cf_target; // Control flow change destination
wire               cf_ack   ; // Control flow change acknolwedge

wire               fd_flush ; // Flush FD pipeline register.
wire               dd_flush ; // Flush DD pipeline register.
wire               de_flush ; // Flush DE pipeline register.
wire               ew_flush ; // Flush EW pipeline register.

wire [RLEN_FD-1:0] c0_data  ; // Output from Fetch
wire               c0_valid ;
wire               c0_ready ;
wire [RLEN_FD-1:0] r1_data  ; // Input to Decode
wire               r1_valid ;
wire               r1_ready = c1_ready;

wire [RLEN_FD-1:0] c1_data  = r1_data; // Output from Decode
wire               c1_valid = r1_valid;
wire               c1_ready ;
wire [RLEN_FD-1:0] r2_data  ; // Input to Dispatch
wire               r2_valid ;
wire               r2_ready = c2_ready;

wire [RLEN_FD-1:0] c2_data  = r2_data; // Output from Dispatch 
wire               c2_valid = r2_valid;
wire               c2_ready ;
wire [RLEN_FD-1:0] r3_data  ; // Input to Execute
wire               r3_valid ;
wire               r3_ready = c3_ready;

wire [RLEN_FD-1:0] c3_data  = r3_data; // Output from Execute
wire               c3_valid = r3_valid;
wire               c3_ready ;
wire [RLEN_FD-1:0] r4_data  ; // Input to Writeback
wire               r4_valid ;
wire               r4_ready = 1'b1;

//
// Instruction fetch stage
//
frv_core_fetch #(
.RLEN(RLEN_FD),
.FRV_PC_RESET_VALUE(FRV_PC_RESET_VALUE)
) i_core_fetch (
.g_clk      (g_clk      ) , // global clock
.g_resetn   (g_resetn   ) , // synchronous reset
.cf_req     (cf_req     ) , // Control flow change request
.cf_target  (cf_target  ) , // Control flow change destination
.cf_ack     (cf_ack     ) , // Control flow change acknolwedge
.imem_cen   (imem_cen   ) , // Chip enable
.imem_wen   (imem_wen   ) , // Write enable
.imem_error (imem_error ) , // Error
.imem_stall (imem_stall ) , // Memory stall
.imem_strb  (imem_strb  ) , // Write strobe
.imem_addr  (imem_addr  ) , // Read/Write address
.imem_rdata (imem_rdata ) , // Read data
.imem_wdata (imem_wdata ) , // Write data
.p_data     (r1_data    ) , // Data previously sent to decode.
.o_data     (c0_data    ) , // Output data to pipeline register.
.o_valid    (c0_valid   ) , // Is fetch stage output valid? 
.i_ready    (c0_ready   )   // Is the decode stage ready?
);

//
// Fetch -> Decode Pipeline Register
//
frv_pipeline_register #(
.RLEN(RLEN_FD),
.BUFFER_HANDSHAKE(BUFFER_HANDSHAKE)
) i_pipeline_register_fd (
.g_clk   (g_clk   ), // global clock
.g_resetn(g_resetn), // synchronous reset
.i_data  (c0_data  ), // Input data from stage N
.i_valid (c0_valid ), // Input data valid?
.o_ready (c0_ready ), // Stage N+1 ready to continue?
.flush   (fd_flush ), // Flush the contents of the pipeline
.o_data  (r1_data  ), // Output data for stage N+1
.o_valid (r1_valid ), // Input data from stage N valid?
.i_ready (r1_ready )  // Stage N+1 ready to continue?
);

//
// frv_core_decode
//
//  Decode stage of the CPU
//
frv_core_decode #(
.RLEN(RLEN_DD)
) i_core_decode (
.g_clk   (g_clk    ), // global clock
.g_resetn(g_resetn ), // synchronous reset
.i_data  (r1_data  ), // Input data to the decoder
.i_valid (r1_valid ), // Is fetch stage output valid? 
.o_ready (r1_ready ), // Is the decode stage ready?
.o_data  (c1_data  ), // Output data to dispatch
.o_valid (c1_valid ), // Is decode stage output valid? 
.i_ready (c1_ready )  // Is the dispatch stage ready?
);


//
// Decode -> Dispatch Pipeline Register
//
frv_pipeline_register #(
.RLEN(RLEN_DD),
.BUFFER_HANDSHAKE(BUFFER_HANDSHAKE)
) i_pipeline_register_dd (
.g_clk   (g_clk   ), // global clock
.g_resetn(g_resetn), // synchronous reset
.i_data  (c1_data  ), // Input data from stage N
.i_valid (c1_valid ), // Input data valid?
.o_ready (c1_ready ), // Stage N+1 ready to continue?
.flush   (dd_flush ), // Flush the contents of the pipeline
.o_data  (r2_data  ), // Output data for stage N+1
.o_valid (r2_valid ), // Input data from stage N valid?
.i_ready (r2_ready )  // Stage N+1 ready to continue?
);


//
// Dispatch -> Execute Pipeline Register
//
frv_pipeline_register #(
.RLEN(RLEN_DE),
.BUFFER_HANDSHAKE(BUFFER_HANDSHAKE)
) i_pipeline_register_de (
.g_clk   (g_clk   ), // global clock
.g_resetn(g_resetn), // synchronous reset
.i_data  (c2_data  ), // Input data from stage N
.i_valid (c2_valid ), // Input data valid?
.o_ready (c2_ready ), // Stage N+1 ready to continue?
.flush   (de_flush ), // Flush the contents of the pipeline
.o_data  (r3_data  ), // Output data for stage N+1
.o_valid (r3_valid ), // Input data from stage N valid?
.i_ready (r3_ready )  // Stage N+1 ready to continue?
);

//
// Execute -> Writeback Pipeline Register
//
frv_pipeline_register #(
.RLEN(RLEN_EW),
.BUFFER_HANDSHAKE(BUFFER_HANDSHAKE)
) i_pipeline_register_ew (
.g_clk   (g_clk   ), // global clock
.g_resetn(g_resetn), // synchronous reset
.i_data  (c3_data  ), // Input data from stage N
.i_valid (c3_valid ), // Input data valid?
.o_ready (c3_ready ), // Stage N+1 ready to continue?
.flush   (ew_flush ), // Flush the contents of the pipeline
.o_data  (r4_data  ), // Output data for stage N+1
.o_valid (r4_valid ), // Input data from stage N valid?
.i_ready (r4_ready )  // Stage N+1 ready to continue?
);

endmodule

