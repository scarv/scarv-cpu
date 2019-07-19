
//
// module: frv_pipeline_dispatch
//
//  Part of the backend, responsible for clearing pipeline bubbles, RAW
//  hazards and gathering operands ready for execution.
//
module frv_pipeline_dispatch (

input              g_clk           , // global clock
input              g_resetn        , // synchronous reset

output wire        s2_p_busy       , // Can this stage accept new inputs?
input  wire        s2_p_valid      , // Is this input valid?
input  wire [ 4:0] s2_rd           , // Destination register address
input  wire [ 4:0] s2_rs1          , // Source register address 1
input  wire [ 4:0] s2_rs2          , // Source register address 2
input  wire [31:0] s2_imm          , // Decoded immediate
input  wire [31:0] s2_pc           , // Program counter
input  wire [ 4:0] s2_uop          , // Micro-op code
input  wire [ 4:0] s2_fu           , // Functional Unit
input  wire        s2_trap         , // Raise a trap?
input  wire [ 7:0] s2_opr_src      , // Operand sources for dispatch stage.
input  wire [ 1:0] s2_size         , // Size of the instruction.
input  wire [31:0] s2_instr        , // The instruction word

input  wire        flush           , // Flush this pipeline stage.

input  wire [ 4:0] fwd_s4_rd       , // Writeback stage destination reg.
input  wire [XL:0] fwd_s4_wdata    , // Write data for writeback stage.
input  wire        fwd_s4_load     , // Writeback stage has load in it.
input  wire        fwd_s4_csr      , // Writeback stage has CSR op in it.

input  wire [ 4:0] fwd_s3_rd       , // Writeback stage destination reg.
input  wire [XL:0] fwd_s3_wdata    , // Write data for writeback stage.
input  wire        fwd_s3_load     , // Writeback stage has load in it.
input  wire        fwd_s3_csr      , // Writeback stage has CSR op in it.

input  wire        gpr_wen         , // GPR write enable.
input  wire [ 4:0] gpr_rd          , // GPR destination register.
input  wire [XL:0] gpr_wdata       , // GPR write data.

output wire [ 4:0] s3_rd           , // Destination register address
output wire [XL:0] s3_opr_a        , // Operand A
output wire [XL:0] s3_opr_b        , // Operand B
output wire [XL:0] s3_opr_c        , // Operand C
output wire [31:0] s3_pc           , // Program counter
output wire [ 4:0] s3_uop          , // Micro-op code
output wire [ 4:0] s3_fu           , // Functional Unit
output wire        s3_trap         , // Raise a trap?
output wire [ 1:0] s3_size         , // Size of the instruction.
output wire [31:0] s3_instr        , // The instruction word
input  wire        s3_p_busy       , // Can this stage accept new inputs?
output wire        s3_p_valid        // Is this input valid?

);

