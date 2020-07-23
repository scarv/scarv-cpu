
//
// module: frv_core
//
//  The top level of the CPU
//
module frv_core(

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

`ifdef RVFI
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
output [NRET * XLEN -1  : 0] rvfi_aux       ,
output [NRET *    5 - 1 : 0] rvfi_rd_addr   ,
output [NRET        - 1 : 0] rvfi_rd_wide   ,
output [NRET * XLEN - 1 : 0] rvfi_rd_wdata  ,
output [NRET * XLEN - 1 : 0] rvfi_rd_wdatahi,

output [NRET * XLEN - 1 : 0] rvfi_pc_rdata  ,
output [NRET * XLEN - 1 : 0] rvfi_pc_wdata  ,

output [NRET * XLEN  - 1: 0] rvfi_mem_addr  ,
output [NRET * XLEN/8- 1: 0] rvfi_mem_rmask ,
output [NRET * XLEN/8- 1: 0] rvfi_mem_wmask ,
output [NRET * XLEN  - 1: 0] rvfi_mem_rdata ,
output [NRET * XLEN  - 1: 0] rvfi_mem_wdata ,
`endif

output wire [XL:0]  trs_pc          , // Trace program counter.
output wire [31:0]  trs_instr       , // Trace instruction.
output wire         trs_valid       , // Trace output valid.
output wire         instr_ret       , // Instruction retired

input  wire         int_nmi         , // Non-maskable interrupt.
input  wire         int_external    , // External interrupt trigger line.
input  wire [ 3:0]  int_extern_cause, // External interrupt cause code.
input  wire         int_software    , // Software interrupt trigger line.
input  wire         int_mtime       , // Machine timer interrupt triggered.

input  wire [63:0]  ctr_time        , // Current mtime counter value.
input  wire [63:0]  ctr_cycle       , // Current cycle counter value.
input  wire [63:0]  ctr_instret     , // Instruction retired counter value.
output wire         ctr_inhibit_cy  , // Stop cycle counter incrementing.
output wire         ctr_inhibit_ir  , // Stop instret incrementing.

output wire         imem_req        , // Start memory request
output wire         imem_wen        , // Write enable
output wire [3:0]   imem_strb       , // Write strobe
output wire [XL:0]  imem_wdata      , // Write data
output wire [XL:0]  imem_addr       , // Read/Write address
input  wire         imem_gnt        , // request accepted
input  wire         imem_error      , // Error
input  wire [XL:0]  imem_rdata      , // Read data

output wire         dmem_req        , // Start memory request
output wire         dmem_wen        , // Write enable
output wire [3:0]   dmem_strb       , // Write strobe
output wire [XL:0]  dmem_wdata      , // Write data
output wire [XL:0]  dmem_addr       , // Read/Write address
input  wire         dmem_gnt        , // request accepted
input  wire         dmem_error      , // Error
input  wire [XL:0]  dmem_rdata        // Read data

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Use a BRAM/DMEM friendly register file?
parameter BRAM_REGFILE = 0;

// If set, trace the instruction word through the pipeline. Otherwise,
// set it to zeros and let it be optimised away.
parameter TRACE_INSTR_WORD = 1'b1;


//
// Value of the M-mode implementation id register
`ifdef SCARV_CPU_MIMPID
parameter  CSR_MIMPID         = `SCARV_CPU_MIMPID;
`else
parameter  CSR_MIMPID         = 32'b0;
`endif

// Common core parameters and constants
`include "frv_common.svh"

// -------------------------------------------------------------------------


wire        mstatus_mie      ; // Global interrupt enable.
wire        mie_meie         ; // External interrupt enable.
wire        mie_mtie         ; // Timer interrupt enable.
wire        mie_msie         ; // Software interrupt enable.

wire        mip_meip         ; // External interrupt pending
wire        mip_mtip         ; // Timer interrupt pending
wire        mip_msip         ; // Software interrupt pending

wire        int_trap_req     ; // Request WB stage trap an interrupt
wire [ 5:0] int_trap_cause   ; // Cause of interrupt
wire        int_trap_ack     ; // WB stage acknowledges the taken trap.

// -------------------------------------------------------------------------

//
// instance: frv_pipeline
//
//  The top level of the CPU data pipeline
//
frv_pipeline #(
.FRV_PC_RESET_VALUE (FRV_PC_RESET_VALUE ),
.BRAM_REGFILE       (BRAM_REGFILE       ),
.TRACE_INSTR_WORD   (TRACE_INSTR_WORD   ),
.CSR_MIMPID         (CSR_MIMPID         )
) i_pipeline(
.g_clk         (g_clk         ), // global clock
.g_resetn      (g_resetn      ), // synchronous reset
`ifdef RVFI
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
.rvfi_aux      (rvfi_aux      ),
.rvfi_rd_addr  (rvfi_rd_addr  ),
.rvfi_rd_wide  (rvfi_rd_wide  ),
.rvfi_rd_wdata (rvfi_rd_wdata ),
.rvfi_rd_wdatahi(rvfi_rd_wdatahi),
.rvfi_pc_rdata (rvfi_pc_rdata ),
.rvfi_pc_wdata (rvfi_pc_wdata ),
.rvfi_mem_addr (rvfi_mem_addr ),
.rvfi_mem_rmask(rvfi_mem_rmask),
.rvfi_mem_wmask(rvfi_mem_wmask),
.rvfi_mem_rdata(rvfi_mem_rdata),
.rvfi_mem_wdata(rvfi_mem_wdata),
`endif
.trs_pc        (trs_pc        ), // Trace program counter.
.trs_instr     (trs_instr     ), // Trace instruction.
.trs_valid     (trs_valid     ), // Trace output valid.
.instr_ret      (instr_ret      ), // Instruction retired.
.mstatus_mie    (mstatus_mie    ), // Global interrupt enable.
.mie_meie       (mie_meie       ), // External interrupt enable.
.mie_mtie       (mie_mtie       ), // Timer interrupt enable.
.mie_msie       (mie_msie       ), // Software interrupt enable.
.mip_meip       (mip_meip       ), // External interrupt pending
.mip_mtip       (mip_mtip       ), // Timer interrupt pending
.mip_msip       (mip_msip       ), // Software interrupt pending
.int_trap_req   (int_trap_req   ), // Request WB stage trap an interrupt
.int_trap_cause (int_trap_cause ), // Cause of interrupt
.int_trap_ack   (int_trap_ack   ), // WB stage acknowledge the taken trap.
.ctr_time       (ctr_time       ), // The time counter value.
.ctr_cycle      (ctr_cycle      ), // The cycle counter value.
.ctr_instret    (ctr_instret    ), // The instret counter value.
.inhibit_cy     (ctr_inhibit_cy ), // Stop cycle counter incrementing.
.inhibit_ir     (ctr_inhibit_ir ), // Stop instret incrementing.
.imem_req      (imem_req      ), // Start memory request
.imem_wen      (imem_wen      ), // Write enable
.imem_strb     (imem_strb     ), // Write strobe
.imem_wdata    (imem_wdata    ), // Write data
.imem_addr     (imem_addr     ), // Read/Write address
.imem_gnt      (imem_gnt      ), // request accepted
.imem_error    (imem_error    ), // Error
.imem_rdata    (imem_rdata    ), // Read data
.dmem_req      (dmem_req      ), // Start memory request
.dmem_wen      (dmem_wen      ), // Write enable
.dmem_strb     (dmem_strb     ), // Write strobe
.dmem_wdata    (dmem_wdata    ), // Write data
.dmem_addr     (dmem_addr     ), // Read/Write address
.dmem_gnt      (dmem_gnt      ), // request accepted
.dmem_error    (dmem_error    ), // Error
.dmem_rdata    (dmem_rdata    )  // Read data
);


//
// instance: frv_interrupts
//
//  Handles internal and external interrupts.
//
frv_interrupt i_interrupts (
.g_clk         (g_clk           ), //
.g_resetn      (g_resetn        ), //
.mstatus_mie   (mstatus_mie     ), // Global interrupt enable.
.mie_meie      (mie_meie        ), // External interrupt enable.
.mie_mtie      (mie_mtie        ), // Timer interrupt enable.
.mie_msie      (mie_msie        ), // Software interrupt enable.
.nmi_pending   (int_nmi         ),
.ex_pending    (int_external    ), // External interrupt pending?
.ex_cause      (int_extern_cause),// External interrupt cause code.
.ti_pending    (int_mtime       ), // From mrv_counters is mtime pending?
.sw_pending    (int_software    ), // Software interrupt pending?
.mip_meip      (mip_meip        ), // External interrupt pending
.mip_mtip      (mip_mtip        ), // Timer interrupt pending
.mip_msip      (mip_msip        ), // Software interrupt pending
.int_trap_req  (int_trap_req    ), // Request WB stage trap an interrupt
.int_trap_cause(int_trap_cause  ), // Cause of interrupt
.int_trap_ack  (int_trap_ack    )  // WB stage acknowledges the taken trap.
);


endmodule
