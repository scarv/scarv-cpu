
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

// Use buffered pipeline handshake protocol?
parameter BUFFER_HANDSHAKE = 0;

// Common core parameters and constants
`include "frv_common.vh"

// -------------------------------------------------------------------------

wire             cf_req     ; // Control flow change request
wire [XLEN-1:0]  cf_target  ; // Control flow change destination
wire             cf_ack     ; // Control flow change acknolwedge

wire             fd_flush   ; // Flush FD pipeline register.
wire             dd_flush   ; // Flush DD pipeline register.
wire             de_flush   ; // Flush DE pipeline register.
wire             ew_flush   ; // Flush EW pipeline register.

localparam RLEN_FD = 34;

wire [     31:0]    s0_data    ; // Output data to pipeline register.
wire                s0_error   ; // Fetch error occured.
wire                s0_d_valid ; // Output data is valid
wire                s0_valid   ; // Is fetch stage output valid? 

// Pack up outputs of fetch stage for input to pipeline register
wire [RLEN_FD-1:0]  s0_pipe_in = {
    s0_error, s0_d_valid, s0_data
};

wire [RLEN_FD-1:0]  mr_s1_data ;
wire [RLEN_FD-1:0]  s1_pipe_out;

wire                s0_s1_busy      ; // Is decode stage busy?  S0 aligned
wire                s1_s1_busy      ; // Is decode stage busy?  S1 aligned

// Most recently register'd values
wire [     31:0]    s1_mr_data      ; // Output data to pipeline register.
wire                s1_mr_d_valid   ; // Output data is valid
wire                s1_mr_error     ; // Fetch error occured.

// Current inputs to decode stage
wire [     31:0]    s1_data         ; // Output data to pipeline register.
wire                s1_d_valid      ; // Output data is valid
wire                s1_error        ; // Fetch error occured.
wire                s1_valid        ; // Is fetch stage output valid? 

// Unpack s0 -> s1 pipeline.
assign {s1_error   , s1_d_valid   , s1_data   } = s1_pipe_out;
assign {s1_mr_error, s1_mr_d_valid, s1_mr_data} = mr_s1_data;

// -------------------------------------------------------------------------


//
// module: frv_core_fetch
//
//  Fetch stage of the CPU, responsible for delivering instructions to
//  the decoder in a timely fashion.
//
frv_core_fetch i_core_fetch(
.g_clk     (g_clk           ), // global clock
.g_resetn  (g_resetn        ), // synchronous reset
.cf_req    (cf_req          ), // Control flow change request
.cf_target (cf_target       ), // Control flow change destination
.cf_ack    (cf_ack          ), // Control flow change acknolwedge
.imem_cen  (imem_cen        ), // Chip enable
.imem_wen  (imem_wen        ), // Write enable
.imem_error(imem_error      ), // Error
.imem_stall(imem_stall      ), // Memory stall
.imem_strb (imem_strb       ), // Write strobe
.imem_addr (imem_addr       ), // Read/Write address
.imem_rdata(imem_rdata      ), // Read data
.imem_wdata(imem_wdata      ), // Write data
.s1_data   (s1_mr_data      ), // Data previously sent to decode
.s0_data   (s0_data         ), // Output data to pipeline register.
.s0_error  (s0_error        ), // Fetch error occured.
.s0_d_valid(s0_d_valid      ), // Output data is valid
.s0_valid  (s0_valid        ), // Is fetch stage output valid? 
.s1_busy   (s0_s1_busy      )  // Is the decode stage busy? 
);


frv_pipeline_register #(
.RLEN(RLEN_FD),
.BUFFER_HANDSHAKE(BUFFER_HANDSHAKE)
) i_pipereg_fd (
.g_clk   (g_clk             ) , // global clock
.g_resetn(g_resetn          ) , // synchronous reset
.i_data  (s0_pipe_in        ) , // Input data from stage N
.i_valid (s0_valid          ) , // Input data valid?
.o_busy  (s0_s1_busy        ) , // Stage N+1 ready to continue?
.mr_data (mr_s1_data        ) , // Most recent data into the stage.
.flush   (fd_flush          ) , // Flush the contents of the pipeline
.o_data  (s1_pipe_out       ) , // Output data for stage N+1
.o_valid (s1_valid          ) , // Input data from stage N valid?
.i_busy  (s1_s1_busy        )   // Stage N+1 ready to continue?
);

endmodule

