
//
// module: frv_bitwise
//
//  This module is responsible for many of the bitwise operations the
//  core performs, both from XCrypto and Bitmanip
//
module frv_bitwise (

input  wire [31:0]  rs1             , //
input  wire [31:0]  rs2             , //
input  wire [31:0]  rs3             , //

input  wire [ 7:0]  bop_lut         , // LUT for xc.bop

input  wire         flush           , // Flush state / pipeline progress
input  wire         valid           , // Inputs valid.

input  wire         uop_fsl         , // Funnel shift Left
input  wire         uop_fsr         , // Funnel shift right
input  wire         uop_mror        , // Wide rotate right
input  wire         uop_cmov        , // Conditional move
input  wire         uop_lut         , // xc.lut
input  wire         uop_bop         , // xc.bop

output wire [63:0]  result          , // 64-bit result
output wire         ready             // Outputs ready.

);


//
// CMOV
// ------------------------------------------------------------

wire [31:0] result_cmov = |rs2 ? rs1 : rs3;

//
// Rotate/Funnel Shift
// ------------------------------------------------------------

wire [ 5:0] ramt    = uop_mror ? rs3[5:0] : rs2[5:0];

wire [63:0] rword_r = {rs1, uop_mror ? rs2 : rs3};
wire [63:0] rword_l;

wire [63:0] r_in    = uop_fsl ? rword_l : rword_r;

wire [63:0] rout_r  = r_in >> (   ramt) |
                      r_in << (64-ramt) ;

wire [63:0] rout_l  ;

wire [63:0] r_out   = uop_fsl ? rout_l  : rout_r ;

genvar i;

generate for(i = 0; i < 64; i = i +1) begin
    
    assign rword_l[i] = rword_r[63-i];
    
    assign rout_l[i]  = rout_r [63-i];

end endgenerate

//
// LUT
// ------------------------------------------------------------

wire [31:0] result_lut;

// Lut function instance from external/xcrypto-rtl
b_lut i_b_lut (
.crs1  (rs1         ), // Source register 1 (LUT input)
.crs2  (rs2         ), // Source register 2 (LUT bottom half)
.crs3  (rs3         ), // Source register 3 (LUT top half)
.result(result_lut  )  //
);

//
// BOP
// ------------------------------------------------------------

wire [31:0] result_bop  ;

b_bop i_b_bop(
.rd    (rs3         ),
.rs1   (rs1         ),
.rs2   (rs2         ),
.lut   (bop_lut     ),
.result(result_bop  ) 
);


//
// Result multiplexing
// ------------------------------------------------------------

wire result_fsl     = uop_fsl || uop_fsr;

assign result =
    {64{result_fsl}} & {32'b0, r_out[63:32]} |
    {64{uop_mror  }} & {       r_out       } |
    {64{uop_cmov  }} & {32'b0, result_cmov } |
    {64{uop_bop   }} & {32'b0, result_bop  } |
    {64{uop_lut   }} & {32'b0, result_lut  } ;

// Single cycle implementation.
assign ready = valid;

endmodule
