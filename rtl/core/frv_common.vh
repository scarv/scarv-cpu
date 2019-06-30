
//
// Common core parameters, constants etc
// ------------------------------------------------------------------------
//

parameter  XLEN = 32        ; // Register word width (bits)
parameter  ILEN = 32        ; // Maximum instruction length (bits)

localparam XL   = XLEN-1    ; // Register signal high bit
localparam IL   = ILEN-1    ; // Instruction signal high bit

//
// Exception codes
// ------------------------------------------------------------------------
//

localparam TRAP_NONE    = 6'b111111;
localparam TRAP_IALIGN  = 6'b0 ;
localparam TRAP_IACCESS = 6'b1 ;
localparam TRAP_IOPCODE = 6'd2 ;
localparam TRAP_BREAKPT = 6'd3 ;
localparam TRAP_LDALIGN = 6'd4 ;
localparam TRAP_LDACCESS= 6'd5 ;
localparam TRAP_STALIGN = 6'd6 ;
localparam TRAP_STACCESS= 6'd7 ;
localparam TRAP_ECALLM  = 6'd11;

localparam TRAP_INT_MSI = 6'd3 ;
localparam TRAP_INT_MTI = 6'd7 ;
localparam TRAP_INT_MEI = 6'd11;

//
// Formal verification macros
// ------------------------------------------------------------------------
//


//
// RISC-V Formal flow macros and parameters.
`ifdef FORMAL

//
// Maximum number of instructions retired per cycle.
localparam NRET = 1;

`endif


//
// Custom formal flow macros.
`ifdef FRV_FORMAL

//
// Cover
`define FRV_COVER(X) if(g_resetn) begin cover(X); end

`endif
