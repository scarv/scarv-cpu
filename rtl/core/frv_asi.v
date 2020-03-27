
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

//
// Which AES variant should we use:
//
// 1. Simple 4-wide SBox and MixColumns instruction
// 2. Tillich/Großschädl
// 3. TTable based / riscv-crypto proposal.
// 4. Tiled
//
parameter XC_AES_VARIANT      = 1;

localparam XC_AES_VARIANT_V1  = XC_AES_VARIANT == 1;
localparam XC_AES_VARIANT_TG  = XC_AES_VARIANT == 2;
localparam XC_AES_VARIANT_TT  = XC_AES_VARIANT == 3;
localparam XC_AES_VARIANT_TI  = XC_AES_VARIANT == 4;

// Single cycle implementations of AES instructions?
parameter AES_SUB_FAST = 1'b1;
parameter AES_MIX_FAST = 1'b1;

//
// Exact Instruction Decoding
// -------------------------------------------------------------

wire insn_aes           = asi_valid && asi_uop[OP:OP-1] == ASI_AES ;
wire insn_sha2          = XC_CLASS_SHA2 && asi_valid && asi_uop[OP:OP-1] == ASI_SHA2;
wire insn_sha3          = XC_CLASS_SHA3 && asi_valid && asi_uop[OP:OP-1] == ASI_SHA3;

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


//
// Result Selection
// -------------------------------------------------------------

wire [XL:0] result_aes      ;
wire [XL:0] result_sha2     ;
wire [XL:0] result_sha3     ;

assign asi_result =
    {32{insn_aes     }} & result_aes    |
    {32{insn_sha2    }} & result_sha2   |
    {32{insn_sha3    }} & result_sha3   ;

wire aes_ready;

assign asi_ready = insn_sha2                       || 
                   insn_sha3                       || 
                   (insn_aes     && aes_ready    ) ;

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


generate if(XC_AES_VARIANT_V1) begin // Simple Sub/Mix

wire   insn_sub_enc = asi_valid && asi_uop == ASI_SAES_V1_ENCS;
wire   insn_sub_dec = asi_valid && asi_uop == ASI_SAES_V1_DECS;
wire   insn_mix_enc = asi_valid && asi_uop == ASI_SAES_V1_ENCM;
wire   insn_mix_dec = asi_valid && asi_uop == ASI_SAES_V1_DECM;

wire   aes_dec      = insn_sub_dec || insn_mix_dec;
wire   aes_mix      = insn_mix_dec || insn_mix_enc;

aes_v1 i_aes_v1 (
.g_clk      (g_clk      ),
.g_resetn   (g_resetn   ),
.valid      (insn_aes   ), // Input data valid
.dec        (aes_dec    ), // Encrypt (0) or decrypt (1)
.mix        (aes_mix    ), // Do MixColumns (1) or SubBytes (0)
.rs1        (asi_rs1    ), // Input source register
.ready      (aes_ready  ), // Finished computing?
.rd         (result_aes )  // Output destination register value.
);

end else if(XC_AES_VARIANT_TG) begin // Tillich/Grochadl

wire   insn_sub_enc = asi_valid && asi_uop == ASI_SAES_V2_SUB_ENC;
wire   insn_sub_dec = asi_valid && asi_uop == ASI_SAES_V2_SUB_DEC;
wire   insn_mix_enc = asi_valid && asi_uop == ASI_SAES_V2_MIX_ENC;
wire   insn_mix_dec = asi_valid && asi_uop == ASI_SAES_V2_MIX_DEC;

wire   aes_sub      = insn_sub_enc || insn_sub_dec;
wire   aes_enc      = insn_sub_enc || insn_mix_enc;

aes_v2 i_aes_v2 (
.g_clk    (g_clk        ),
.g_resetn (g_resetn     ),
.valid    (insn_aes     ), // Are the inputs valid?
.sub      (aes_sub      ), // Sub if set, Mix if clear
.enc      (aes_enc      ), // Perform encrypt (set) or decrypt (clear).
.rs1      (asi_rs1      ), // Input source register 1
.rs2      (asi_rs2      ), // Input source register 2
.ready    (aes_ready    ), // Is the instruction complete?
.rd       (result_aes   )  // 
);

end else if(XC_AES_VARIANT_TT) begin // TTable

wire   insn_encs  = asi_valid && asi_uop == ASI_SAES_V3_ENCS ;
wire   insn_decs  = asi_valid && asi_uop == ASI_SAES_V3_DECS ;
wire   insn_encsm = asi_valid && asi_uop == ASI_SAES_V3_ENCSM;
wire   insn_decsm = asi_valid && asi_uop == ASI_SAES_V3_DECSM;

wire   aes_dec    = insn_decs   || insn_decsm;
wire   aes_mix    = insn_encsm  || insn_decsm;

aes_v3_1 i_aes_v3_1 (
.valid  (insn_aes   ), // Are the inputs valid? Used for logic gating.
.dec    (aes_dec    ), // Encrypt (clear) or decrypt (set)
.mix    (aes_mix    ), // Perform MixColumn transformation (if set)
.rs1    (asi_rs1    ), // Source register 1
.rs2    (asi_rs2    ), // Source register 2
.bs     (asi_shamt  ), // Byte select immediate
.rd     (result_aes ), // output destination register value.
.ready  (aes_ready  )  // Compute finished?
);

end else if(XC_AES_VARIANT_TI) begin // Tiles

wire    insn_esrsub_lo = asi_valid && asi_uop == ASI_SAES_V5_ESRSUB_LO ;
wire    insn_esrsub_hi = asi_valid && asi_uop == ASI_SAES_V5_ESRSUB_HI ;
wire    insn_dsrsub_lo = asi_valid && asi_uop == ASI_SAES_V5_DSRSUB_LO ;
wire    insn_dsrsub_hi = asi_valid && asi_uop == ASI_SAES_V5_DSRSUB_HI ;
wire    insn_emix      = asi_valid && asi_uop == ASI_SAES_V5_EMIX      ;
wire    insn_dmix      = asi_valid && asi_uop == ASI_SAES_V5_DMIX      ;
wire    insn_sub       = asi_valid && asi_uop == ASI_SAES_V5_SUB       ;

wire    op_hi          = insn_esrsub_hi || insn_dsrsub_hi   ;
wire    op_sbsr        = insn_esrsub_hi || insn_dsrsub_hi  ||
                         insn_esrsub_lo || insn_dsrsub_lo   ;
wire    op_mix         = insn_emix      || insn_dmix        ;
wire    op_dec         = insn_dsrsub_lo || insn_dsrsub_hi  ||
                         insn_dmix                          ;

aes_tiled i_aes_tiled(
.g_clk      (g_clk      ),
.g_resetn   (g_resetn   ),
.valid      (insn_aes   ), // Input data valid
.dec        (op_dec     ), // Encrypt (0) or decrypt (1)
.op_sb      (insn_sub   ), // Sub-bytes only
.op_sbsr    (op_sbsr    ), // Subbytes and shift-rows
.op_mix     (op_mix     ), // Mix-Columns
.hi         (op_hi      ), // High or low shiftrows?
.rs1        (asi_rs1    ), // Input source register
.rs2        (asi_rs2    ), // Input source register
.ready      (aes_ready  ), // Finished computing?
.rd         (result_aes )  // Output destination register value.
);

end else begin

assign result_aes = 32'b0;
assign aes_ready  =  1'b1;

end endgenerate

endmodule
