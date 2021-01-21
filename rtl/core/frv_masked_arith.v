
//Arithmetic masking operations
module frv_masked_arith (
input  [31:0] i_a0,
input  [31:0] i_a1,
input  [31:0] i_b0,
input  [31:0] i_b1,
input  [31:0] i_gs,
input         mask,
input         remask,
input         doadd,
input         dosub,
output [31:0] o_r0,
output [31:0] o_r1
);

wire [32:0]  amadd0, amadd1;
wire [31:0]  opr_lhs_0, opr_rhs_0;
wire [31:0]  opr_lhs_1, opr_rhs_1;
wire         ci;

assign opr_lhs_0 =             i_a0 ;
assign opr_rhs_0 =  ( doadd)?  i_b0 :
                    ( dosub)? ~i_b0 :
              /*mask|remask*/  i_gs ;
assign opr_lhs_1 =  ( ~mask)?  i_a1 :
                     /*mask*/  i_gs ;
assign opr_rhs_1 =  ( doadd)?  i_b1 :
                    ( dosub)? ~i_b1 :
                    (remask)?  i_gs :
                     /*mask*/ 32'd0 ;
assign ci = dosub;

assign amadd0 = {opr_lhs_0,1'b1} + {opr_rhs_0,ci};
assign amadd1 = {opr_lhs_1,1'b1} + {opr_rhs_1,ci};

assign o_r0 = amadd0[32:1];
assign o_r1 = amadd1[32:1];

endmodule

