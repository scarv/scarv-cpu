
//
// module: frv_asi 
//
//  Handles all algorithm specific instructions.
//  - AES
//  - SHA2
//  - SHA3
//
module frv_asi (

input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input               asi_valid       , // Stall this stage
output              asi_ready       , // stage ready to progress

input  wire         asi_flush_aessub, // Flush any state in AES sub submodule
input  wire         asi_flush_aesmix, // Flush any state in AES mix submodule
input  wire [31:0]  asi_flush_data  , // Data to flush into the submodules.

input  wire [OP:0]  asi_uop         , // Exactly which operation to perform.
input  wire [XL:0]  asi_rs1         , // Source register 1
input  wire [XL:0]  asi_rs2         , // Source register 2
input  wire [ 1:0]  asi_shamt       , // Shift amount for SHA3 instructions.

output wire [XL:0]  asi_result        // Instruction result.

);

`include "frv_common.vh"

//
// XCrypto feature class config bits.
parameter XC_CLASS_AES        = 1'b1;
parameter XC_CLASS_SHA2       = 1'b1;
parameter XC_CLASS_SHA3       = 1'b1;

// Single cycle implementations of AES instructions?
parameter AES_SUB_FAST = 1'b1;
parameter AES_MIX_FAST = 1'b1;

//
// Exact Instruction Decoding
// -------------------------------------------------------------

wire insn_aes           = asi_valid && asi_uop[OP:OP-1] == ASI_AES ;
wire insn_aes_sub       = XC_CLASS_AES && insn_aes  && !asi_uop[2];
wire insn_aes_mix       = XC_CLASS_AES && insn_aes  &&  asi_uop[2];
wire insn_sha2          = XC_CLASS_SHA2 && asi_valid && asi_uop[OP:OP-1] == ASI_SHA2;
wire insn_sha3          = XC_CLASS_SHA3 && asi_valid && asi_uop[OP:OP-1] == ASI_SHA3;

wire insn_aessub_enc    = asi_valid && asi_uop == ASI_AESSUB_ENC   ;
wire insn_aessub_encrot = asi_valid && asi_uop == ASI_AESSUB_ENCROT;
wire insn_aessub_dec    = asi_valid && asi_uop == ASI_AESSUB_DEC   ;
wire insn_aessub_decrot = asi_valid && asi_uop == ASI_AESSUB_DECROT;
wire insn_aesmix_enc    = asi_valid && asi_uop == ASI_AESMIX_ENC   ;
wire insn_aesmix_dec    = asi_valid && asi_uop == ASI_AESMIX_DEC   ;
wire insn_sha3_xy       = asi_valid && asi_uop == ASI_SHA3_XY      ;
wire insn_sha3_x1       = asi_valid && asi_uop == ASI_SHA3_X1      ;
wire insn_sha3_x2       = asi_valid && asi_uop == ASI_SHA3_X2      ;
wire insn_sha3_x4       = asi_valid && asi_uop == ASI_SHA3_X4      ;
wire insn_sha3_yx       = asi_valid && asi_uop == ASI_SHA3_YX      ;
wire insn_sha256_s0     = asi_valid && asi_uop == ASI_SHA256_S0    ;
wire insn_sha256_s1     = asi_valid && asi_uop == ASI_SHA256_S1    ;
wire insn_sha256_s2     = asi_valid && asi_uop == ASI_SHA256_S2    ;
wire insn_sha256_s3     = asi_valid && asi_uop == ASI_SHA256_S3    ;

//
// Input Gating
// -------------------------------------------------------------

wire [XL:0] sha2_rs1    = {XLEN{insn_sha2}} & asi_rs1;
wire [ 1:0] sha2_ss     = asi_uop[1:0];

wire [XL:0] aes_sub_rs1 = {XLEN{insn_aes_sub}} & asi_rs1;
wire [XL:0] aes_sub_rs2 = {XLEN{insn_aes_sub}} & asi_rs2;
wire        aes_sub_enc = !asi_uop[0];
wire        aes_sub_rot =  asi_uop[1];

wire [XL:0] aes_mix_rs1 = {XLEN{insn_aes_mix}} & asi_rs1;
wire [XL:0] aes_mix_rs2 = {XLEN{insn_aes_mix}} & asi_rs2;
wire        aes_mix_enc = !asi_uop[0];

//
// Result Selection
// -------------------------------------------------------------

wire [XL:0] result_aessub   ;
wire [XL:0] result_aesmix   ;
wire [XL:0] result_sha2     ;
wire [XL:0] result_sha3     ;

assign asi_result =
    {32{insn_aes_mix }} & result_aesmix |
    {32{insn_aes_sub }} & result_aessub |
    {32{insn_sha2    }} & result_sha2   |
    {32{insn_sha3    }} & result_sha3   ;

wire aes_sub_ready;
wire aes_mix_ready;

assign asi_ready = insn_sha2                       || 
                   insn_sha3                       || 
                   (insn_aes_sub && aes_sub_ready) ||
                   (insn_aes_mix && aes_mix_ready) ;

//
// Submodule Instances
// -------------------------------------------------------------

//
// instance: xc_sha3
//
//  Implements the specialised sha3 indexing functions.
//  - All of the f_* inputs must be 1-hot.
//
xc_sha3 i_xc_sha3(
.rs1      (asi_rs1      ), // Input source register 1
.rs2      (asi_rs2      ), // Input source register 2
.shamt    (asi_shamt    ), // Post-Shift Amount
.f_xy     (insn_sha3_xy ), // xc.sha3.xy instruction function
.f_x1     (insn_sha3_x1 ), // xc.sha3.x1 instruction function
.f_x2     (insn_sha3_x2 ), // xc.sha3.x2 instruction function
.f_x4     (insn_sha3_x4 ), // xc.sha3.x4 instruction function
.f_yx     (insn_sha3_yx ), // xc.sha3.yx instruction function
.result   (result_sha3  )  //
);

//
// instance: xc_sha256
//
//  Implements the light-weight SHA256 instruction functions.
//
xc_sha256 i_xc_sha256 (
.rs1   (sha2_rs1    ), // Input source register 1
.ss    (sha2_ss     ), // Exactly which transformation to perform?
.result(result_sha2 )  // 
);

//
// instance : xc_aessub
//
//  Implements the lightweight AES SubBytes instructions.
//
xc_aessub  #(
.FAST(AES_SUB_FAST)
)i_xc_aessub(
.clock (g_clk           ),
.reset (!g_resetn       ),
.flush (asi_flush_aessub),
.flush_data(asi_flush_data),
.valid (insn_aes_sub    ), // Are the inputs valid?
.rs1   (aes_sub_rs1     ), // Input source register 1
.rs2   (aes_sub_rs2     ), // Input source register 2
.enc   (aes_sub_enc     ), // Perform encrypt (set) or decrypt (clear).
.rot   (aes_sub_rot     ), // Perform encrypt (set) or decrypt (clear).
.ready (aes_sub_ready   ), // Is the instruction complete?
.result(result_aessub   )  // 
);

//
// instance: xc_aesmix
//
//  Implements the lightweight AES MixColumns instructions.
//
xc_aesmix #(
.FAST(AES_MIX_FAST)
) i_xc_aesmix(
.clock (g_clk           ),
.reset (!g_resetn       ),
.valid (insn_aes_mix    ), // Are the inputs valid?
.flush (asi_flush_aesmix),
.flush_data(asi_flush_data),
.rs1   (aes_mix_rs1     ), // Input source register 1
.rs2   (aes_mix_rs2     ), // Input source register 2
.enc   (aes_mix_enc     ), // Perform encrypt (set) or decrypt (clear).
.ready (aes_mix_ready   ), // Is the instruction complete?
.result(result_aesmix   )  // 
);

endmodule
