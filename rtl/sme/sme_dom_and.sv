
//`include "sme_common.svh"

module sme_dom_and #(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
parameter D      =3, // Number of shares.
parameter N      =32  // Width of the operation.
)(
input          g_clk    , // Global clock
input          g_resetn , // Sychronous active low reset.

input            en       , // Enable.
input  [RB   :0] rng ,// Extra randomness.

input  [N*D-1:0] rs1 , // RS1 as SMAX shares ={{N{share0}, {N{share1}}
input  [N*D-1:0] rs2 , // RS2 as SMAX shares ={{N{share0}, {N{share1}}

output [N*D-1:0] rd    // RD as SMAX shares
);

localparam RBITS_PER_SHARE  = D*(D-'d1)/2;
localparam RBITS_TOTAL      = N * RBITS_PER_SHARE;

localparam RB               = RBITS_TOTAL     - 1;
localparam RM               = RBITS_PER_SHARE - 1;

//wire [N-1:0] dbg_rs1 = rs1[31:0] ^ rs1[63:32];
//wire [N-1:0] dbg_rs2 = rs2[31:0] ^ rs2[63:32];
//wire [N-1:0] dbg_rd  = rd [31:0] ^ rd [63:32];

genvar B;
genvar s;
generate for(B=0; B < N; B=B+1) begin

    wire [RM :0] rng_slice = rng[B*RBITS_PER_SHARE+:RBITS_PER_SHARE];
    wire [D-1:0] rs1_slice ;
    wire [D-1:0] rs2_slice ;
    wire [D-1:0] rd_slice  ;

    for(s=0; s<D; s=s+1) begin
        assign rs1_slice[s] = rs1[s*N+B];
        assign rs2_slice[s] = rs2[s*N+B];
        assign rd[s*N+B]    = rd_slice[s];
    end
    
    //wire dbg_rs1_slice  = ^rs1_slice;
    //wire dbg_rs2_slice  = ^rs2_slice;
    //wire dbg_rd_slice   = ^rd_slice;

    sme_dom_and1 #(
        .POSEDGE(POSEDGE),
        .D      (D      )
    ) dom_and (
        .g_clk(g_clk),
        .g_resetn(g_resetn),
        .en (en         ),
        .rng(rng_slice  ),
        .rs1(rs1_slice  ),
        .rs2(rs2_slice  ),
        .rd (rd_slice   )
    );

end endgenerate

endmodule

// A version of sme_dom_and with non-array inputs.
module sme_dom_and1#(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
parameter D      =2  // Number of shares.
)(
input          g_clk     , // Global clock
input          g_resetn  , // Sychronous active low reset.

input          en        , // Enable.
input  [RM :0] rng,// Extra randomness.

input  [D-1:0] rs1, // RS1 as SMAX shares
input  [D-1:0] rs2, // RS2 as SMAX shares

output [D-1:0] rd   // RD as SMAX shares
);

localparam RMAX  = D*(D-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam SM    = D-1;

genvar i;
genvar j;
generate for(i = 0; i < D; i = i+1) begin : gen_i
    
    wire [SM:0] calculation;
    wire [SM:0] rng_i;
    reg  [SM:0] resharing;

    for(j = 0; j < D; j=j+1) begin : gen_j

        assign calculation[j] = rs1[i] && rs2[j];

        assign rng_i[j]       = i==j ? 1'b0                 :
                                j> i ? rng[i+(j*(j-1))/2]   :
                                       rng[j+(i*(i-1))/2]   ;

    end

    `ifdef SILVER
        always @(posedge g_clk) begin
            resharing <= calculation ^ rng_i;
        end
    `else
        if(POSEDGE) begin
            always @(posedge g_clk) begin
                resharing <= calculation ^ rng_i;
            end
        end else begin
            always @(negedge g_clk) begin
                resharing <= calculation ^ rng_i;
            end
        end
    `endif

    assign rd[i] = ^resharing;

end endgenerate

endmodule
