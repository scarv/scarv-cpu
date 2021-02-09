
import sme_pkg::*;

module sme_dom_and #(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
parameter D      =3, // Number of shares.
parameter N      =32  // Width of the operation.
)(
input          g_clk     , // Global clock
output         g_clk_req , // Global clock request
input          g_resetn  , // Sychronous active low reset.

input          en        , // Enable.
input  [N-1:0] rng [D-1:0],// Extra randomness.

input  [N-1:0] rs1 [D-1:0], // RS1 as SMAX shares
input  [N-1:0] rs2 [D-1:0], // RS2 as SMAX shares

output [N-1:0] rd  [D-1:0]  // RD as SMAX shares
);

// For debugging
(*keep*) reg [N-1:0] u_rs1, u_rs2, u_rd;

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
genvar i;
genvar j;
generate for (n = 0; n < N; n = n+1) begin: gen_bits

    // Shared representations of bit n of the inputs (x,y) and outputs (q).
    logic [D-1:0] x, y, q; 

    for (i = 0; i < D; i = i+1) begin : domain
        // Pull relevant single bits out of the inputs to the top level module.
        assign x[i] = rs1[i][n];
        assign y[i] = rs2[i][n];

        logic [D-1:0] n_ands;
        logic [D-1:0]   ands;

        always_comb begin
            integer j;
            for (j = 0; j < D; j = j+1) begin
                if(j == i) begin
                    n_ands[j] = (x[i] && y[j])                      ;
                end else if($signed(j)>$signed(i)) begin
                    n_ands[j] = (x[i] && y[j]) ^ rng[i+j*(j-1)/2][n];
                end else begin // j<i                               
                    n_ands[j] = (x[i] && y[j]) ^ rng[j+i*(i-1)/2][n];
                end
            end
        end
        
        if(POSEDGE) begin
            always_ff @(posedge g_clk) if(en) begin
                ands <= n_ands;
            end
        end else begin
            always_ff @(negedge g_clk) if(en) begin
                ands <= n_ands;
            end
        end

        assign q[i]     = ^ands;
        assign rd[i][n] =  q[i];
    end

end endgenerate

endmodule

// A version of sme_dom_and with non-array inputs.
module sme_dom_and1#(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
parameter D      =3  // Number of shares.
)(
input          g_clk     , // Global clock
output         g_clk_req , // Global clock request
input          g_resetn  , // Sychronous active low reset.

input          en        , // Enable.
input  [D-1:0] rng,// Extra randomness.
              
input  [D-1:0] rs1, // RS1 as SMAX shares
input  [D-1:0] rs2, // RS2 as SMAX shares
              
output [D-1:0] rd   // RD as SMAX shares
);

wire [0:0] i_rng [D-1:0];
wire [0:0] i_rs1 [D-1:0];
wire [0:0] i_rs2 [D-1:0];
wire [0:0] i_rd  [D-1:0];

genvar i;
generate for(i = 0; i < D; i=i+1) begin
    assign i_rng[i][0] = rng[i];
    assign i_rs1[i][0] = rs1[i];
    assign i_rs2[i][0] = rs2[i];
    assign rd   [i]    = i_rd[i][0];
end endgenerate

sme_dom_and #(
.POSEDGE(POSEDGE), .D(D), .N(1)
) i_and (
.g_clk     (g_clk     ), // Global clock
.g_clk_req (g_clk_req ), // Global clock request
.g_resetn  (g_resetn  ), // Sychronous active low reset.
.en        (en        ), // Enable.
.rng       (i_rng     ),// Extra randomness.
.rs1       (i_rs1     ), // RS1 as SMAX shares
.rs2       (i_rs2     ), // RS2 as SMAX shares
.rd        (i_rd      )  // RD as SMAX shares
);

endmodule
