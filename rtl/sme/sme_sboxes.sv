//
//    sme_sboxes.sv
//    This is a very heavily modified version of "sboxes.v", sourced
//    from <https://github.com/mjosaarinen/lwaes_isa/>
//    Ben Marshall <ben.marshall@bristol.ac.uk>
//    Original copyright and notes preserved below.

//    sboxes.v
//    2020-01-29    Markku-Juhani O. Saarinen <mjos@pqshield.com>
//    Copyright (c) 2020, PQShield Ltd. All rights reserved.

/*

    Non-hardened combinatorial logic for AES, inverse AES, and SM4 S-Boxes.

    Each S-Box has a nonlinear middle layer sandwitched between linear
    top and bottom layers. In this version the top ("inner") layer expands
    8 bits to 21 bits while the bottom layer compresses 18 bits back to 8.

    Overall structure and AES and AES^-1 slightly modified from [BoPe12].
    SM4 top and bottom layers by Markku-Juhani O. Saarinen, January 2020.

    The middle layer is common between all; the beneficiality of muxing it
    depends on target. Currently we are not doing it.

    How? Because all of these are "Nyberg S-boxes" [Ny93]; built from a
    multiplicative inverse in GF(256) and are therefore affine isomorphic.

    [BoPe12] Boyar J., Peralta R. "A Small Depth-16 Circuit for the AES
    S-Box." Proc.SEC 2012. IFIP AICT 376. Springer, pp. 287-298 (2012)
    DOI: https://doi.org/10.1007/978-3-642-30436-1_24
    Preprint: https://eprint.iacr.org/2011/332.pdf

    [Ny93] Nyberg K., "Differentially Uniform Mappings for Cryptography",
    Proc. EUROCRYPT '93, LNCS 765, Springer, pp. 55-64 (1993)
    DOI: https://doi.org/10.1007/3-540-48285-7_6

*/

