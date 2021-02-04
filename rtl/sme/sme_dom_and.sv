
import sme_pkg::*;

module sme_dom_and #(
parameter D =  3, // Number of shares.
parameter N = 32  // Width of the operation.
)(
input             g_clk     , // Global clock
input             g_clk_req , // Global clock request
input             g_resetn  , // Sychronous active low reset.

input             en        , // Enable.
input  [XLEN-1:0] rng [D-1:0],// Extra randomness.

input  [XLEN-1:0] rs1 [D-1:0], // RS1 as SMAX shares
input  [XLEN-1:0] rs2 [D-1:0], // RS2 as SMAX shares

output [XLEN-1:0] rd  [D-1:0]  // RD as SMAX shares
);

// For debugging
(*keep*) reg [XLEN-1:0] u_rs1, u_rs2, u_rd;

always_comb begin
    integer d;
    u_rs1 = rs1[0];
    u_rs2 = rs2[0];
    u_rd  = rd [0];
    for (d=1; d<D; d=d+1) begin
        u_rs1 = u_rs1 ^ rs1[d];
        u_rs2 = u_rs2 ^ rs2[d];
        u_rd  = u_rd  ^ rd [d];
    end
end

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

        logic [D-1:0] n_ands;
        logic [D-1:0]   ands;

        always_comb begin
            integer i;
            for (i = 0; i < D; i = i+1) begin
                if(i == d) begin
                    n_ands[i] = (x[d] && y[i])                      ;
                end else begin
                    n_ands[i] = (x[d] && y[i]) ^ rng[d][d+i*(i-1)/2];
                end
            end
        end
        
        always_ff @(negedge g_clk) if(en) begin
            ands <= n_ands;
        end

        assign q[d] = ^ands;
        assign rd[d][n] = q[d];
    end

end endgenerate

endmodule
