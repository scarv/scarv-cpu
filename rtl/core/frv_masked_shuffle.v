
//
// module: frv_masked_shuffle
//
//  Performs a permutation of a 32-bit word. Used to shuffle one
//  share of each input/result of a masked operation.
//  This mitigates accidental un-masking through muxing.
//
module frv_masked_shuffle #(
parameter LEN   = 32,
parameter CONST = 32'h0
)(
input  wire [LEN-1:0] i  ,
input  wire           en ,
input  wire           fwd,
output wire [LEN-1:0] o
);

wire [LEN-1:0] rev_in   ;
wire [LEN-1:0] rev_out  ;

wire [LEN-1:0] const_in  =  fwd ? CONST: {LEN{1'b0}};
wire [LEN-1:0] const_out = !fwd ? CONST: {LEN{1'b0}};

assign rev_in   = i ^ const_in;

genvar J;
for (J = 0; J < LEN; J = J+1) begin
    assign rev_out[J] = rev_in[(LEN-1)-J];
end

assign o        = en ? rev_out ^ const_out: i;

endmodule