//
//    The shared non-linear middle part for AES, AES^-1, and SM4.
module sme_sbox_inv_mid#(
parameter SMAX=3
)(
input          g_clk        , // Global clock
input          g_resetn     , // Sychronous active low reset.
input          en           ,
input   [31:0] rng[RM    :0],
input   [20:0] x  [SMAX-1:0], // 21 bits x 3 shares
output  [17:0] y  [SMAX-1:0] 
);

    localparam RMAX  = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
    localparam RM    = RMAX-1;
    localparam SM = SMAX-1;
    
    // 3 shares / 21 bits.
    wire [SM:0] xs[20:0];
    wire [SM:0] ys[20:0];
    wire [RM:0] rs[33:0];

    genvar i, s;
    generate for(i = 0; i < 34; i = i+1) begin
        for(s = 0; s < SMAX; s = s+1) begin
            if(i<18) begin assign  y[s][i] = ys[i][s]; end
            if(i<21) begin assign xs[i][s] =  x[s][i]; end
        end 
    end endgenerate
    
    generate for(i = 0; i < 32; i = i+1) begin
        for(s = 0; s < RMAX; s = s+1) begin
            assign rs[i][s] = rng[s][i];
        end 
    end endgenerate

    `define AND(RD,X,Y,RI,PE) sme_dom_and1 #(       \
            .POSEDGE(PE), .D(SMAX)                  \
        ) i_and_``RI  (                             \
            .g_clk      (g_clk          ),          \
            .g_resetn   (g_resetn       ),          \
            .en         (en             ),          \
            .rng        (rs[RI]         ),          \
            .rs1        (X              ),          \
            .rs2        (Y              ),          \
            .rd         (RD             )           \
        );
    
    wire [SM:0] t1  ; `AND(t1 , xs[ 9], xs[ 5], 0, 0)
    wire [SM:0] t2  ; `AND(t2 , xs[17], xs[ 6], 1, 0)
    wire [SM:0] t4  ; `AND(t4 , xs[14], xs[ 0], 2, 0)
    wire [SM:0] t6  ; `AND(t6 , xs[ 3], xs[12], 3, 0)
    wire [SM:0] t7  ; `AND(t7 , xs[16], xs[ 7], 4, 0)
    wire [SM:0] t9  ; `AND(t9 , xs[15], xs[13], 5, 0)
    wire [SM:0] t11 ; `AND(t11, xs[ 1], xs[11], 6, 0)
    wire [SM:0] t12 ; `AND(t12, xs[ 4], xs[20], 7, 0)
    wire [SM:0] t14 ; `AND(t14, xs[ 2], xs[ 8], 8, 0)
    
    // stage
    wire [SM:0] t0  = xs[ 3] ^ xs[12];
    wire [SM:0] t3  = xs[10] ^ t1    ;
    wire [SM:0] t5  = t4     ^ t1    ;
    wire [SM:0] t8  = t0     ^ t6    ;
    wire [SM:0] t10 = t9     ^ t6    ;
    wire [SM:0] t13 = t12    ^ t11   ;
    wire [SM:0] t15 = t14    ^ t11   ;
    wire [SM:0] t16 = t3     ^ t2    ;
    wire [SM:0] t17 = t5     ^ xs[18];
    wire [SM:0] t18 = t8     ^ t7    ;
    wire [SM:0] t19 = t10    ^ t15   ;
    wire [SM:0] t20 = t16    ^ t13   ;
    wire [SM:0] t21 = t17    ^ t15   ;
    wire [SM:0] t22 = t18    ^ t13   ;
    wire [SM:0] t23 = t19    ^ xs[19];
    wire [SM:0] t24 = t22    ^ t23   ;
    wire [SM:0] t27 = t20    ^ t21   ;

    wire [SM:0] t25 ; `AND(t25, t22, t20, 10, 1)
    wire [SM:0] t31 ; `AND(t31, t20, t23, 11, 1)
    wire [SM:0] t34 ; `AND(t34, t21, t22, 12, 1)

    // stage
    wire [SM:0] t28 = t23 ^ t25;
    wire [SM:0] t26 = t21 ^ t25;
    wire [SM:0] t33 = t27 ^ t25;
    wire [SM:0] t36 = t24 ^ t25;
    wire [SM:0] t37 = t21 ^ t29;

    wire [SM:0] t29 ; `AND(t29, t28, t27,  9, 0)
    wire [SM:0] t30 ; `AND(t30, t26, t24, 13, 0)
    wire [SM:0] t32 ; `AND(t32, t27, t31, 14, 0)
    wire [SM:0] t35 ; `AND(t35, t24, t34, 15, 0)

    // stage
    wire [SM:0] t38 = t32 ^ t33;
    wire [SM:0] t39 = t23 ^ t30;
    wire [SM:0] t40 = t35 ^ t36;
    wire [SM:0] t41 = t38 ^ t40;
    wire [SM:0] t42 = t37 ^ t39;
    wire [SM:0] t43 = t37 ^ t38;
    wire [SM:0] t44 = t39 ^ t40;
    wire [SM:0] t45 = t42 ^ t41;

    `AND(ys[ 0], t38, xs[ 7], 16, 1)
    `AND(ys[ 1], t37, xs[13], 17, 1)
    `AND(ys[ 2], t42, xs[11], 18, 1)
    `AND(ys[ 3], t45, xs[20], 19, 1)
    `AND(ys[ 4], t41, xs[ 8], 20, 1)
    `AND(ys[ 5], t44, xs[ 9], 21, 1)
    `AND(ys[ 6], t40, xs[17], 22, 1)
    `AND(ys[ 7], t39, xs[14], 23, 1)
    `AND(ys[ 8], t43, xs[ 3], 24, 1)
    `AND(ys[ 9], t38, xs[16], 25, 1)
    `AND(ys[10], t37, xs[15], 26, 1)
    `AND(ys[11], t42, xs[ 1], 27, 1)
    `AND(ys[12], t45, xs[ 4], 28, 1)
    `AND(ys[13], t41, xs[ 2], 29, 1)
    `AND(ys[14], t44, xs[ 5], 30, 1)
    `AND(ys[15], t40, xs[ 6], 31, 1)
    `AND(ys[16], t39, xs[ 0], 32, 1)
    `AND(ys[17], t43, xs[12], 33, 1)

    `undef AND

