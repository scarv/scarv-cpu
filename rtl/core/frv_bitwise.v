
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
// XCrypto feature class config bits.
parameter XC_CLASS_BIT        = 1'b1;

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

wire [63:0] rt_5    = ramt[5] ? {r_in[31:0], r_in[63:32]} : r_in;   // 32
wire [63:0] rt_4    = ramt[4] ? {rt_5[15:0], rt_5[63:16]} : rt_5;   // 16
wire [63:0] rt_3    = ramt[3] ? {rt_4[ 7:0], rt_4[63: 8]} : rt_4;   // 8 
wire [63:0] rt_2    = ramt[2] ? {rt_3[ 3:0], rt_3[63: 4]} : rt_3;   // 4 
wire [63:0] rt_1    = ramt[1] ? {rt_2[ 1:0], rt_2[63: 2]} : rt_2;   // 2 
wire [63:0] rt_0    = ramt[0] ? {rt_1[   0], rt_1[63: 1]} : rt_1;   // 1 

wire [63:0] rout_l  ;

wire [63:0] r_out   = uop_fsl ? rout_l  : rt_0   ;

genvar i;

generate for(i = 0; i < 64; i = i +1) begin
    
    assign rword_l[i] = rword_r[63-i];
    
    assign rout_l[i]  = rt_0   [63-i];

end endgenerate

//
// LUT
// ------------------------------------------------------------

wire [31:0] result_lut;

generate if(XC_CLASS_BIT) begin

// Lut function instance from external/xcrypto/rtl
b_lut i_b_lut (
.crs1  (rs1         ), // Source register 1 (LUT input)
.crs2  (rs2         ), // Source register 2 (LUT bottom half)
.crs3  (rs3         ), // Source register 3 (LUT top half)
.result(result_lut  )  //
);

end else begin

    assign result_lut = 0;

end endgenerate

//
// BOP
// ------------------------------------------------------------

wire [31:0] result_bop  ;

generate if(XC_CLASS_BIT) begin

b_bop i_b_bop(
.rs1   (rs1         ),
.rs2   (rs2         ),
.rd    (rs3         ),
.lut   (bop_lut     ),
.result(result_bop  ) 
);

end else begin

    assign result_bop = 0;

end endgenerate


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
