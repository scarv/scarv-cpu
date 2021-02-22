//import sme_pkg::*;
module sme_ks_adder #(
parameter D =  3, // Number of shares.
parameter G =  D+D*(D-1)/2, // Number of guard shares.
parameter N = 32  // Width of the operation.
)(
input            g_clk       , // Global clock
output           g_clk_req   , // Global clock request
input            g_resetn    , // Sychronous active low reset. 

input            en          , // Operation Enable.
input            sub         , // Subtract when =1, add when =0.
input  [N-1:0]   rng  [G-1:0],// Extra randomness.

input  [N-1:0]   mxor [D-1:0], // RS1 as SMAX shares
input  [N-1:0]   mand [D-1:0], // RS2 as SMAX shares

output reg [N-1:0]   rd   [D-1:0], // RD as SMAX shares
output wire          rdy
);

reg  [N-1:0] rng1     [G-1:0];     // reuse randomness.
integer r;
always @(*) begin
  rng1[0] = rng[G-1];
  for (r = 1; r < G; r = r+1)  rng1[r] = rng[r-1];
end

wire  [N-1:0] s_mand   [D-1:0];

wire  [N-1:0] pi       [D-1:0];
wire  [N-1:0] pj       [D-1:0];
wire  [N-1:0] gj       [D-1:0];
//p = (pi & pj);
//g = gi ^ (pi & gj);
wire  [N-1:0] p        [D-1:0];
wire  [N-1:0] g        [D-1:0];

wire  [N-1:0] pigj     [D-1:0];


reg  [ 5:0] seq_cnt;
always @(posedge g_clk)
  if (!g_resetn)    seq_cnt <=6'd1;
  else if (rdy)     seq_cnt <=6'd1;
  else if (en )     seq_cnt <=seq_cnt << 1;

wire   ini = en  && seq_cnt[0];
assign rdy =        seq_cnt[5];

genvar s;
generate for(s = 0; s < D; s = s+1) begin : gen_shares // BEGIN GENERATE

  // SUB OPT: execute the operations at line 5 & 6 in the BoolSub algorithm.
  wire           mand_lsb =  mand[s][0] ^ (mxor[s][0] && sub);
  wire   [N-1:0] sub_mand   = {mand[s][N-1:1], mand_lsb};
  wire   [N-1:0] sub_mxor   = mxor[s];

  wire   [N-1:0] p_s = p[s];
  wire   [N-1:0] g_s = g[s];

  wire   [N-1:0] pi_s = ({32{ini}} & sub_mxor) | ({32{!ini}} & p_s);
  wire   [N-1:0] gi_s = ({32{ini}} & sub_mand) | ({32{!ini}} & g_s);

  wire   [N-1:0] pj_s =  {32{ seq_cnt[0]}} & {pi_s[30:0], 1'd1} |
                         {32{ seq_cnt[1]}} & {pi_s[29:0], 2'd0} |
                         {32{ seq_cnt[2]}} & {pi_s[27:0], 4'd0} |
                         {32{|seq_cnt[3]}} & {pi_s[23:0], 8'd0} ;
  wire   [N-1:0] gj_s =  {32{ seq_cnt[0]}} & {gi_s[30:0], 1'd0} |
                         {32{ seq_cnt[1]}} & {gi_s[29:0], 2'd0} |
                         {32{ seq_cnt[2]}} & {gi_s[27:0], 4'd0} |
                         {32{ seq_cnt[3]}} & {gi_s[23:0], 8'd0} |
                         {32{|seq_cnt[4]}} & {gi_s[15:0],16'd0} ;
  assign pi[s] = pi_s;
  assign pj[s] = pj_s;
  assign gj[s] = gj_s;

  reg   [N-1:0] n_g;
  always @(posedge g_clk) begin
    if (en)        n_g <= gi_s;
  end

  assign g[s] = n_g ^ pigj[s];

end endgenerate

integer i;
always @(*) begin
  rd[0] = mxor[0] ^ {g[0][30:0],sub};
  for (i = 1; i < D; i = i+1)  rd[i] = mxor[i] ^ {g[i][30:0],1'b0};
end

dom_and #(
.POSEDGE(1),      // using posedge FFs
.D(D),            // Number of shares
.N(N)             // Bit-width of the operation.
) i_dom_and_pi_pj (
.g_clk      (g_clk    ), // Global clock
.g_clk_req  (         ), // Global clock request
.g_resetn   (g_resetn ), // Sychronous active low reset.
.en         (en       ), // Enable.
.rng        (rng      ), // Extra randomness.
.rs1        (pi      ), // RS1 as SMAX shares
.rs2        (pj       ), // RS2 as SMAX shares
.rd         (p        )  // RD as SMAX shares
);

dom_and #(
.POSEDGE(1),      // using posedge FFs
.D(D),            // Number of shares
.N(N)             // Bit-width of the operation.
) i_dom_and_pi_gj (
.g_clk      (g_clk    ), // Global clock
.g_clk_req  (         ), // Global clock request
.g_resetn   (g_resetn ), // Sychronous active low reset.
.en         (en       ), // Enable.
.rng        (rng1     ), // Extra randomness.
.rs1        (pi       ), // RS1 as SMAX shares
.rs2        (gj       ), // RS2 as SMAX shares
.rd         (pigj     )  // RD as SMAX shares
);

endmodule


module dom_and #(
parameter POSEDGE=0,  // If 0, trigger on negedge, else posedge.
parameter D      =2,  // Number of shares.
parameter G      =D+D*(D-1)/2, // Number of guard shares.
parameter N      =32  // Width of the operation.
)(
input          g_clk     ,     // Global clock
output         g_clk_req ,     // Global clock request
input          g_resetn  ,     // Sychronous active low reset.

input          en        ,     // Enable.
input  [N-1:0] rng [G-1:0],// Extra randomness.

input  [N-1:0] rs1 [D-1:0],    // RS1 as SMAX shares
input  [N-1:0] rs2 [D-1:0],    // RS2 as SMAX shares

output [N-1:0] rd  [D-1:0]     // RD as SMAX shares
);

genvar s;
genvar p; 
generate for (s = 0; s < D; s = s+1) begin: domand_gen_shares
  wire [N-1:0] x = rs1[s];

  reg  [N-1:0] ands [D-1:0];  
  reg  [N-1:0] rd_s;
  for (p = 0; p < D; p = p+1) begin: domand_gen_products
    wire [N-1:0] y = rs2[p];      

    wire [N-1:0] p_ands;    
    if(p == s) begin: p0
      assign p_ands = (x & y)                   ;
    end else if(p>s) begin : p1
      assign p_ands = (x & y) ^ rng[s+p*(p-1)/2];
    end else begin: p2
      assign p_ands = (x & y) ^ rng[p+s*(s-1)/2];
    end
        
    if(POSEDGE) begin
      always @(posedge g_clk) if(en) ands[p] <= p_ands;
    end else begin
      always @(negedge g_clk) if(en) ands[p] <= p_ands;
    end
  end

  integer i;
  always @(*) begin
    rd_s  = 0;
    for (i = 0; i < D; i = i+1) begin rd_s = rd_s ^ ands[i]; end
  end

  assign rd[s]=rd_s;

end endgenerate

endmodule

