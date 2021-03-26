
`define SL(IDX) N*IDX+:N

`include "sme_common.svh"

module sme_ks_adder #(
parameter D =  3, // Number of shares.
parameter G =  D+D*(D-1)/2, // Number of guard shares.
parameter N = 32  // Width of the operation.
)(
input                g_clk      , // Global clock
input                g_resetn   , // Sychronous active low reset. 

input                en         , // Operation Enable.
input                sub        , // Subtract when =1, add when =0.
input      [N*G-1:0] s_rng      , // Extra randomness.

input      [N*D-1:0] s_mxor     , // RS1 as SMAX shares
input      [N*D-1:0] s_mand     , // RS2 as SMAX shares

output reg [N*D-1:0] s_rd       , // RD as SMAX shares
output wire          rdy
);

wire [N-1:0] mxor [D-1:0]; // RS1 as SMAX shares
wire [N-1:0] mand [D-1:0]; // RS2 as SMAX shares
reg  [N-1:0] rd   [D-1:0]; // RD as SMAX shares

genvar z;
generate for (s = 0; s<D; s=s+1) begin
    assign mxor[s     ]    = s_mxor[s*N+:N];
    assign mand[s     ]    = s_mand[s*N+:N];
    assign s_rd[s*N+:N]    = rd[s];
end endgenerate
//`SME_UNPACK(mxor, s_mxor, N, D, z)
//`SME_UNPACK(mand, s_mand, N, D, z)
//`SME_PACK(s_rd, rd, N, D, z)

/* verilator lint_off WIDTH */
localparam RNG_BITS = D*(D-'d1)/2;
localparam AND_BITS = N * RNG_BITS;
/* verilator lint_on WIDTH */
wire [AND_BITS-1:0] rng_0 = s_rng[0*AND_BITS+:AND_BITS];
wire [AND_BITS-1:0] rng_1 = s_rng[1*AND_BITS+:AND_BITS];

wire  [D*N-1:0] pi   ;
wire  [D*N-1:0] pj   ;
wire  [D*N-1:0] gj   ;
//p = (pi & pj);
//g = gi ^ (pi & gj);
wire  [D*N-1:0] p    ;
wire  [D*N-1:0] g    ;

wire  [D*N-1:0] pigj ;


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
  wire   [N-1:0] mand_s     = s_mand[`SL(s)];
  wire   [N-1:0] mxor_s     = s_mxor[`SL(s)];

  wire           mand_lsb =  mand_s[0] ^ (mxor_s[0] && sub);
  wire   [N-1:0] sub_mand   = {mand[s][N-1:1], mand_lsb};
  wire   [N-1:0] sub_mxor   = mxor_s;

  wire   [N-1:0] p_s = p[`SL(s)];
  wire   [N-1:0] g_s = g[`SL(s)];

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
  assign pi[`SL(s)] = pi_s;
  assign pj[`SL(s)] = pj_s;
  assign gj[`SL(s)] = gj_s;

  reg   [N-1:0] n_g;
  always @(posedge g_clk) begin
    if (en)        n_g <= gi_s;
  end

  assign g[`SL(s)] = n_g ^ pigj[`SL(s)];

end endgenerate

wire [N-1:0] g_0 = g[`SL(0)];
assign rd[0] = s_mxor[`SL(0)] ^ {g_0[30:0],sub};

genvar  i;
generate for(i=1; i <D; i=i+1) begin
  
  wire [N-1:0] g_i = g[`SL(i)];
  
  assign rd[i] = s_mxor[`SL(i)] ^ {g_i[30:0],1'b0};

end endgenerate

genvar a;
genvar n;
generate for(a = 0; a < N; a=a+1) begin

wire [RNG_BITS-1:0] rng_0_a = rng_0[a*RNG_BITS+:RNG_BITS];
wire [RNG_BITS-1:0] rng_1_a = rng_1[a*RNG_BITS+:RNG_BITS];

wire [D-1:0] pi_slice  ;
wire [D-1:0] pj_slice  ;
wire [D-1:0] gj_slice  ;
wire [D-1:0] p_slice   ;
wire [D-1:0] pigj_slice;

for(n=0; n<D; n=n+1) begin
    assign pi_slice[n] = pi[n*N+a];
    assign pj_slice[n] = pj[n*N+a];
    assign gj_slice[n] = gj[n*N+a];
    assign p[n*N+a] = p_slice[n];
    assign pigj[n*N+a] = pigj_slice[n];
end

sme_dom_and #(
.POSEDGE(1),      // using posedge FFs
.D(D),            // Number of shares
.N(1)             // Bit-width of the operation.
) i_dom_and_pi_pj (
.g_clk      (g_clk    ), // Global clock
.g_resetn   (g_resetn ), // Sychronous active low reset.
.en         (en       ), // Enable.
.rng        (rng_0_a  ), // Extra randomness.
.rs1        (pi_slice ), // RS1 as SMAX shares
.rs2        (pj_slice ), // RS2 as SMAX shares
.rd         (p_slice  )  // RD as SMAX shares
);

sme_dom_and #(
.POSEDGE(1),      // using posedge FFs
.D(D),            // Number of shares
.N(1)             // Bit-width of the operation.
) i_dom_and_pi_gj (
.g_clk      (g_clk     ), // Global clock
.g_resetn   (g_resetn  ), // Sychronous active low reset.
.en         (en        ), // Enable.
.rng        (rng_1_a   ), // Extra randomness.
.rs1        (pi_slice  ), // RS1 as SMAX shares
.rs2        (gj_slice  ), // RS2 as SMAX shares
.rd         (pigj_slice)  // RD as SMAX shares
);

end endgenerate

endmodule

`undef SL

