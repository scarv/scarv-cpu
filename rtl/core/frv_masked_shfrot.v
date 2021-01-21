
// Shift/rotate module to operate on each sharing with random padding
module frv_masked_shfrot(
input  [31:0] s    , // input share
input  [ 4:0] shamt, // Shift amount 
input  [31:0] rp   , // random padding
input         srli , // Shift  right
input         slli , // Shift  left
input         rori , // Rotate right

output [31:0] r      // ouput share
);

wire left = slli;
wire right= srli | rori;

wire [31:0] l0 =  s;

wire [31:0]  l1;
wire [31:0]  l2;
wire [31:0]  l4;
wire [31:0]  l8;
wire [31:0] l16;

wire         l1_rpr = (rori)? l0[   0] : rp[    0];
wire [ 1:0]  l2_rpr = (rori)? l1[ 1:0] : rp[ 2: 1];
wire [ 3:0]  l4_rpr = (rori)? l2[ 3:0] : rp[ 6: 3];
wire [ 7:0]  l8_rpr = (rori)? l4[ 7:0] : rp[14: 7];
wire [15:0] l16_rpr = (rori)? l8[15:0] : rp[30:15];
//
// Level 1 code - shift/rotate by 1.
wire [31:0] l1_left  = {l0[30:0], rp[31]};
wire [31:0] l1_right = {l1_rpr  , l0[31:1]};
  
wire l1_l  = left  && shamt[0];
wire l1_r  = right && shamt[0];
wire l1_n  =         !shamt[0];

assign l1  = {32{l1_l}} & l1_left  |
             {32{l1_r}} & l1_right |
             {32{l1_n}} & l0       ;

// Level 2 code - shift/rotate by 2..
wire [31:0] l2_left  = {l1[29:0], rp[30:29]};
wire [31:0] l2_right = {l2_rpr  , l1[31: 2]};
  
wire l2_l  = left  && shamt[1];
wire l2_r  = right && shamt[1];
wire l2_n  =         !shamt[1];

assign l2  = {32{l2_l}} & l2_left  |
             {32{l2_r}} & l2_right |
             {32{l2_n}} & l1       ;

// Level 3 code - shift/rotate by 4.
wire [31:0] l4_left  = {l2[27:0], rp[28:25]};
wire [31:0] l4_right = {l4_rpr  , l2[31: 4]};
  
wire l4_l  = left  && shamt[2];
wire l4_r  = right && shamt[2];
wire l4_n  =         !shamt[2];
assign l4  = {32{l4_l}} & l4_left  |
             {32{l4_r}} & l4_right |
             {32{l4_n}} & l2       ;

// Level 4 code - shift/rotate by 8.
wire [31:0] l8_left  = {l4[23:0], rp[24:17]};
wire [31:0] l8_right = {l8_rpr  , l4[31: 8]};
  
wire l8_l  = left  && shamt[3];
wire l8_r  = right && shamt[3];
wire l8_n  =         !shamt[3];

assign l8  = {32{l8_l}} & l8_left  |
             {32{l8_r}} & l8_right |
             {32{l8_n}} & l4       ;

// Level 5 code - shift/rotate by 16.
wire [31:0] l16_left  = {l8[15:0], rp[16: 1]};
wire [31:0] l16_right = {l16_rpr , l8[31:16]};
  
wire l16_l  = left  && shamt[4];
wire l16_r  = right && shamt[4];
wire l16_n  =         !shamt[4];

assign l16  = {32{l16_l}} & l16_left  |
              {32{l16_r}} & l16_right |
              {32{l16_n}} & l8        ;

// output
assign r = l16;

endmodule