endmodule

//
//    top (inner) linear layer for AES
module sme_sbox_aes_top #(
parameter SMAX = 3
)(
input   [ 7:0] x [SMAX-1:0] ,
output  [20:0] y [SMAX-1:0]
);
    
    localparam SM = SMAX-1;

    // 3 shares / 21 bits.
    wire [SM:0] xs[ 7:0];
    wire [SM:0] ys[20:0];

    genvar i, s;
    generate for(i = 0; i < 21; i = i+1) begin
        for(s = 0; s < SMAX; s = s+1) begin
            if(i< 8) begin assign xs[i][s] =  x[s][i]; end
            if(i<21) begin assign  y[s][i] = ys[i][s]; end
        end 
    end endgenerate

    wire [SM:0] y0  = xs[0] ;
    wire [SM:0] y1  = xs[7] ^     xs[4];
    wire [SM:0] y2  = xs[7] ^     xs[2];
    wire [SM:0] y3  = xs[7] ^     xs[1];
    wire [SM:0] y4  = xs[4] ^     xs[2];
    wire [SM:0] t0  = xs[3] ^     xs[1];
    wire [SM:0] y5  = y1    ^     t0   ;
    wire [SM:0] t1  = xs[6] ^     xs[5];
    wire [SM:0] y6  = xs[0] ^     y5   ;
    wire [SM:0] y7  = xs[0] ^     t1   ;
    wire [SM:0] y8  = y5    ^     t1   ;
    wire [SM:0] t2  = xs[6] ^     xs[2];
    wire [SM:0] t3  = xs[5] ^     xs[2];
    wire [SM:0] y9  = y3    ^     y4   ;
    wire [SM:0] y10 = y5    ^     t2   ;
    wire [SM:0] y11 = t0    ^     t2   ;
    wire [SM:0] y12 = t0    ^     t3   ;
    wire [SM:0] y13 = y7    ^     y12  ;
    wire [SM:0] t4  = xs[4] ^     xs[0];
    wire [SM:0] y14 = t1    ^     t4   ;
    wire [SM:0] y15 = y1    ^     y14  ;
    wire [SM:0] t5  = xs[1] ^     xs[0];
    wire [SM:0] y16 = t1    ^     t5   ;
    wire [SM:0] y17 = y2    ^     y16  ;
    wire [SM:0] y18 = y2    ^     y8   ;
    wire [SM:0] y19 = y15   ^     y13  ;
    wire [SM:0] y20 = y1    ^     t3   ;
    
    assign ys[0 ]  = y0 ;
    assign ys[1 ]  = y1 ;
    assign ys[10]  = y10;
    assign ys[11]  = y11;
    assign ys[12]  = y12;
    assign ys[13]  = y13;
    assign ys[14]  = y14;
    assign ys[15]  = y15;
    assign ys[16]  = y16;
    assign ys[17]  = y17;
    assign ys[18]  = y18;
    assign ys[19]  = y19;
    assign ys[2 ]  = y2 ;
    assign ys[20]  = y20;
    assign ys[3 ]  = y3 ;
    assign ys[4 ]  = y4 ;
    assign ys[5 ]  = y5 ;
    assign ys[6 ]  = y6 ;
    assign ys[7 ]  = y7 ;
    assign ys[8 ]  = y8 ;
    assign ys[9 ]  = y9 ;

endmodule

//
//    bottom (outer) linear layer for AES
module sme_sbox_aes_out #(
parameter SMAX = 3
)(
input   [17:0] x [SMAX-1:0],
output  [ 7:0] y [SMAX-1:0]
);
    localparam SM = SMAX-1;

//(*keep*) reg [ 17:0] u_x;
//(*keep*) reg [  7:0] u_y;

