
`include "sme_common.svh"

module sme_dom_and #(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
parameter D      =3, // Number of shares.
parameter N      =32  // Width of the operation.
)(
input          g_clk    , // Global clock
input          g_resetn , // Sychronous active low reset.

input          en       , // Enable.
input  [N*RMAX-1:0] rng ,// Extra randomness.

input  [N*D-1:0] rs1 , // RS1 as SMAX shares
input  [N*D-1:0] rs2 , // RS2 as SMAX shares

output [N*D-1:0] rd    // RD as SMAX shares
);

localparam RMAX  = D+D*(D-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam SM    = D-1;

wire [N-1:0] a_rng [RM:0];
wire [N-1:0] a_rs1 [SM:0];
wire [N-1:0] a_rs2 [SM:0];
wire [N-1:0] a_rd  [SM:0];

genvar i;
`SME_UNPACK(a_rng, rng, N, RMAX, i)
`SME_UNPACK(a_rs1, rs1, N, D, i)
`SME_UNPACK(a_rs2, rs2, N, D, i)
`SME_PACK(rd, a_rd, N, D, i)

// For debugging
//(*keep*) reg [N-1:0] u_rs1, u_rs2, u_rd;
//
//always_comb begin
//    integer d;
//    u_rs1 = a_rs1[0];
//    u_rs2 = a_rs2[0];
//    u_rd  = a_rd [0];
//    for (d=1; d<D; d=d+1) begin
//        u_rs1 = u_rs1 ^ a_rs1[d];
//        u_rs2 = u_rs2 ^ a_rs2[d];
//        u_rd  = u_rd  ^ a_rd [d];
//    end
//end

genvar s;
genvar p; 
generate for (s = 0; s < D; s = s+1) begin: domand_gen_shares
  wire [N-1:0] x = a_rs1[s];

  reg  [N-1:0] ands [D-1:0];  
  reg  [N-1:0] rd_s;
  for (p = 0; p < D; p = p+1) begin: domand_gen_products
    wire [N-1:0] y = a_rs2[p];      

    wire [N-1:0] p_ands;    
    if(p == s) begin: p0
      assign p_ands = (x & y)                   ;
    end else if(p>s) begin : p1
      assign p_ands = (x & y) ^ a_rng[s+p*(p-1)/2];
    end else begin: p2
      assign p_ands = (x & y) ^ a_rng[p+s*(s-1)/2];
    end
        
    if(POSEDGE) begin
      always @(posedge g_clk) if(!g_resetn) ands[p] <= 'b0;
                              else if(en) ands[p] <= p_ands;
    end else begin
      always @(negedge g_clk) if(!g_resetn) ands[p] <= 'b0;
                              else if(en) ands[p] <= p_ands;
    end
  end

  integer i;
  always @(*) begin
    rd_s  = 0;
    for (i = 0; i < D; i = i+1) begin rd_s = rd_s ^ ands[i]; end
  end

  assign a_rd[s]=rd_s;

end endgenerate

endmodule

// A version of sme_dom_and with non-array inputs.
module sme_dom_and1#(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
parameter D      =3  // Number of shares.
)(
input          g_clk     , // Global clock
input          g_resetn  , // Sychronous active low reset.

input          en        , // Enable.
input  [RM :0] rng,// Extra randomness.
              
input  [D-1:0] rs1, // RS1 as SMAX shares
input  [D-1:0] rs2, // RS2 as SMAX shares
              
output [D-1:0] rd   // RD as SMAX shares
);

localparam RMAX  = D+D*(D-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam SM    = D-1;

//wire [0:0] i_rng [RM :0];
//wire [0:0] i_rs1 [D-1:0];
//wire [0:0] i_rs2 [D-1:0];
//wire [0:0] i_rd  [D-1:0];
//
//genvar i;
//generate for(i = 0; i < D; i=i+1) begin
//    assign i_rs1[i][0] = rs1[i];
//    assign i_rs2[i][0] = rs2[i];
//    assign rd   [i]    = i_rd[i][0];
//end endgenerate
//    
//generate for(i = 0; i < RMAX; i=i+1) begin
//    assign i_rng[i][0] = rng[i];
//end endgenerate

sme_dom_and #(
.POSEDGE(POSEDGE), .D(D), .N(1)
) i_and (
.g_clk     (g_clk     ), // Global clock
.g_resetn  (g_resetn  ), // Sychronous active low reset.
.en        (en        ), // Enable.
.rng       (  rng     ),// Extra randomness.
.rs1       (  rs1     ), // RS1 as SMAX shares
.rs2       (  rs2     ), // RS2 as SMAX shares
.rd        (  rd      )  // RD as SMAX shares
);

endmodule
