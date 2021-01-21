
//Boolean masked multiplication in field gf(2^8) for AES
module frv_masked_fmul(	
input         g_resetn, 
input         g_clk, 
input         ena,
input  [31:0] i_a0,
input  [31:0] i_a1,
input  [31:0] i_b0,
input  [31:0] i_b1,
input         i_sqr,
input  [31:0] i_gs,
output [31:0] o_r0,
output [31:0] o_r1
);

parameter MASKING_ISE_DOM      = 1'b1;

wire [31:0] c_b0a0, c_b1a1, c_b100,c_b000; // controlled for selecting squaring or multiplying operation
assign c_b0a0 =   (i_sqr)?  i_a0:        //do square 
             /*multiply*/   i_b0;
assign c_b1a1 =   (i_sqr)?  i_a1:        //do square 
             /*multiply*/   i_b1;
assign c_b100 =   (i_sqr)? 32'd0:        //do square 
             /*multiply*/   i_b1;
assign c_b000 =   (i_sqr)? 32'd0:        //do square 
             /*multiply*/   i_b0;

wire [31:0] m00, m11, m01, m10;

frv_gf256_mul mult0_b0(.i_a(i_a0[ 7: 0]),.i_b(c_b0a0[ 7: 0]),.o_r(m00[ 7: 0]));
frv_gf256_mul mult1_b0(.i_a(i_a1[ 7: 0]),.i_b(c_b1a1[ 7: 0]),.o_r(m11[ 7: 0]));
frv_gf256_mul mult2_b0(.i_a(i_a0[ 7: 0]),.i_b(c_b100[ 7: 0]),.o_r(m01[ 7: 0]));
frv_gf256_mul mult3_b0(.i_a(i_a1[ 7: 0]),.i_b(c_b000[ 7: 0]),.o_r(m10[ 7: 0]));

frv_gf256_mul mult0_b1(.i_a(i_a0[15: 8]),.i_b(c_b0a0[15: 8]),.o_r(m00[15: 8]));
frv_gf256_mul mult1_b1(.i_a(i_a1[15: 8]),.i_b(c_b1a1[15: 8]),.o_r(m11[15: 8]));
frv_gf256_mul mult2_b1(.i_a(i_a0[15: 8]),.i_b(c_b100[15: 8]),.o_r(m01[15: 8]));
frv_gf256_mul mult3_b1(.i_a(i_a1[15: 8]),.i_b(c_b000[15: 8]),.o_r(m10[15: 8]));

frv_gf256_mul mult0_b2(.i_a(i_a0[23:16]),.i_b(c_b0a0[23:16]),.o_r(m00[23:16]));
frv_gf256_mul mult1_b2(.i_a(i_a1[23:16]),.i_b(c_b1a1[23:16]),.o_r(m11[23:16]));
frv_gf256_mul mult2_b2(.i_a(i_a0[23:16]),.i_b(c_b100[23:16]),.o_r(m01[23:16]));
frv_gf256_mul mult3_b2(.i_a(i_a1[23:16]),.i_b(c_b000[23:16]),.o_r(m10[23:16]));

frv_gf256_mul mult0_b3(.i_a(i_a0[31:24]),.i_b(c_b0a0[31:24]),.o_r(m00[31:24]));
frv_gf256_mul mult1_b3(.i_a(i_a1[31:24]),.i_b(c_b1a1[31:24]),.o_r(m11[31:24]));
frv_gf256_mul mult2_b3(.i_a(i_a0[31:24]),.i_b(c_b100[31:24]),.o_r(m01[31:24]));
frv_gf256_mul mult3_b3(.i_a(i_a1[31:24]),.i_b(c_b000[31:24]),.o_r(m10[31:24]));

generate 
  if (MASKING_ISE_DOM == 1'b1) begin : DOM_masking
    wire [31:0] reshare0 = m01^i_gs;
    wire [31:0] reshare1 = m10^i_gs;
    wire [31:0] integr0, integr1; 

    FF_Nb #(.Nb(32), .EDG(1'b0)) 
      ff_p0(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(reshare0), .dout(integr0));
    FF_Nb #(.Nb(32), .EDG(1'b0)) 
      ff_p1(.g_resetn(g_resetn), .g_clk(g_clk), .ena(ena), .din(reshare1), .dout(integr1));

    assign o_r0 = m00 ^ integr0;
    assign o_r1 = m11 ^ integr1;
  end else begin                    : masking
    (* keep="true" *)
    wire [31:0] refresh = i_gs ^ m01 ^ m10;
    assign o_r0 = m00 ^ i_gs;
    assign o_r1 = m11 ^ refresh;
  end
endgenerate
endmodule