//always_comb begin
//    integer d;
//    u_x= x[0];
//    u_y= y[0];
//    for (d=1; d<SMAX; d=d+1) begin
//        u_x = u_x ^ x[d];
//        u_y = u_y ^ y[d];
//    end
//end
    
    // used to invert a variable by toglging the 0'th share bit
    wire [SM:0] inv = {{SM{1'b0}}, 1'b1};

    // 3 shares / 21 bits.
    wire [SM:0] xs[17:0];
    wire [SM:0] ys[ 7:0];

    genvar i, s;
    generate for(i = 0; i < 18; i = i+1) begin
        for(s = 0; s < SMAX; s = s+1) begin
            if(i<18) begin assign xs[i][s] =  x[s][i]; end
            if(i< 8) begin assign  y[s][i] = ys[i][s]; end
        end 
    end endgenerate

    wire [SM:0] t0   = xs[11] ^ xs[12];
    wire [SM:0] t1   = xs[ 0] ^ xs[ 6];
    wire [SM:0] t2   = xs[14] ^ xs[16];
    wire [SM:0] t3   = xs[15] ^ xs[ 5];
    wire [SM:0] t4   = xs[ 4] ^ xs[ 8];
    wire [SM:0] t5   = xs[17] ^ xs[11];
    wire [SM:0] t6   = xs[12] ^ t5;
    wire [SM:0] t7   = xs[14] ^ t3;
    wire [SM:0] t8   = xs[ 1] ^ xs[ 9];
    wire [SM:0] t9   = xs[ 2] ^ xs[ 3];
    wire [SM:0] t10  = xs[ 3] ^ t4;
    wire [SM:0] t11  = xs[10] ^ t2;
    wire [SM:0] t12  = xs[16] ^ xs[ 1];
    wire [SM:0] t13  = xs[ 0] ^ t0;
    wire [SM:0] t14  = xs[ 2] ^ xs[11];
    wire [SM:0] t15  = xs[ 5] ^ t1;
    wire [SM:0] t16  = xs[ 6] ^ t0;
    wire [SM:0] t17  = xs[ 7] ^ t1;
    wire [SM:0] t18  = xs[ 8] ^ t8;
    wire [SM:0] t19  = xs[13] ^ t4;
    wire [SM:0] t20  = t0     ^ t1;
    wire [SM:0] t21  = t1     ^ t7;
    wire [SM:0] t22  = t3     ^ t12;
    wire [SM:0] t23  = t18    ^ t2;
    wire [SM:0] t24  = t15    ^ t9;
    wire [SM:0] t25  = t6     ^ t10;
    wire [SM:0] t26  = t7     ^ t9;
    wire [SM:0] t27  = t8     ^ t10;
    wire [SM:0] t28  = t11    ^ t14;
    wire [SM:0] t29  = t11    ^ t17;

    assign ys[0] = y0; wire [SM:0] y0 = t6  ^ t23 ^ inv;
    assign ys[1] = y1; wire [SM:0] y1 = t13 ^ t27 ^ inv;
    assign ys[2] = y2; wire [SM:0] y2 = t25 ^ t29      ;
    assign ys[3] = y3; wire [SM:0] y3 = t20 ^ t22      ;
    assign ys[4] = y4; wire [SM:0] y4 = t6  ^ t21      ;
    assign ys[5] = y5; wire [SM:0] y5 = t19 ^ t28 ^ inv;
    assign ys[6] = y6; wire [SM:0] y6 = t16 ^ t26 ^ inv;
    assign ys[7] = y7; wire [SM:0] y7 = t6  ^ t24      ;

endmodule

//
//    top (inner) linear layer for AES^-1
module sme_sbox_aesi_top # (
parameter SMAX = 3
)(
output  [20:0] y [SMAX-1:0],
input   [ 7:0] x [SMAX-1:0]
);
    localparam SM = SMAX-1;

    wire [SM:0] xs[ 7:0];
    wire [SM:0] ys[20:0];

    genvar i, s;
    generate for(i = 0; i < 21; i = i+1) begin
        for(s = 0; s < SMAX; s = s+1) begin
            if(i< 8) begin assign xs[i][s] =  x[s][i]; end
            if(i<21) begin assign  y[s][i] = ys[i][s]; end
        end 
    end endgenerate

    wire [SM:0] y17 = xs[ 7] ^  xs[4];
    wire [SM:0] y16 = xs[ 6] ^~ xs[4];
    wire [SM:0] y2  = xs[ 7] ^~ xs[6];
    wire [SM:0] y1  = xs[ 4] ^  xs[3];
    wire [SM:0] y18 = xs[ 3] ^~ xs[0];
    wire [SM:0] t0  = xs[ 1] ^  xs[0];
    wire [SM:0] y6  = xs[ 6] ^~ y17 ;
    wire [SM:0] y14 = y16    ^  t0;
    wire [SM:0] y7  = xs[ 0] ^~ y1;
    wire [SM:0] y8  = y2     ^  y18;
    wire [SM:0] y9  = y2     ^  t0;
    wire [SM:0] y3  = y1     ^  t0;
    wire [SM:0] y19 = xs[ 5] ^~ y1;
    wire [SM:0] t1  = xs[ 6] ^  xs[1];
    wire [SM:0] y13 = xs[ 5] ^~ y14;
    wire [SM:0] y15 = y18    ^  t1;
    wire [SM:0] y4  = xs[ 3] ^  y6;
    wire [SM:0] t2  = xs[ 5] ^~ xs[2];
    wire [SM:0] t3  = xs[ 2] ^~ xs[1];
    wire [SM:0] t4  = xs[ 5] ^~ xs[3];
    wire [SM:0] y5  = y16    ^  t2 ;
    wire [SM:0] y12 = t1     ^  t4 ;
    wire [SM:0] y20 = y1     ^  t3 ;
    wire [SM:0] y11 = y8     ^  y20 ;
    wire [SM:0] y10 = y8     ^  t3 ;
    wire [SM:0] y0  = xs[ 7] ^  t2 ;
    
    assign ys[0 ] = y0 ;
    assign ys[1 ] = y1 ;
    assign ys[10] = y10;
    assign ys[11] = y11;
    assign ys[12] = y12;
    assign ys[13] = y13;
    assign ys[14] = y14;
    assign ys[15] = y15;
    assign ys[16] = y16;
    assign ys[17] = y17;
    assign ys[18] = y18;
    assign ys[19] = y19;
    assign ys[2 ] = y2 ;
    assign ys[20] = y20;
    assign ys[3 ] = y3 ;
    assign ys[4 ] = y4 ;
    assign ys[5 ] = y5 ;
    assign ys[6 ] = y6 ;
    assign ys[7 ] = y7 ;
    assign ys[8 ] = y8 ;
    assign ys[9 ] = y9 ;

endmodule

//
//    bottom (outer) linear layer for AES^-1
module sme_sbox_aesi_out #(
parameter SMAX=3
)(
output  [ 7:0] y [SMAX-1:0],
input   [17:0] x [SMAX-1:0]
);
    localparam SM = SMAX-1;

    wire [SM:0] xs[17:0];
    wire [SM:0] ys[ 7:0];

    genvar i, s;
    generate for(i = 0; i < 21; i = i+1) begin
        for(s = 0; s < SMAX; s = s+1) begin
            if(i<18) begin assign xs[i][s] =  x[s][i]; end
            if(i< 8) begin assign  y[s][i] = ys[i][s]; end
        end 
    end endgenerate

    wire [SM:0] t0  = xs[ 2] ^    xs[11];
    wire [SM:0] t1  = xs[ 8] ^    xs[ 9];
    wire [SM:0] t2  = xs[ 4] ^    xs[12];
    wire [SM:0] t3  = xs[15] ^    xs[ 0];
    wire [SM:0] t4  = xs[16] ^    xs[ 6];
    wire [SM:0] t5  = xs[14] ^    xs[ 1];
    wire [SM:0] t6  = xs[17] ^    xs[10];
    wire [SM:0] t7  = t0    ^     t1   ;
    wire [SM:0] t8  = xs[ 0] ^    xs[ 3];
    wire [SM:0] t9  = xs[ 5] ^    xs[13];
    wire [SM:0] t10 = xs[ 7] ^    t4   ;
    wire [SM:0] t11 = t0    ^     t3   ;
    wire [SM:0] t12 = xs[14] ^    xs[16];
    wire [SM:0] t13 = xs[17] ^    xs[ 1];
    wire [SM:0] t14 = xs[17] ^    xs[12];
    wire [SM:0] t15 = xs[ 4] ^    xs[ 9];
    wire [SM:0] t16 = xs[ 7] ^    xs[11];
    wire [SM:0] t17 = xs[ 8] ^    t2 ;
    wire [SM:0] t18 = xs[13] ^    t5 ;
    wire [SM:0] t19 = t2    ^     t3 ;
    wire [SM:0] t20 = t4    ^     t6 ;
    wire [SM:0] t22 = t2    ^     t7 ;
    wire [SM:0] t23 = t7    ^     t8 ;
    wire [SM:0] t24 = t5    ^     t7 ;
    wire [SM:0] t25 = t6    ^     t10;
    wire [SM:0] t26 = t9    ^     t11;
    wire [SM:0] t27 = t10   ^     t18;
    wire [SM:0] t28 = t11   ^     t25;
    wire [SM:0] t29 = t15   ^     t20;
    assign ys[0]    = t9    ^     t16;
    assign ys[1]    = t14   ^     t23;
    assign ys[2]    = t19   ^     t24;
    assign ys[3]    = t23   ^     t27;
    assign ys[4]    = t12   ^     t22;
    assign ys[5]    = t17   ^     t28;
    assign ys[6]    = t26   ^     t29;
    assign ys[7]    = t13   ^     t22;

