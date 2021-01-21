
/* affine transformation in GF(2^8)
  i_a : 8-bit input
  i_b : 8 8-bit rows of 64-bit affine matrix. 
  o_r : 8-bit output
*/
module frv_gf256_aff(i_a,i_m,o_r);
input[ 7:0] i_a;
input[63:0] i_m;
output[7:0] o_r;
/*
wire [7:0] r7 = i_m[63:56];
wire [7:0] r6 = i_m[55:48];
wire [7:0] r5 = i_m[47:40];
wire [7:0] r4 = i_m[39:32];
wire [7:0] r3 = i_m[31:24];
wire [7:0] r2 = i_m[23:16];
wire [7:0] r1 = i_m[15: 8];
wire [7:0] r0 = i_m[ 7: 0];

wire [7:0] m7 = i_a & r7;
wire [7:0] m6 = i_a & r6;
wire [7:0] m5 = i_a & r5;
wire [7:0] m4 = i_a & r4;
wire [7:0] m3 = i_a & r3;
wire [7:0] m2 = i_a & r2;
wire [7:0] m1 = i_a & r1;
wire [7:0] m0 = i_a & r0;

assign o_r[0] = ^m0;
assign o_r[1] = ^m1;
assign o_r[2] = ^m2;
assign o_r[3] = ^m3;
assign o_r[4] = ^m4;
assign o_r[5] = ^m5;
assign o_r[6] = ^m6;
assign o_r[7] = ^m7;
*/

wire [7:0] c7 = i_m[63:56];
wire [7:0] c6 = i_m[55:48];
wire [7:0] c5 = i_m[47:40];
wire [7:0] c4 = i_m[39:32];
wire [7:0] c3 = i_m[31:24];
wire [7:0] c2 = i_m[23:16];
wire [7:0] c1 = i_m[15: 8];
wire [7:0] c0 = i_m[ 7: 0];

wire [7:0] m7 = {8{i_a[7]}} & c7;
wire [7:0] m6 = {8{i_a[6]}} & c6;
wire [7:0] m5 = {8{i_a[5]}} & c5;
wire [7:0] m4 = {8{i_a[4]}} & c4;
wire [7:0] m3 = {8{i_a[3]}} & c3;
wire [7:0] m2 = {8{i_a[2]}} & c2;
wire [7:0] m1 = {8{i_a[1]}} & c1;
wire [7:0] m0 = {8{i_a[0]}} & c0;

assign o_r = m0^m1^m2^m3^m4^m5^m6^m7;

endmodule

