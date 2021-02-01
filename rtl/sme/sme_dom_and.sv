
import sme_pkg::*;

module sme_dom_and #(
parameter D =  4, // Number of shares.
parameter N = 32  // Width of the operation.
)(
input             g_clk     , // Global clock
input             g_clk_req , // Global clock request
input             g_resetn  , // Sychronous active low reset.

input  [XLEN-1:0] rng [D-1:0],// Extra randomness.

input  [XLEN-1:0] rs1 [D-1:0], // RS1 as SMAX shares
input  [XLEN-1:0] rs2 [D-1:0], // RS2 as SMAX shares

output [XLEN-1:0] rd  [D-1:0]  // RD as SMAX shares
);

genvar n;
genvar d;
genvar i;
genvar j;
generate for (n = 0; n < N; n = n+1) begin: gen_bits

    // Shared representations of bit n of the inputs (x,y) and outputs (q).
    logic [D-1:0] x, y, q; 

    for (d = 0; d < D; d = d+1) begin : domain
        // Pull relevant single bits out of the inputs to the top level module.
        assign x[d] = rs1[d][n];
        assign y[d] = rs2[d][n];

        logic [D-1:0] ands;

        integer i,j;
        always_ff @(negedge g_clk) begin
            for (i = 0; i < D; i = i+1) begin
                for (j = 0; j < D; j = j+1) begin
                    if(i == j) begin
                        ands[d] <= (x[i] && y[j])                   ;
                    end else begin
                        ands[d] <= (x[i] && y[j]) ^ rng[d][i+j*(j-1)/2];
                    end
                end
            end
        end

        assign q[d] = ^ands;
        assign rd[d][n] = q[d];
    end

end endgenerate

endmodule