endmodule


//
// Encrypt/Decrypt SBox for AES.
module sme_sbox_aes #(
parameter SMAX=3
)(
input  wire        g_clk              , // Global clock
input  wire        g_resetn           , // Sychronous active low reset.
input  wire        en                 , // Operation enable.
input  wire        dec                , // Decrypt
input  wire [31:0] rng      [RM    :0], // Random bits
input  wire [ 7:0] sbox_in  [SMAX-1:0], // SMAX share input
output wire [ 7:0] sbox_out [SMAX-1:0]  // SMAX share output
);

localparam RMAX  = SMAX+SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RM    = RMAX-1;
localparam  SM = SMAX-1;

wire [20:0] fwd_top [SM:0];
wire [20:0] inv_top [SM:0];

wire [20:0] mid_in  [SM:0];
wire [17:0] mid_out [SM:0];

wire [ 7:0] fwd_bot [SM:0];
wire [ 7:0] inv_bot [SM:0];

sme_sbox_aes_top  #(.SMAX(SMAX)) i_top_fwd (.x(sbox_in),.y(fwd_top));
sme_sbox_aesi_top #(.SMAX(SMAX)) i_top_inv (.x(sbox_in),.y(inv_top));

assign mid_in = dec ? inv_top : fwd_top;

sme_sbox_inv_mid  #(.SMAX(SMAX)) i_mid (
.g_clk      (g_clk      ),
.g_resetn   (g_resetn   ),
.en         (en         ),
.rng        (rng        ),
.x          (mid_in     ),
.y          (mid_out    )
);

sme_sbox_aes_out  #(.SMAX(SMAX)) i_bot_fwd (.x(mid_out),.y(fwd_bot));
sme_sbox_aesi_out #(.SMAX(SMAX)) i_bot_inv (.x(mid_out),.y(inv_bot));

assign sbox_out = dec ? inv_bot : fwd_bot;


// For debugging
//(*keep*) reg [ 20:0] u_fwd_top;
//(*keep*) reg [ 20:0] u_mid_in ;
//(*keep*) reg [ 17:0] u_mid_out;
//(*keep*) reg [  7:0] u_fwd_bot;
//
//always_comb begin
//    integer d;
//    u_fwd_top= fwd_top[0];
//    u_mid_in = mid_in [0];
//    u_mid_out= mid_out[0];
//    u_fwd_bot= fwd_bot[0];
//    for (d=1; d<SMAX; d=d+1) begin
//        u_fwd_top = u_fwd_top ^ fwd_top[d];
//        u_mid_in  = u_mid_in  ^ mid_in [d];
//        u_mid_out = u_mid_out ^ mid_out[d];
//        u_fwd_bot = u_fwd_bot ^ fwd_bot[d];
//    end
//end

endmodule

