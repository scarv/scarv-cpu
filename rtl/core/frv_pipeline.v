
//
// module: frv_pipeline
//
//  The top level of the CPU data pipeline
//
module frv_pipeline (

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
output [NRET *    5 - 1 : 0] rvfi_rs3_addr  ,
output [NRET * XLEN - 1 : 0] rvfi_rs1_rdata ,
output [NRET * XLEN - 1 : 0] rvfi_rs2_rdata ,
output [NRET * XLEN - 1 : 0] rvfi_rs3_rdata ,
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

output wire [XL:0]  trs_pc          , // Trace program counter.
output wire [31:0]  trs_instr       , // Trace instruction.
output wire         trs_valid       , // Trace output valid.

output wire         instr_ret       , // Instruction retired.

output wire         mstatus_mie     , // Global interrupt enable.
output wire         mie_meie        , // External interrupt enable.
output wire         mie_mtie        , // Timer interrupt enable.
output wire         mie_msie        , // Software interrupt enable.

input  wire         mip_meip        , // External interrupt pending
input  wire         mip_mtip        , // Timer interrupt pending
input  wire         mip_msip        , // Software interrupt pending

input  wire [63:0]  ctr_time        , // The time counter value.
input  wire [63:0]  ctr_cycle       , // The cycle counter value.
input  wire [63:0]  ctr_instret     , // The instret counter value.

input  wire         int_trap_req    , // Request WB stage trap an interrupt
input  wire [ 5:0]  int_trap_cause  , // Cause of interrupt
output wire         int_trap_ack    , // WB stage acknowledges the taken trap.

output wire         inhibit_cy      , // Stop cycle counter incrementing.
output wire         inhibit_tm      , // Stop time counter incrementing.
output wire         inhibit_ir      , // Stop instret incrementing.

output wire         mmio_en         , // MMIO enable
output wire         mmio_wen        , // MMIO write enable
output wire [31:0]  mmio_addr       , // MMIO address
output wire [31:0]  mmio_wdata      , // MMIO write data
input  wire [31:0]  mmio_rdata      , // MMIO read data
input  wire         mmio_error      , // MMIO error

output wire         imem_req        , // Start memory request
output wire         imem_wen        , // Write enable
output wire [3:0]   imem_strb       , // Write strobe
output wire [XL:0]  imem_wdata      , // Write data
output wire [XL:0]  imem_addr       , // Read/Write address
input  wire         imem_gnt        , // request accepted
input  wire         imem_recv       , // Instruction memory recieve response.
output wire         imem_ack        , // Instruction memory ack response.
input  wire         imem_error      , // Error
input  wire [XL:0]  imem_rdata      , // Read data

output wire         dmem_req        , // Start memory request
output wire         dmem_wen        , // Write enable
output wire [3:0]   dmem_strb       , // Write strobe
output wire [XL:0]  dmem_wdata      , // Write data
output wire [XL:0]  dmem_addr       , // Read/Write address
input  wire         dmem_gnt        , // request accepted
input  wire         dmem_recv       , // Instruction memory recieve response.
output wire         dmem_ack        , // Data memory ack response.
input  wire         dmem_error      , // Error
input  wire [XL:0]  dmem_rdata        // Read data

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Use a BRAM/DMEM friendly register file?
parameter BRAM_REGFILE = 0;

// Base address of the memory mapped IO region.
parameter   MMIO_BASE_ADDR        = 32'h0000_1000;
parameter   MMIO_BASE_MASK        = 32'hFFFF_F000;

// If set, trace the instruction word through the pipeline. Otherwise,
// set it to zeros and let it be optimised away.
parameter TRACE_INSTR_WORD = 1'b1;

//
// XCrypto feature class config bits.
parameter XC_CLASS_BASELINE   = 1'b1;
parameter XC_CLASS_RANDOMNESS = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_MEMORY     = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_BIT        = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_PACKED     = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_MULTIARITH = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_AES        = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_SHA2       = 1'b1 && XC_CLASS_BASELINE;
parameter XC_CLASS_SHA3       = 1'b1 && XC_CLASS_BASELINE;

//
// Partial Bitmanip Extension Support
parameter BITMANIP_BASELINE   = 1'b1;

// Common core parameters and constants
`include "frv_common.vh"

// -------------------------------------------------------------------------

//
// Alias'd / miscellaneous signals.
assign      instr_ret = trs_valid;

//
// Control flow change bus.
wire        cf_req     ; // Control flow change request
wire [XL:0] cf_target  ; // Control flow change destination
wire        cf_ack     ; // Control flow change acknolwedge

//
// CSR access bus.
wire        csr_en     ; // CSR Access Enable
wire        csr_wr     ; // CSR Write Enable
wire        csr_wr_set ; // CSR Write - Set
wire        csr_wr_clr ; // CSR Write - Clear
wire [11:0] csr_addr   ; // Address of the CSR to access.
wire [XL:0] csr_wdata  ; // Data to be written to a CSR
wire [XL:0] csr_rdata  ; // CSR read data

wire [XL:0] csr_mepc   ; // Current MEPC.
wire [XL:0] csr_mtvec  ; // Current MTVEC.

wire        exec_mret  ; // MRET instruction executed.

//
// Trap raising bus.
wire        trap_cpu   ; // A trap occured due to CPU
wire        trap_int   ; // A trap occured due to interrupt
wire [ 5:0] trap_cause ; // Cause code for the trap.
wire [XL:0] trap_mtval ; // Value associated with the trap.
wire [XL:0] trap_pc    ; // PC value associated with the trap.


wire        s0_flush   = cf_req && cf_ack; // Flush stage
wire        s1_flush   = cf_req && cf_ack; // Flush pipe stage register.
wire        s2_flush   = cf_req && cf_ack; // Flush this pipeline stage.
wire        s3_flush   = cf_req && cf_ack; // Flush this pipeline stage.
wire        s4_flush   = cf_req && cf_ack; // Flush this pipeline stage.

wire        s0_busy       ; // Stall stage

wire        s1_valid      ; // Stage ready to progress
wire        s1_busy       ; // Stage ready to progress
wire [XL:0] s1_data       ; // Data to be decoded.
wire        s1_error      ;

wire [ 4:0] s1_rs1_addr   ;
wire [ 4:0] s1_rs2_addr   ;
wire [ 4:0] s1_rs3_addr   ;
wire [XL:0] s1_rs1_rdata  ;
wire [XL:0] s1_rs2_rdata  ;
wire [XL:0] s1_rs3_rdata  ;

wire        s2_valid      ; // Is the output data valid?
wire        s2_busy       ; // Is the next stage ready for new inputs?
wire [ 4:0] s2_rd         ; // Destination register address
wire [XL:0] s2_opr_a      ; // Operand A
wire [XL:0] s2_opr_b      ; // Operand B
wire [XL:0] s2_opr_c      ; // Operand C
wire [OP:0] s2_uop        ; // Micro-op code
wire [FU:0] s2_fu         ; // Functional Unit (alu/mem/jump/mul/csr)
wire [PW:0] s2_pw         ; // IALU pack width specifer.
wire        s2_trap       ; // Raise a trap?
wire [ 1:0] s2_size       ; // Size of the instruction.
wire [31:0] s2_instr      ; // The instruction word

wire [ 4:0] fwd_s2_rd     ; // Writeback stage destination reg.
wire [XL:0] fwd_s2_wdata  ; // Write data for writeback stage.
wire        fwd_s2_load   ; // Writeback stage has load in it.
wire        fwd_s2_csr    ; // Writeback stage has CSR op in it.

wire [ 4:0] s3_rd         ; // Destination register address
wire [XL:0] s3_opr_a      ; // Operand A
wire [XL:0] s3_opr_b      ; // Operand B
wire [OP:0] s3_uop        ; // Micro-op code
wire [FU:0] s3_fu         ; // Functional Unit
wire        s3_trap       ; // Raise a trap?
wire [ 1:0] s3_size       ; // Size of the instruction.
wire [31:0] s3_instr      ; // The instruction word
wire        s3_busy       ; // Can this stage accept new inputs?
wire        s3_valid      ; // Is this input valid?

wire [ 4:0] fwd_s3_rd     ; // Writeback stage destination reg.
wire [XL:0] fwd_s3_wdata  ; // Write data for writeback stage.
wire        fwd_s3_load   ; // Writeback stage has load in it.
wire        fwd_s3_csr    ; // Writeback stage has CSR op in it.

wire [ 4:0] s4_rd         ; // Destination register address
wire [XL:0] s4_opr_a      ; // Operand A
wire [XL:0] s4_opr_b      ; // Operand B
wire [OP:0] s4_uop        ; // Micro-op code
wire [FU:0] s4_fu         ; // Functional Unit
wire        s4_trap       ; // Raise a trap?
wire [ 1:0] s4_size       ; // Size of the instruction.
wire [31:0] s4_instr      ; // The instruction word
wire        s4_busy       ; // Can this stage accept new inputs?
wire        s4_valid      ; // Is this input valid?

wire [ 4:0] fwd_s4_rd     ; // Writeback stage destination reg.
wire [XL:0] fwd_s4_wdata  ; // Write data for writeback stage.
wire        fwd_s4_load   ; // Writeback stage has load in it.
wire        fwd_s4_csr    ; // Writeback stage has CSR op in it.

wire        gpr_wen       ; // GPR write enable.
wire [ 4:0] gpr_rd        ; // GPR destination register.
wire [XL:0] gpr_wdata     ; // GPR write data.

wire        hold_lsu_req  ; // Don't make LSU requests yet.

`ifdef RVFI
wire [XL:0] rvfi_s2_rs1_rdata; // Source register data 1
wire [XL:0] rvfi_s2_rs2_rdata; // Source register data 2
wire [XL:0] rvfi_s2_rs3_rdata; // Source register data 3
wire [ 4:0] rvfi_s2_rs1_addr ; // Source register address 1
wire [ 4:0] rvfi_s2_rs2_addr ; // Source register address 2
wire [ 4:0] rvfi_s2_rs3_addr ; // Source register address 3
wire [XL:0] rvfi_s3_rs1_rdata; // Source register data 1
wire [XL:0] rvfi_s3_rs2_rdata; // Source register data 2
wire [XL:0] rvfi_s3_rs3_rdata; // Source register data 3
wire [ 4:0] rvfi_s3_rs1_addr ; // Source register address 1
wire [ 4:0] rvfi_s3_rs2_addr ; // Source register address 2
wire [ 4:0] rvfi_s3_rs3_addr ; // Source register address 3
wire [XL:0] rvfi_s4_rs1_rdata; // Source register data 1
wire [XL:0] rvfi_s4_rs2_rdata; // Source register data 2
wire [XL:0] rvfi_s4_rs3_rdata; // Source register data 3
wire [ 4:0] rvfi_s4_rs1_addr ; // Source register address 1
wire [ 4:0] rvfi_s4_rs2_addr ; // Source register address 2
wire [ 4:0] rvfi_s4_rs3_addr ; // Source register address 3
wire [XL:0] rvfi_s4_mem_wdata; // Memory write data.
`endif


//
// Bubbling and forwarding control.
// -------------------------------------------------------------------------

wire nz_s1_rs1     = |s1_rs1_addr;
wire nz_s1_rs2     = |s1_rs2_addr;
wire nz_s1_rs3     = |s1_rs3_addr;

wire hzd_rs1_s4 = s1_rs1_addr == fwd_s4_rd && nz_s1_rs1;
wire hzd_rs1_s3 = s1_rs1_addr == fwd_s3_rd && nz_s1_rs1;
wire hzd_rs1_s2 = s1_rs1_addr == fwd_s2_rd && nz_s1_rs1;

wire hzd_rs2_s4 = s1_rs2_addr == fwd_s4_rd && nz_s1_rs2;
wire hzd_rs2_s3 = s1_rs2_addr == fwd_s3_rd && nz_s1_rs2;
wire hzd_rs2_s2 = s1_rs2_addr == fwd_s2_rd && nz_s1_rs2;

wire hzd_rs3_s4 = s1_rs3_addr == fwd_s4_rd && nz_s1_rs3;
wire hzd_rs3_s3 = s1_rs3_addr == fwd_s3_rd && nz_s1_rs3;
wire hzd_rs3_s2 = s1_rs3_addr == fwd_s2_rd && nz_s1_rs3;

//
// Bubbling occurs when:
// - There is a data hazard due to a CSR read or a data load.
wire   s1_bubble   =
    !s1_valid && !s2_busy                                                   ||
    ((fwd_s4_load||fwd_s4_csr) && (hzd_rs1_s4 || hzd_rs2_s4 || hzd_rs3_s4)) ||
    ((fwd_s3_load||fwd_s3_csr) && (hzd_rs1_s3 || hzd_rs2_s3 || hzd_rs3_s3)) ||
    ((fwd_s2_load||fwd_s2_csr) && (hzd_rs1_s2 || hzd_rs2_s2 || hzd_rs3_s2))  ;


wire [XL:0] fwd_rs1_rdata =
     hzd_rs1_s2 ? fwd_s2_wdata   :
     hzd_rs1_s3 ? fwd_s3_wdata   :
     hzd_rs1_s4 ? fwd_s4_wdata   :
                  s1_rs1_rdata   ;

wire [XL:0] fwd_rs2_rdata =
     hzd_rs2_s2 ? fwd_s2_wdata   :
     hzd_rs2_s3 ? fwd_s3_wdata   :
     hzd_rs2_s4 ? fwd_s4_wdata   :
                  s1_rs2_rdata   ;

wire [XL:0] fwd_rs3_rdata =
     hzd_rs3_s2 ? fwd_s2_wdata   :
     hzd_rs3_s3 ? fwd_s3_wdata   :
     hzd_rs3_s4 ? fwd_s4_wdata   :
                  s1_rs3_rdata   ;

//
// Submodule Instances.
// -------------------------------------------------------------------------


//
// instance: frv_pipeline_fetch
//
//  Fetch pipeline stage.
//
frv_pipeline_fetch #(
.FRV_PC_RESET_VALUE(FRV_PC_RESET_VALUE)
) i_pipeline_s0_fetch (
.g_clk              (g_clk              ), // global clock
.g_resetn           (g_resetn           ), // synchronous reset
.cf_req             (cf_req             ), // Control flow change
.cf_target          (cf_target          ), // Control flow change target
.cf_ack             (cf_ack             ), // Acknowledge control flow change
.imem_req           (imem_req           ), // Start memory request
.imem_wen           (imem_wen           ), // Write enable
.imem_strb          (imem_strb          ), // Write strobe
.imem_wdata         (imem_wdata         ), // Write data
.imem_addr          (imem_addr          ), // Read/Write address
.imem_gnt           (imem_gnt           ), // request accepted
.imem_ack           (imem_ack           ), // memory ack response.
.imem_recv          (imem_recv          ), // memory recieve response.
.imem_error         (imem_error         ), // Error
.imem_rdata         (imem_rdata         ), // Read data
.s0_flush           (s0_flush           ), // Flush stage
.s1_busy            (s1_busy            ), // Stall stage
.s1_valid           (s1_valid           ), // Stage ready to progress
.s1_data            (s1_data            ), // Data to be decoded.
.s1_error           (s1_error           )
);

//
// instance : frv_pipeline_decode
//
//  Decode stage of the CPU, responsible for turning RISC-V encoded
//  instructions into wider pipeline encodings.
//
frv_pipeline_decode #(
.FRV_PC_RESET_VALUE (FRV_PC_RESET_VALUE ),
.TRACE_INSTR_WORD   (TRACE_INSTR_WORD   ),
.XC_CLASS_BASELINE  (XC_CLASS_BASELINE  ),
.XC_CLASS_RANDOMNESS(XC_CLASS_RANDOMNESS),
.XC_CLASS_MEMORY    (XC_CLASS_MEMORY    ),
.XC_CLASS_BIT       (XC_CLASS_BIT       ),
.XC_CLASS_PACKED    (XC_CLASS_PACKED    ),
.XC_CLASS_MULTIARITH(XC_CLASS_MULTIARITH),
.XC_CLASS_AES       (XC_CLASS_AES       ),
.XC_CLASS_SHA2      (XC_CLASS_SHA2      ),
.XC_CLASS_SHA3      (XC_CLASS_SHA3      ),
.BITMANIP_BASELINE  (BITMANIP_BASELINE  ) 
) i_pipeline_s1_decode (
.g_clk              (g_clk              ), // global clock
.g_resetn           (g_resetn           ), // synchronous reset
.s1_valid           (s1_valid           ), // Is the input data valid?
.s1_busy            (s1_busy            ), // Is this stage ready for new inputs?
.s1_data            (s1_data            ), // Data word to decode.
.s1_error           (s1_error           ), // Is there a fetch bus error?
.s1_flush           (s1_flush           ), // Flush pipe stage register.
.s1_bubble          (s1_bubble          ), // Insert a pipeline bubble.
.s1_rs1_addr        (s1_rs1_addr        ),
.s1_rs2_addr        (s1_rs2_addr        ),
.s1_rs3_addr        (s1_rs3_addr        ),
.s1_rs1_rdata       (fwd_rs1_rdata      ),
.s1_rs2_rdata       (fwd_rs2_rdata      ),
.s1_rs3_rdata       (fwd_rs3_rdata      ),
.cf_req             (cf_req             ), // Control flow change
.cf_target          (cf_target          ), // Control flow change target
.cf_ack             (cf_ack             ), // Acknowledge control flow change
`ifdef RVFI
.rvfi_s2_rs1_addr   (rvfi_s2_rs1_addr   ),
.rvfi_s2_rs2_addr   (rvfi_s2_rs2_addr   ),
.rvfi_s2_rs3_addr   (rvfi_s2_rs3_addr   ),
.rvfi_s2_rs1_data   (rvfi_s2_rs1_rdata  ),
.rvfi_s2_rs2_data   (rvfi_s2_rs2_rdata  ),
.rvfi_s2_rs3_data   (rvfi_s2_rs3_rdata  ),
`endif
.s2_valid           (s2_valid           ), // Is the output data valid?
.s2_busy            (s2_busy            ), // Is next stage ready?
.s2_rd              (s2_rd              ), // Destination register address
.s2_opr_a           (s2_opr_a           ), // Operand A
.s2_opr_b           (s2_opr_b           ), // Operand B
.s2_opr_c           (s2_opr_c           ), // Operand C
.s2_uop             (s2_uop             ), // Micro-op code
.s2_fu              (s2_fu              ), // Functional Unit
.s2_pw              (s2_pw              ), // IALU Pack width
.s2_trap            (s2_trap            ), // Raise a trap?
.s2_size            (s2_size            ), // Size of the instruction.
.s2_instr           (s2_instr           )  // The instruction word
);

//
// instance: frv_pipeline_execute
//
//  Execute stage of the pipeline, responsible for ALU / LSU / Branch compare.
//
frv_pipeline_execute #(
.XC_CLASS_RANDOMNESS(XC_CLASS_RANDOMNESS),
.XC_CLASS_MEMORY    (XC_CLASS_MEMORY    ),
.XC_CLASS_BIT       (XC_CLASS_BIT       ),
.XC_CLASS_PACKED    (XC_CLASS_PACKED    ),
.XC_CLASS_MULTIARITH(XC_CLASS_MULTIARITH),
.XC_CLASS_AES       (XC_CLASS_AES       ),
.XC_CLASS_SHA2      (XC_CLASS_SHA2      ),
.XC_CLASS_SHA3      (XC_CLASS_SHA3      ),
.BITMANIP_BASELINE  (BITMANIP_BASELINE  ) 
) i_pipeline_s2_execute (
.g_clk            (g_clk            ), // global clock
.g_resetn         (g_resetn         ), // synchronous reset
.s2_rd            (s2_rd            ), // Destination register address
.s2_opr_a         (s2_opr_a         ), // Operand A
.s2_opr_b         (s2_opr_b         ), // Operand B
.s2_opr_c         (s2_opr_c         ), // Operand C
.s2_uop           (s2_uop           ), // Micro-op code
.s2_fu            (s2_fu            ), // Functional Unit
.s2_pw            (s2_pw            ), // IALU Pack width
.s2_trap          (s2_trap          ), // Raise a trap?
.s2_size          (s2_size          ), // Size of the instruction.
.s2_instr         (s2_instr         ), // The instruction word
.s2_busy          (s2_busy          ), // Can this stage accept new inputs?
.s2_valid         (s2_valid         ), // Is this input valid?
.flush            (s2_flush         ), // Flush this pipeline stage.
.fwd_s2_rd        (fwd_s2_rd        ), // Writeback stage destination reg.
.fwd_s2_wdata     (fwd_s2_wdata     ), // Write data for writeback stage.
.fwd_s2_load      (fwd_s2_load      ), // Writeback stage has load in it.
.fwd_s2_csr       (fwd_s2_csr       ), // Writeback stage has CSR op in it.
`ifdef RVFI
.rvfi_s2_rs1_rdata(rvfi_s2_rs1_rdata), // Source register data 1
.rvfi_s2_rs2_rdata(rvfi_s2_rs2_rdata), // Source register data 2
.rvfi_s2_rs3_rdata(rvfi_s2_rs3_rdata), // Source register data 2
.rvfi_s2_rs1_addr (rvfi_s2_rs1_addr ), // Source register address 1
.rvfi_s2_rs2_addr (rvfi_s2_rs2_addr ), // Source register address 2
.rvfi_s2_rs3_addr (rvfi_s2_rs3_addr ), // Source register address 2
.rvfi_s3_rs1_rdata(rvfi_s3_rs1_rdata), // Source register data 1
.rvfi_s3_rs2_rdata(rvfi_s3_rs2_rdata), // Source register data 2
.rvfi_s3_rs3_rdata(rvfi_s3_rs3_rdata), // Source register data 2
.rvfi_s3_rs1_addr (rvfi_s3_rs1_addr ), // Source register address 1
.rvfi_s3_rs2_addr (rvfi_s3_rs2_addr ), // Source register address 2
.rvfi_s3_rs3_addr (rvfi_s3_rs3_addr ), // Source register address 2
`endif // RVFI
.s3_rd            (s3_rd            ), // Destination register address
.s3_opr_a         (s3_opr_a         ), // Operand A
.s3_opr_b         (s3_opr_b         ), // Operand B
.s3_uop           (s3_uop           ), // Micro-op code
.s3_fu            (s3_fu            ), // Functional Unit
.s3_trap          (s3_trap          ), // Raise a trap?
.s3_size          (s3_size          ), // Size of the instruction.
.s3_instr         (s3_instr         ), // The instruction word
.s3_busy          (s3_busy          ), // Can this stage accept new inputs?
.s3_valid         (s3_valid         )  // Is this input valid?
);


//
// instance: frv_pipeline_memory
//
//  Memory stage of the pipeline, responsible making memory requests.
//
frv_pipeline_memory #(
.MMIO_BASE_ADDR(MMIO_BASE_ADDR),
.MMIO_BASE_MASK(MMIO_BASE_MASK)
) i_pipeline_s3_memory(
.g_clk            (g_clk            ), // global clock
.g_resetn         (g_resetn         ), // synchronous reset
.flush            (s3_flush         ), // Flush this pipeline stage.
.s3_rd            (s3_rd            ), // Destination register address
.s3_opr_a         (s3_opr_a         ), // Operand A
.s3_opr_b         (s3_opr_b         ), // Operand B
.s3_uop           (s3_uop           ), // Micro-op code
.s3_fu            (s3_fu            ), // Functional Unit
.s3_trap          (s3_trap          ), // Raise a trap?
.s3_size          (s3_size          ), // Size of the instruction.
.s3_instr         (s3_instr         ), // The instruction word
.s3_busy          (s3_busy          ), // Can this stage accept new inputs?
.s3_valid         (s3_valid         ), // Is this input valid?
.fwd_s3_rd        (fwd_s3_rd        ), // Writeback stage destination reg.
.fwd_s3_wdata     (fwd_s3_wdata     ), // Write data for writeback stage.
.fwd_s3_load      (fwd_s3_load      ), // Writeback stage has load in it.
.fwd_s3_csr       (fwd_s3_csr       ), // Writeback stage has CSR op in it.
`ifdef RVFI
.rvfi_s3_rs1_rdata(rvfi_s3_rs1_rdata), // Source register data 1
.rvfi_s3_rs2_rdata(rvfi_s3_rs2_rdata), // Source register data 2
.rvfi_s3_rs3_rdata(rvfi_s3_rs3_rdata), // Source register data 3
.rvfi_s3_rs1_addr (rvfi_s3_rs1_addr ), // Source register address 1
.rvfi_s3_rs2_addr (rvfi_s3_rs2_addr ), // Source register address 2
.rvfi_s3_rs3_addr (rvfi_s3_rs3_addr ), // Source register address 3
.rvfi_s4_rs1_rdata(rvfi_s4_rs1_rdata), // Source register data 1
.rvfi_s4_rs2_rdata(rvfi_s4_rs2_rdata), // Source register data 2
.rvfi_s4_rs3_rdata(rvfi_s4_rs3_rdata), // Source register data 3
.rvfi_s4_rs1_addr (rvfi_s4_rs1_addr ), // Source register address 1
.rvfi_s4_rs2_addr (rvfi_s4_rs2_addr ), // Source register address 2
.rvfi_s4_rs3_addr (rvfi_s4_rs3_addr ), // Source register address 3
.rvfi_s4_mem_wdata(rvfi_s4_mem_wdata), // Memory write data.
`endif // RVFI
.hold_lsu_req     (hold_lsu_req     ), // Disallow LSU requests when set.
.mmio_en          (mmio_en          ), // MMIO enable
.mmio_wen         (mmio_wen         ), // MMIO write enable
.mmio_addr        (mmio_addr        ), // MMIO address
.mmio_wdata       (mmio_wdata       ), // MMIO write data
.dmem_req         (dmem_req         ), // Start memory request
.dmem_wen         (dmem_wen         ), // Write enable
.dmem_strb        (dmem_strb        ), // Write strobe
.dmem_wdata       (dmem_wdata       ), // Write data
.dmem_addr        (dmem_addr        ), // Read/Write address
.dmem_gnt         (dmem_gnt         ), // request accepted
.s4_rd            (s4_rd            ), // Destination register address
.s4_opr_a         (s4_opr_a         ), // Operand A
.s4_opr_b         (s4_opr_b         ), // Operand B
.s4_uop           (s4_uop           ), // Micro-op code
.s4_fu            (s4_fu            ), // Functional Unit
.s4_trap          (s4_trap          ), // Raise a trap?
.s4_size          (s4_size          ), // Size of the instruction.
.s4_instr         (s4_instr         ), // The instruction word
.s4_busy          (s4_busy          ), // Can this stage accept new inputs?
.s4_valid         (s4_valid         )  // Is this input valid?
);


//
// instance: frv_pipeline_writeback
//
//  Responsible for finalising all instruction writeback behaviour.
//  - Jumps/control flow changes
//  - CSR accesses
//  - GPR writeback.
//
frv_pipeline_writeback #(
.FRV_PC_RESET_VALUE(FRV_PC_RESET_VALUE)
) i_pipeline_s4_writeback(
.g_clk            (g_clk            ), // global clock
.g_resetn         (g_resetn         ), // synchronous reset
`ifdef RVFI
.rvfi_valid       (rvfi_valid       ),
.rvfi_order       (rvfi_order       ),
.rvfi_insn        (rvfi_insn        ),
.rvfi_trap        (rvfi_trap        ),
.rvfi_halt        (rvfi_halt        ),
.rvfi_intr        (rvfi_intr        ),
.rvfi_mode        (rvfi_mode        ),
.rvfi_rs1_addr    (rvfi_rs1_addr    ),
.rvfi_rs2_addr    (rvfi_rs2_addr    ),
.rvfi_rs3_addr    (rvfi_rs3_addr    ),
.rvfi_rs1_rdata   (rvfi_rs1_rdata   ),
.rvfi_rs2_rdata   (rvfi_rs2_rdata   ),
.rvfi_rs3_rdata   (rvfi_rs3_rdata   ),
.rvfi_rd_addr     (rvfi_rd_addr     ),
.rvfi_rd_wdata    (rvfi_rd_wdata    ),
.rvfi_pc_rdata    (rvfi_pc_rdata    ),
.rvfi_pc_wdata    (rvfi_pc_wdata    ),
.rvfi_mem_addr    (rvfi_mem_addr    ),
.rvfi_mem_rmask   (rvfi_mem_rmask   ),
.rvfi_mem_wmask   (rvfi_mem_wmask   ),
.rvfi_mem_rdata   (rvfi_mem_rdata   ),
.rvfi_mem_wdata   (rvfi_mem_wdata   ),
.rvfi_s4_rs1_rdata(rvfi_s4_rs1_rdata), // Source register data 1
.rvfi_s4_rs2_rdata(rvfi_s4_rs2_rdata), // Source register data 2
.rvfi_s4_rs3_rdata(rvfi_s4_rs3_rdata), // Source register data 3
.rvfi_s4_rs1_addr (rvfi_s4_rs1_addr ), // Source register address 1
.rvfi_s4_rs2_addr (rvfi_s4_rs2_addr ), // Source register address 2
.rvfi_s4_rs3_addr (rvfi_s4_rs3_addr ), // Source register address 2
.rvfi_s4_mem_wdata(rvfi_s4_mem_wdata), // Memory write data.
`endif // RVFI
.s4_rd            (s4_rd            ), // Destination register address
.s4_opr_a         (s4_opr_a         ), // Operand A
.s4_opr_b         (s4_opr_b         ), // Operand B
.s4_uop           (s4_uop           ), // Micro-op code
.s4_fu            (s4_fu            ), // Functional Unit
.s4_trap          (s4_trap          ), // Raise a trap?
.s4_size          (s4_size          ), // Size of the instruction.
.s4_instr         (s4_instr         ), // The instruction word
.s4_busy          (s4_busy          ), // Can this stage accept new inputs?
.s4_valid         (s4_valid         ), // Are the stage inputs valid?
.fwd_s4_rd        (fwd_s4_rd        ), // Writeback stage destination reg.
.fwd_s4_wdata     (fwd_s4_wdata     ), // Write data for writeback stage.
.fwd_s4_load      (fwd_s4_load      ), // Writeback stage has load in it.
.fwd_s4_csr       (fwd_s4_csr       ), // Writeback stage has CSR op in it.
.gpr_wen          (gpr_wen          ), // GPR write enable.
.gpr_rd           (gpr_rd           ), // GPR destination register.
.gpr_wdata        (gpr_wdata        ), // GPR write data.
.int_trap_req     (int_trap_req     ), // Request WB stage trap an interrupt
.int_trap_cause   (int_trap_cause   ), // Cause of interrupt
.int_trap_ack     (int_trap_ack     ), // WB stage acknowledge the taken trap.
.trap_cpu         (trap_cpu         ), // A trap occured due to CPU
.trap_int         (trap_int         ), // A trap occured due to interrupt
.trap_cause       (trap_cause       ), // A trap occured due to interrupt
.trap_mtval       (trap_mtval       ), // Value associated with the trap.
.trap_pc          (trap_pc          ), // PC value associated with the trap.
.exec_mret        (exec_mret        ), // MRET instruction executed.
.csr_mepc         (csr_mepc         ),
.csr_mtvec        (csr_mtvec        ),
.trs_pc           (trs_pc           ), // Trace program counter.
.trs_instr        (trs_instr        ), // Trace instruction.
.trs_valid        (trs_valid        ), // Trace output valid.
.csr_en           (csr_en           ), // CSR Access Enable
.csr_wr           (csr_wr           ), // CSR Write Enable
.csr_wr_set       (csr_wr_set       ), // CSR Write - Set
.csr_wr_clr       (csr_wr_clr       ), // CSR Write - Clear
.csr_addr         (csr_addr         ), // Address of the CSR to access.
.csr_wdata        (csr_wdata        ), // Data to be written to a CSR
.csr_rdata        (csr_rdata        ), // CSR read data
.cf_req           (cf_req           ), // Control flow change request
.cf_target        (cf_target        ), // Control flow change target
.cf_ack           (cf_ack           ), // Control flow change acknowledge.
.hold_lsu_req     (hold_lsu_req     ), // Don't make LSU requests yet.
.mmio_rdata       (mmio_rdata       ), // MMIO read data
.mmio_error       (mmio_error       ), // MMIO error
.dmem_recv        (dmem_recv        ), // Instruction memory recieve response.
.dmem_ack         (dmem_ack         ), // Data memory ack response.
.dmem_error       (dmem_error       ), // Error
.dmem_rdata       (dmem_rdata       )  // Read data
);

//
// instance: frv_csrs
//
//  Responsible for keeping control/status registers up to date.
//
frv_csrs #(
.XC_CLASS_BASELINE  (XC_CLASS_BASELINE  ),
.XC_CLASS_RANDOMNESS(XC_CLASS_RANDOMNESS),
.XC_CLASS_MEMORY    (XC_CLASS_MEMORY    ),
.XC_CLASS_BIT       (XC_CLASS_BIT       ),
.XC_CLASS_PACKED    (XC_CLASS_PACKED    ),
.XC_CLASS_MULTIARITH(XC_CLASS_MULTIARITH),
.XC_CLASS_AES       (XC_CLASS_AES       ),
.XC_CLASS_SHA2      (XC_CLASS_SHA2      ),
.XC_CLASS_SHA3      (XC_CLASS_SHA3      ),
.BITMANIP_BASELINE  (BITMANIP_BASELINE  ) 
) i_csrs (
.g_clk            (g_clk            ), // global clock
.g_resetn         (g_resetn         ), // synchronous reset
.csr_en           (csr_en           ), // CSR Access Enable
.csr_wr           (csr_wr           ), // CSR Write Enable
.csr_wr_set       (csr_wr_set       ), // CSR Write - Set
.csr_wr_clr       (csr_wr_clr       ), // CSR Write - Clear
.csr_addr         (csr_addr         ), // Address of the CSR to access.
.csr_wdata        (csr_wdata        ), // Data to be written to a CSR
.csr_rdata        (csr_rdata        ), // CSR read data
.csr_mepc         (csr_mepc         ), // Current MEPC.
.csr_mtvec        (csr_mtvec        ), // Current MTVEC.
.exec_mret        (exec_mret        ), // MRET instruction executed.
.mstatus_mie      (mstatus_mie      ), // Global interrupt enable.
.mie_meie         (mie_meie         ), // External interrupt enable.
.mie_mtie         (mie_mtie         ), // Timer interrupt enable.
.mie_msie         (mie_msie         ), // Software interrupt enable.
.mip_meip         (mip_meip         ), // External interrupt pending
.mip_mtip         (mip_mtip         ), // Timer interrupt pending
.mip_msip         (mip_msip         ), // Software interrupt pending
.ctr_time         (ctr_time         ), // The time counter value.
.ctr_cycle        (ctr_cycle        ), // The cycle counter value.
.ctr_instret      (ctr_instret      ), // The instret counter value.
.inhibit_cy       (inhibit_cy       ), // Stop cycle counter incrementing.
.inhibit_tm       (inhibit_tm       ), // Stop time counter incrementing.
.inhibit_ir       (inhibit_ir       ), // Stop instret incrementing.
.trap_cpu         (trap_cpu         ), // A trap occured due to CPU
.trap_int         (trap_int         ), // A trap occured due to interrupt
.trap_cause       (trap_cause       ), // Cause of a trap.
.trap_mtval       (trap_mtval       ), // Value associated with the trap.
.trap_pc          (trap_pc          )  // PC value associated with the trap.
);


//
// instance: frv_gprs
//
//  The general purpose register file.
//
frv_gprs #(
.BRAM_REGFILE(BRAM_REGFILE)
) i_gprs (
.g_clk      (g_clk          ), //
.g_resetn   (g_resetn       ), //
.rs1_addr   (s1_rs1_addr    ), // Source register 1 address
.rs1_data   (s1_rs1_rdata   ), // Source register 1 read data
.rs2_addr   (s1_rs2_addr    ), // Source register 2 address
.rs2_data   (s1_rs2_rdata   ), // Source register 2 read data
.rs3_addr   (s1_rs3_addr    ), // Source register 3 address
.rs3_data   (s1_rs3_rdata   ), // Source register 3 read data
.rd_wen     (gpr_wen        ), // Destination register write enable
.rd_addr    (gpr_rd         ), // Destination register address
.rd_data    (gpr_wdata      )  // Destination register write data
);

endmodule