// Common core parameters and constants
`include "frv_common.vh"

// Use an FPGA BRAM style register file.
parameter BRAM_REGFILE = 0;

// -------------------------------------------------------------------------

wire [ 4:0] n_s3_rd      = s2_rd    ; // Destination register address
wire [31:0] n_s3_pc      = s2_pc    ; // Program counter
wire [ 4:0] n_s3_uop     = s2_uop   ; // Micro-op code
wire [ 4:0] n_s3_fu      = s2_fu    ; // Functional Unit
wire [ 1:0] n_s3_size    = s2_size  ; // Size of the instruction.
wire [31:0] n_s3_instr   = s2_instr ; // The instruction word
wire [XL:0] n_s3_opr_a              ; // Operand A
wire [XL:0] n_s3_opr_b              ; // Operand B
wire [XL:0] n_s3_opr_c              ; // Operand C
wire        n_s3_trap               ; // Raise a trap?

//
// Any extra decode / operand packing/unpacking.
// -------------------------------------------------------------------------

wire [31:0] csr_addr = {20'b0, s2_imm[31:20]};
wire [31:0] csr_imm  = {{27{s2_rs1[4]}}, s2_rs1};

//
// Bubbling and stalling
// -------------------------------------------------------------------------

wire   dis_bubble   =
((               fwd_s4_csr) && (s2_rs1 == fwd_s4_rd || s2_rs2 == fwd_s4_rd))  ||
((fwd_s3_load || fwd_s3_csr) && (s2_rs1 == fwd_s3_rd || s2_rs2 == fwd_s3_rd))   ;

wire      p_busy    ;

assign s2_p_busy    = dis_bubble || p_busy;

wire      p_valid   = dis_bubble || s2_p_valid;

//
// GPR data sourcing
// -------------------------------------------------------------------------

wire [XL:0] s2_rs1_data             ; // Current read data from GPRs
wire [XL:0] s2_rs2_data             ; // 

// Actual register source values with forwarding taken into account.
wire [XL:0] dis_rs1                 ; // Dispatch stage value of RS1
wire [XL:0] dis_rs2                 ; // Dispatch stage value of RS2

wire        fwd_s3_rs1 = s2_rs1 == fwd_s3_rd && |s2_rs1;
wire        fwd_s4_rs1 = s2_rs1 == fwd_s4_rd && |s2_rs1;
;
wire        fwd_s3_rs2 = s2_rs2 == fwd_s3_rd && |s2_rs2;
wire        fwd_s4_rs2 = s2_rs2 == fwd_s4_rd && |s2_rs2;

assign dis_rs1 =
     fwd_s3_rs1 ? fwd_s3_wdata   :
     fwd_s4_rs1 ? fwd_s4_wdata   :
                  s2_rs1_data    ;

assign dis_rs2 =
     fwd_s3_rs2 ? fwd_s3_wdata   :
     fwd_s4_rs2 ? fwd_s4_wdata   :
                  s2_rs2_data    ;

//
// PC offset computation
// -------------------------------------------------------------------------

wire [XL:0] pc_plus_imm             ; // Sum of PC and immediate.

assign      pc_plus_imm = s2_pc + s2_imm;

//
// Operand Source decoding
// -------------------------------------------------------------------------

// Operand A sourcing.
wire opra_src_rs1  = s2_opr_src[DIS_OPRA_RS1 ];
wire opra_src_pcim = s2_opr_src[DIS_OPRA_PCIM];
wire opra_src_csri = s2_opr_src[DIS_OPRA_CSRI];

assign n_s3_opr_a = 
    {XLEN{opra_src_rs1    }} & dis_rs1        |
    {XLEN{opra_src_pcim   }} & pc_plus_imm    |
    {XLEN{opra_src_csri   }} & csr_imm        ;

// Operand B sourcing.
wire oprb_src_rs2  = s2_opr_src[DIS_OPRB_RS2 ];
wire oprb_src_imm  = s2_opr_src[DIS_OPRB_IMM ];

assign n_s3_opr_b =
    {XLEN{oprb_src_rs2    }} & dis_rs2        |
    {XLEN{oprb_src_imm    }} & s2_imm         ;

// Operand C sourcing.
wire oprc_src_rs2  = s2_opr_src[DIS_OPRC_RS2 ];
wire oprc_src_csra = s2_opr_src[DIS_OPRC_CSRA];
wire oprc_src_pcim = s2_opr_src[DIS_OPRC_PCIM];

assign n_s3_opr_c = 
    {XLEN{oprc_src_rs2    }} & dis_rs2        |
    {XLEN{oprc_src_csra   }} & csr_addr       |
    {XLEN{oprc_src_pcim   }} & pc_plus_imm    ;

//
// Submodule instances
// -------------------------------------------------------------------------

frv_gprs #(
.BRAM_REGFILE(BRAM_REGFILE)
) i_gprs (
.g_clk      (g_clk      ), //
.g_resetn   (g_resetn   ), //
.rs1_addr   (s2_rs1     ), // Source register 1 address
.rs1_data   (s2_rs1_data), // Source register 1 read data
.rs2_addr   (s2_rs2     ), // Source register 2 address
.rs2_data   (s2_rs2_data), // Source register 2 read data
.rd_wen     (gpr_wen    ), // Destination register write enable
.rd_addr    (gpr_rd     ), // Destination register address
.rd_data    (gpr_wdata  )  // Destination register write data
);

//
// Pipeline Register
// -------------------------------------------------------------------------

localparam PIPE_REG_W = 178;

wire pipe_reg_flush = flush || (p_valid && !p_busy && dis_bubble);

wire [PIPE_REG_W-1:0] pipe_reg_out;

wire [PIPE_REG_W-1:0] pipe_reg_in = {
    n_s3_rd   ,
    n_s3_pc   ,
    n_s3_uop  ,
    n_s3_fu   ,
    n_s3_size ,
    n_s3_instr,
    n_s3_opr_a,
    n_s3_opr_b,
    n_s3_opr_c,
    n_s3_trap 
};

assign {
    s3_rd   ,
    s3_pc   ,
    s3_uop  ,
    s3_fu   ,
    s3_size ,
    s3_instr,
    s3_opr_a,
    s3_opr_b,
    s3_opr_c,
    s3_trap 
} = pipe_reg_out;

frv_pipeline_register #(
.RLEN(PIPE_REG_W),
.BUFFER_HANDSHAKE(1'b0)
) i_dispatch_pipe_reg(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (pipe_reg_in      ), // Input data from stage N
.i_valid  (p_valid          ), // Input data valid?
.o_busy   (p_busy           ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Most recent data into the stage.
.flush    (pipe_reg_flush   ), // Flush the contents of the pipeline
.o_data   (pipe_reg_out     ), // Output data for stage N+1
.o_valid  (s3_p_valid       ), // Input data from stage N valid?
.i_busy   (s3_p_busy        )  // Stage N+1 ready to continue?
);

endmodule


