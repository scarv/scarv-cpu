
//Boolean masked affine transformation in field gf(2^8) for AES
/* 
   i_a0, i_a1: 2 shares of 4-byte input
   i_mt      : 8 8-bit rows of 64-bit affine matrix. 
   i_gs      : guard share for refreshing
   o_r0, o_r1: 2 shares of 4-byte output
*/
module frv_masked_faff(	
input  [31:0] i_a0,
input  [31:0] i_a1,
input  [63:0] i_mt,
input  [31:0] i_gs,
output [31:0] o_r0,
output [31:0] o_r1
);

wire [31:0] r0, r1;
frv_gf256_aff atr0_b0 (.i_a(i_a0[ 7: 0]), .i_m(i_mt), .o_r(r0[ 7: 0]));
frv_gf256_aff atr1_b0 (.i_a(i_a1[ 7: 0]), .i_m(i_mt), .o_r(r1[ 7: 0]));

frv_gf256_aff atr0_b1 (.i_a(i_a0[15: 8]), .i_m(i_mt), .o_r(r0[15: 8]));
frv_gf256_aff atr1_b1 (.i_a(i_a1[15: 8]), .i_m(i_mt), .o_r(r1[15: 8]));

frv_gf256_aff atr0_b2 (.i_a(i_a0[23:16]), .i_m(i_mt), .o_r(r0[23:16]));
frv_gf256_aff atr1_b2 (.i_a(i_a1[23:16]), .i_m(i_mt), .o_r(r1[23:16]));

frv_gf256_aff atr0_b3 (.i_a(i_a0[31:24]), .i_m(i_mt), .o_r(r0[31:24]));
frv_gf256_aff atr1_b3 (.i_a(i_a1[31:24]), .i_m(i_mt), .o_r(r1[31:24]));
 
assign o_r0 = i_gs ^ r0;
assign o_r1 = i_gs ^ r1;

endmodule

