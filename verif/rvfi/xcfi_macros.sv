
`ifndef __XCFI_MACROS__
`define __XCFI_MACROS__

`define XCFI_TRACE_INPUTS \
    input [NRET          - 1 : 0] rvfi_valid       , \
    input [NRET * 64     - 1 : 0] rvfi_order       , \
    input [NRET * ILEN   - 1 : 0] rvfi_insn        , \
    input [NRET          - 1 : 0] rvfi_trap        , \
    input [NRET          - 1 : 0] rvfi_halt        , \
    input [NRET          - 1 : 0] rvfi_intr        , \
    input [NRET *    2   - 1 : 0] rvfi_mode        , \
    input [NRET *    2   - 1 : 0] rvfi_ixl         , \
    input [NRET *    5   - 1 : 0] rvfi_rs1_addr    , \
    input [NRET *    5   - 1 : 0] rvfi_rs2_addr    , \
    input [NRET *    5   - 1 : 0] rvfi_rs3_addr    , \
    input [NRET * XLEN   - 1 : 0] rvfi_rs1_rdata   , \
    input [NRET * XLEN   - 1 : 0] rvfi_rs2_rdata   , \
    input [NRET * XLEN   - 1 : 0] rvfi_rs3_rdata   , \
    input [NRET *    5   - 1 : 0] rvfi_rd_addr     , \
    input [NRET * XLEN   - 1 : 0] rvfi_rd_wdata    , \
    input [NRET * XLEN   - 1 : 0] rvfi_pc_rdata    , \
    input [NRET * XLEN   - 1 : 0] rvfi_pc_wdata    , \
    input [NRET * XLEN   - 1 : 0] rvfi_mem_addr    , \
    input [NRET * XLEN/8 - 1 : 0] rvfi_mem_rmask   , \
    input [NRET * XLEN/8 - 1 : 0] rvfi_mem_wmask   , \
    input [NRET * XLEN   - 1 : 0] rvfi_mem_rdata   , \
    input [NRET * XLEN   - 1 : 0] rvfi_mem_wdata   

`define XCFI_TRACE_OUTPUTS \
    output [NRET          - 1 : 0] rvfi_valid       , \
    output [NRET * 64     - 1 : 0] rvfi_order       , \
    output [NRET * ILEN   - 1 : 0] rvfi_insn        , \
    output [NRET          - 1 : 0] rvfi_trap        , \
    output [NRET          - 1 : 0] rvfi_halt        , \
    output [NRET          - 1 : 0] rvfi_intr        , \
    output [NRET *    2   - 1 : 0] rvfi_mode        , \
    output [NRET *    2   - 1 : 0] rvfi_ixl         , \
    output [NRET *    5   - 1 : 0] rvfi_rs1_addr    , \
    output [NRET *    5   - 1 : 0] rvfi_rs2_addr    , \
    output [NRET *    5   - 1 : 0] rvfi_rs3_addr    , \
    output [NRET * XLEN   - 1 : 0] rvfi_rs1_rdata   , \
    output [NRET * XLEN   - 1 : 0] rvfi_rs2_rdata   , \
    output [NRET * XLEN   - 1 : 0] rvfi_rs3_rdata   , \
    output [NRET *    5   - 1 : 0] rvfi_rd_addr     , \
    output [NRET * XLEN   - 1 : 0] rvfi_rd_wdata    , \
    output [NRET * XLEN   - 1 : 0] rvfi_pc_rdata    , \
    output [NRET * XLEN   - 1 : 0] rvfi_pc_wdata    , \
    output [NRET * XLEN   - 1 : 0] rvfi_mem_addr    , \
    output [NRET * XLEN/8 - 1 : 0] rvfi_mem_rmask   , \
    output [NRET * XLEN/8 - 1 : 0] rvfi_mem_wmask   , \
    output [NRET * XLEN   - 1 : 0] rvfi_mem_rdata   , \
    output [NRET * XLEN   - 1 : 0] rvfi_mem_wdata   

