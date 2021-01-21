
//
// module: frv_masked_and
//
//  Implements an N-bit masked AND operation using Domain oriented masking
//  See figure 2 of https://eprint.iacr.org/2016/486.pdf
//
// Note: Internal registers change on negative edge of g_clk when clk_en set.
//
//  Input variables are X and Y. Domains are A and B.
//
module frv_masked_and #(
parameter N=32
)(
input  wire          g_clk  ,
input  wire          clk_en ,   // Clock/register enble.
input  wire [N-1:0]  z0     ,   // Fresh randomness
input  wire [N-1:0]  z1     ,   // Fresh randomness
input  wire [N-1:0]  ax, ay ,   // Domain A Input shares: rs1 s0, rs2 s0
input  wire [N-1:0]  bx, by ,   // Domain B Input shares: rs1 s1, rs2 s1
output wire [N-1:0]  qx, qy     // Result shares
);

wire [N-1:0] t0 = ax & z0;
reg  [N-1:0] t1 ;

always @(negedge g_clk) if(clk_en) t1 <= by ^ z0;

assign qx = ((t1 ^ ay) & ax) ^ t0 ^ z1;


wire [N-1:0] t2 = bx & z0;
reg  [N-1:0] t3 ;

always @(negedge g_clk) if(clk_en) t3 <= ay ^ z0;

assign qy = ((t3 ^ by) & bx) ^ t2 ^ z1;

endmodule


//
// module: frv_masked_bitwise
//
//  Handles all bitwise operations inside the masked ALU. Individual results
//  are exposed so they can be re-used inside other functional units of the
//  masked ALU, namely the binary add/sub module.
//
module frv_masked_bitwise (
  input wire         g_resetn, g_clk, ena, 
  input wire  [31:0] i_remask0,
  input wire  [31:0] i_remask1,
  input wire  [31:0] i_a0  ,  i_a1 , 
  input wire  [31:0] i_b0  ,  i_b1 ,
  output wire [31:0] o_xor0, o_xor1,
  output wire [31:0] o_and0, o_and1,
  output wire [31:0] o_ior0, o_ior1,
  output wire [31:0] o_not0, o_not1,
  output wire        rdy
);

// Masking ISE - Use a DOM Implementation (1) or not (0)
parameter MASKING_ISE_DOM     = 1'b1;

//
// AND
// ------------------------------------------------------------

generate  if (MASKING_ISE_DOM == 1'b1) begin : masking_DOM
    
    //
    // DOM Masked AND
    frv_masked_and #(.N(32)) i_dom_and (
        .g_clk      (g_clk      ),
        .clk_en     (ena        ),
        .z0         (i_remask0  ),
        .z1         (i_remask1  ),
        .ax         (i_a0       ),
        .ay         (i_b0       ),
        .bx         (i_a1       ),
        .by         (i_b1       ),
        .qx         (o_and0     ),
        .qy         (o_and1     )
    );

end else begin : masking

    //
    // Naieve masked AND

    assign o_and0 = i_remask0 ^ (i_a0 & i_b1) ^ (i_a0 | ~i_b0);
    assign o_and1 = i_remask0 ^ (i_a1 & i_b1) ^ (i_a1 | ~i_b0);  

end endgenerate

//
// XOR / IOR / NOT
// ------------------------------------------------------------

assign o_xor0 = i_remask1 ^ i_a0 ^ i_b0;
assign o_xor1 = i_remask1 ^ i_a1 ^ i_b1;  

// IOR POST: reuse BOOL AND to execute BoolIor
assign o_ior0 =  o_and0;
assign o_ior1 = ~o_and1;

assign o_not0 =  i_a0  ;
assign o_not1 = ~i_a1  ;

assign rdy = ena;

endmodule
