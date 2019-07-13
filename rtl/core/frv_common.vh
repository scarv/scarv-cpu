
//
// Common core parameters, constants etc
// ------------------------------------------------------------------------
//

parameter  XLEN = 32        ; // Register word width (bits)
parameter  ILEN = 32        ; // Maximum instruction length (bits)

localparam XL   = XLEN-1    ; // Register signal high bit
localparam IL   = ILEN-1    ; // Instruction signal high bit

localparam REG_ZERO = 5'd0;
localparam REG_RA   = 5'd1;
localparam REG_SP   = 5'd2;

//
// Pipeline encoding fields
// ------------------------------------------------------------------------
//

localparam P_FU_ALU     = 0;
localparam P_FU_MUL     = 1;
localparam P_FU_LSU     = 2;
localparam P_FU_CFU     = 3;
localparam P_FU_CSR     = 4;

localparam ALU_ADD      = {2'b00, 3'b001};
localparam ALU_SUB      = {2'b00, 3'b000};
localparam ALU_AND      = {2'b01, 3'b001};
localparam ALU_OR       = {2'b01, 3'b010};
localparam ALU_XOR      = {2'b01, 3'b100};
localparam ALU_SLT      = {2'b10, 3'b001};
localparam ALU_SLTU     = {2'b10, 3'b010};
localparam ALU_SRA      = {2'b11, 3'b001};
localparam ALU_SRL      = {2'b11, 3'b010};
localparam ALU_SLL      = {2'b11, 3'b100};

localparam CFU_BEQ      = {2'b00, 3'b001};
localparam CFU_BGE      = {2'b00, 3'b010};
localparam CFU_BGEU     = {2'b00, 3'b011};
localparam CFU_BLT      = {2'b00, 3'b100};
localparam CFU_BLTU     = {2'b00, 3'b101};
localparam CFU_BNE      = {2'b00, 3'b110};
localparam CFU_EBREAK   = {2'b01, 3'b000};
localparam CFU_ECALL    = {2'b01, 3'b000};
localparam CFU_JMP      = {2'b10, 3'b001};
localparam CFU_JALI     = {2'b10, 3'b010};
localparam CFU_JALR     = {2'b10, 3'b100};
localparam CFU_MRET     = {2'b11, 3'b000};

localparam LSU_SIGNED   = 0;
localparam LSU_LOAD     = 3;
localparam LSU_STORE    = 4;
localparam LSU_BYTE     = 2'b01;
localparam LSU_HALF     = 2'b10;
localparam LSU_WORD     = 2'b11;

localparam MUL_DIV      = {2'b11, 3'b000};
localparam MUL_DIVU     = {2'b11, 3'b001};
localparam MUL_MUL      = {2'b01, 3'b000};
localparam MUL_MULH     = {2'b01, 3'b100};
localparam MUL_MULHSU   = {2'b01, 3'b111};
localparam MUL_MULHU    = {2'b01, 3'b101};
localparam MUL_REM      = {2'b10, 3'b000};
localparam MUL_REMU     = {2'b10, 3'b001};

localparam CSR_READ     = 4;
localparam CSR_WRITE    = 3;
localparam CSR_SET      = 2;
localparam CSR_CLEAR    = 1;
localparam CSR_SWAP     = 0;

//
// Dispatch stage operand register sources

localparam DIS_OPRA_RS1 = 0;  // Operand A sources RS1
localparam DIS_OPRA_PCIM= 1;  // Operand A sources PC+immediate
localparam DIS_OPRA_CSRI= 2;  // Operand A sources CSR mask immediate

localparam DIS_OPRB_RS2 = 3;  // Operand B sources RS2
localparam DIS_OPRB_IMM = 4;  // Operand B sources immediate

localparam DIS_OPRC_RS2 = 5;  // Operand C sources RS2
localparam DIS_OPRC_CSRA= 6;  // Operand C sources CSR address immediate
localparam DIS_OPRC_PCIM= 7;  // Operand C sources PC+immediate

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