`define XCFI_TRACE_WIRES \
    wire [NRET          - 1 : 0] rvfi_valid       ; \
    wire [NRET * 64     - 1 : 0] rvfi_order       ; \
    wire [NRET * ILEN   - 1 : 0] rvfi_insn        ; \
    wire [NRET          - 1 : 0] rvfi_trap        ; \
    wire [NRET          - 1 : 0] rvfi_halt        ; \
    wire [NRET          - 1 : 0] rvfi_intr        ; \
    wire [NRET *    2   - 1 : 0] rvfi_mode        ; \
    wire [NRET *    2   - 1 : 0] rvfi_ixl         ; \
    wire [NRET *    5   - 1 : 0] rvfi_rs1_addr    ; \
    wire [NRET *    5   - 1 : 0] rvfi_rs2_addr    ; \
    wire [NRET *    5   - 1 : 0] rvfi_rs3_addr    ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_rs1_rdata   ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_rs2_rdata   ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_rs3_rdata   ; \
    wire [NRET *    5   - 1 : 0] rvfi_rd_addr     ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_rd_wdata    ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_pc_rdata    ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_pc_wdata    ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_mem_addr    ; \
    wire [NRET * XLEN/8 - 1 : 0] rvfi_mem_rmask   ; \
    wire [NRET * XLEN/8 - 1 : 0] rvfi_mem_wmask   ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_mem_rdata   ; \
    wire [NRET * XLEN   - 1 : 0] rvfi_mem_wdata   ;

`define XCFI_TRACE_CONNECT \
    .rvfi_valid       (rvfi_valid       ), \
    .rvfi_order       (rvfi_order       ), \
    .rvfi_insn        (rvfi_insn        ), \
    .rvfi_trap        (rvfi_trap        ), \
    .rvfi_halt        (rvfi_halt        ), \
    .rvfi_intr        (rvfi_intr        ), \
    .rvfi_mode        (rvfi_mode        ), \
    .rvfi_ixl         (rvfi_ixl         ), \
    .rvfi_rs1_addr    (rvfi_rs1_addr    ), \
    .rvfi_rs2_addr    (rvfi_rs2_addr    ), \
    .rvfi_rs3_addr    (rvfi_rs3_addr    ), \
    .rvfi_rs1_rdata   (rvfi_rs1_rdata   ), \
    .rvfi_rs2_rdata   (rvfi_rs2_rdata   ), \
    .rvfi_rs3_rdata   (rvfi_rs3_rdata   ), \
    .rvfi_rd_addr     (rvfi_rd_addr     ), \
    .rvfi_rd_wdata    (rvfi_rd_wdata    ), \
    .rvfi_pc_rdata    (rvfi_pc_rdata    ), \
    .rvfi_pc_wdata    (rvfi_pc_wdata    ), \
    .rvfi_mem_addr    (rvfi_mem_addr    ), \
    .rvfi_mem_rmask   (rvfi_mem_rmask   ), \
    .rvfi_mem_wmask   (rvfi_mem_wmask   ), \
    .rvfi_mem_rdata   (rvfi_mem_rdata   ), \
    .rvfi_mem_wdata   (rvfi_mem_wdata   ) 

`define XCFI_SPEC_OUTPUTS \
    output                  spec_valid     , \
    output                  spec_trap      , \
    output [         4 : 0] spec_rs1_addr  , \
    output [         4 : 0] spec_rs2_addr  , \
    output [         4 : 0] spec_rs3_addr  , \
    output [         4 : 0] spec_rd_addr   , \
    output [XLEN   - 1 : 0] spec_rd_wdata  , \
    output [XLEN   - 1 : 0] spec_pc_wdata  , \
    output [XLEN   - 1 : 0] spec_mem_addr  , \
    output [XLEN/8 - 1 : 0] spec_mem_rmask , \
    output [XLEN/8 - 1 : 0] spec_mem_wmask , \
    output [XLEN   - 1 : 0] spec_mem_wdata   \

`define XCFI_SPEC_CONNECT \
    .spec_valid     (spec_valid     ), \
    .spec_trap      (spec_trap      ), \
    .spec_rs1_addr  (spec_rs1_addr  ), \
    .spec_rs2_addr  (spec_rs2_addr  ), \
    .spec_rs3_addr  (spec_rs3_addr  ), \
    .spec_rd_addr   (spec_rd_addr   ), \
    .spec_rd_wdata  (spec_rd_wdata  ), \
    .spec_pc_wdata  (spec_pc_wdata  ), \
    .spec_mem_addr  (spec_mem_addr  ), \
    .spec_mem_rmask (spec_mem_rmask ), \
    .spec_mem_wmask (spec_mem_wmask ), \
    .spec_mem_wdata (spec_mem_wdata )  \

`define XCFI_XC_CLASS_PARAMETERS                            \
parameter XC_CLASS_BASELINE   = 1'b1;                       \
parameter XC_CLASS_RANDOMNESS = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_MEMORY     = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_BIT        = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_PACKED     = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_MULTIARITH = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_AES        = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_SHA2       = 1'b1 && XC_CLASS_BASELINE;  \
parameter XC_CLASS_SHA3       = 1'b1 && XC_CLASS_BASELINE;

`define XCFI_BITMANIP_CLASS_PARAMETERS                      \
parameter BITMANIP_BASELINE   = 1'b1;

`define XCFI_INSN_CHECK_COMMON \
    parameter ILEN = 32                    ; \
    parameter NRET = 1                     ; \
    parameter XLEN = 32                    ; \
    parameter XL   = XLEN - 1              ; \
    wire [31:0] d_data = rvfi_insn;          \
    `XCFI_XC_CLASS_PARAMETERS                \
    `XCFI_BITMANIP_CLASS_PARAMETERS          \
    `include "frv_common.vh"                 \
    `include "frv_pipeline_decode.vh"        \
    `include "xcfi_shared.vh"        

`define RS1            rvfi_rs1_rdata
`define RS2            rvfi_rs2_rdata
`define RS3            rvfi_rs3_rdata
`define RD             rvfi_rd_wdata 

`define FIELD_RS1_ADDR d_data[19:15]
`define FIELD_RS2_ADDR d_data[24:20]
`define FIELD_RS3_ADDR d_data[31:27]
`define FIELD_RD_ADDR  d_data[11: 7]

`endif
