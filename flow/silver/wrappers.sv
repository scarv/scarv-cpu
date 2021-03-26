
//
// This file contains wrappers for various SME modules, parameterised for
// different numbers of shares.
// 
// The SILVER tool is then applied to the wrapper module, thus verifying the
// parameterised sub-module it wraps.
//


//
// 2 share DOM AND
// ------------------------------------------------------------

module sme_dom_and1_2share #(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
)(
(* SILVER="clock"   *) input          g_clk     , // Global clock
(* SILVER="control" *) input          g_resetn  , // Sychronous active low reset.

(* SILVER="control" *) input          en        , // Enable.
(* SILVER="refresh" *) input  [RM :0] rng,// Extra randomness.
              
(* SILVER="0_1,0_0" *) input  [D-1:0] rs1, // RS1 as SMAX shares
(* SILVER="1_1,1_0" *) input  [D-1:0] rs2, // RS2 as SMAX shares

(* SILVER="2_1,2_0" *) output [D-1:0] rd   // RD as SMAX shares
);

localparam D     = 2;
localparam RMAX  = D*(D-1)/2;
localparam RM    = RMAX-1;
localparam SM    = D-1;

sme_dom_and1 #(
.D(D)
) i_duv (
.g_clk     (g_clk     ), // Global clock
.g_resetn  (g_resetn  ), // Sychronous active low reset.
.en        (en        ), // Enable.
.rng       (rng       ),// Extra randomness.
.rs1       (rs1       ), // RS1 as SMAX shares
.rs2       (rs2       ), // RS2 as SMAX shares
.rd        (rd        )  // RD as SMAX shares
);

endmodule

//
// 3 share DOM AND
// ------------------------------------------------------------

module sme_dom_and1_3share #(
parameter POSEDGE=0, // If 0, trigger on negedge, else posedge.
)(
(* SILVER="clock"   *) input          g_clk     , // Global clock
(* SILVER="control" *) input          g_resetn  , // Sychronous active low reset.

(* SILVER="control" *) input          en        , // Enable.
(* SILVER="refresh" *) input  [RM :0] rng,// Extra randomness.
              
(* SILVER="0_2,0_1,0_0" *) input  [D-1:0] rs1, // RS1 as SMAX shares
(* SILVER="1_2,1_1,1_0" *) input  [D-1:0] rs2, // RS2 as SMAX shares

(* SILVER="2_2,2_1,2_0" *) output [D-1:0] rd   // RD as SMAX shares
);

localparam D     = 3;
localparam RMAX  = D*(D-1)/2;
localparam RM    = RMAX-1;
localparam SM    = D-1;

sme_dom_and1 #(
.D(D)
) i_duv (
.g_clk     (g_clk     ), // Global clock
.g_resetn  (g_resetn  ), // Sychronous active low reset.
.en        (en        ), // Enable.
.rng       (rng       ),// Extra randomness.
.rs1       (rs1       ), // RS1 as SMAX shares
.rs2       (rs2       ), // RS2 as SMAX shares
.rd        (rd        )  // RD as SMAX shares
);

endmodule

//
// 2 share SBox Middle Layer
// ------------------------------------------------------------


module sme_sbox_inv_mid_2share (
(*SILVER="clock"*)input          g_clk    , // Global clock
(*SILVER="control"*)input          g_resetn , // Sychronous active low reset.
(*SILVER="control"*)input          en       ,
(*SILVER="control"*)input          flush    ,
(*SILVER="refresh"*)input   [RW:0] rng      ,
(*SILVER="[20:0]_0"*)input   [20:0] x_0      ,
(*SILVER="[20:0]_1"*)input   [20:0] x_1      ,
(*SILVER="[39:21]_0"*)output  [17:0] y_0      ,    
(*SILVER="[39:21]_1"*)output  [17:0] y_1      
);

localparam SMAX=2;
localparam AND_GATES = 34;
localparam RMAX  = SMAX*(SMAX-1)/2; // Number of guard shares.
localparam RW    = AND_GATES*RMAX-1;

sme_sbox_inv_mid #(
.SMAX(SMAX)
) i_duv (
.g_clk      (g_clk      ), // Global clock
.g_resetn   (g_resetn   ), // Sychronous active low reset.
.en         (en         ),
.flush      (flush      ),
.rng        (rng        ),
.x          ({x_1,x_0}  ), // 21 bits x 3 shares
.y          ({y_1,y_0}  )
);


endmodule

