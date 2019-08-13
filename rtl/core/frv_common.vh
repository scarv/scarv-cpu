
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

localparam P_FU_ALU     = 0;    // Integer alu
localparam P_FU_MUL     = 1;    // Multiply/divide
localparam P_FU_LSU     = 2;    // Load store unit
localparam P_FU_CFU     = 3;    // Control flow unit
localparam P_FU_CSR     = 4;    // CSR accesses
localparam P_FU_BIT     = 5;    // Bitwise
localparam P_FU_ASI     = 6;    // Algorithm specific (AES/SHA2/SHA3)
localparam P_FU_RNG     = 7;    // Algorithm specific (AES/SHA2/SHA3)
localparam P_FU_MPI     = 8;    // Multi-precision arithmetic

localparam FU           = 8;    // Width of functional unit specifier field
localparam OP           = 4;    // Width of micro-op specifier field.
localparam PW           = 2;    // Width of IALU pack width field.

localparam PW_32        = 3'b100;
localparam PW_16        = 3'b011;
localparam PW_8         = 3'b010;
localparam PW_4         = 3'b001;
localparam PW_2         = 3'b000;

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
localparam ALU_ROR      = {2'b11, 3'b110};

localparam CFU_BEQ      = {2'b00, 3'b001};
localparam CFU_BGE      = {2'b00, 3'b010};
localparam CFU_BGEU     = {2'b00, 3'b011};
localparam CFU_BLT      = {2'b00, 3'b100};
localparam CFU_BLTU     = {2'b00, 3'b101};
localparam CFU_BNE      = {2'b00, 3'b110};
localparam CFU_EBREAK   = {2'b01, 3'b001};
localparam CFU_ECALL    = {2'b01, 3'b010};
localparam CFU_MRET     = {2'b01, 3'b100};
localparam CFU_JMP      = {2'b10, 3'b001};
localparam CFU_JALI     = {2'b10, 3'b010};
localparam CFU_JALR     = {2'b10, 3'b100};
localparam CFU_TAKEN    = {2'b11, 3'b001};
localparam CFU_NOT_TAKEN= {2'b11, 3'b000};

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
localparam MUL_CLMUL_L  = {2'b00, 3'b001};
localparam MUL_CLMUL_H  = {2'b00, 3'b010};
localparam MUL_CLMUL_R  = {2'b00, 3'b100};

localparam CSR_READ     = 4;
localparam CSR_WRITE    = 3;
localparam CSR_SET      = 2;
localparam CSR_CLEAR    = 1;
localparam CSR_SWAP     = 0;

localparam BIT_BDEP          = {2'b01, 3'b000};
localparam BIT_BEXT          = {2'b01, 3'b001};
localparam BIT_GREV          = {2'b10, 3'b000};
localparam BIT_GREVI         = {2'b10, 3'b001};
localparam BIT_LUT           = {2'b11, 3'b000};
localparam BIT_BOP           = {2'b11, 3'b001};
localparam BIT_CMOV          = {2'b11, 3'b100};
localparam BIT_FSL           = {2'b00, 3'b000};
localparam BIT_FSR           = {2'b00, 3'b001};

localparam ASI_AES  = 2'b01;
localparam ASI_SHA2 = 2'b10;
localparam ASI_SHA3 = 2'b11;

localparam ASI_AESSUB_ENC    = {ASI_AES , 3'b000};
localparam ASI_AESSUB_ENCROT = {ASI_AES , 3'b010};
localparam ASI_AESSUB_DEC    = {ASI_AES , 3'b001};
localparam ASI_AESSUB_DECROT = {ASI_AES , 3'b011};
localparam ASI_AESMIX_ENC    = {ASI_AES , 3'b100};
localparam ASI_AESMIX_DEC    = {ASI_AES , 3'b101};
localparam ASI_SHA3_XY       = {ASI_SHA3, 3'b000};
localparam ASI_SHA3_X1       = {ASI_SHA3, 3'b001};
localparam ASI_SHA3_X2       = {ASI_SHA3, 3'b010};
localparam ASI_SHA3_X4       = {ASI_SHA3, 3'b011};
localparam ASI_SHA3_YX       = {ASI_SHA3, 3'b100};
localparam ASI_SHA256_S0     = {ASI_SHA2, 3'b000};
localparam ASI_SHA256_S1     = {ASI_SHA2, 3'b001};
localparam ASI_SHA256_S2     = {ASI_SHA2, 3'b010};
localparam ASI_SHA256_S3     = {ASI_SHA2, 3'b011};

localparam RNG_RNGTEST       = {2'b00, 3'b001};
localparam RNG_RNGSEED       = {2'b00, 3'b010};
localparam RNG_RNGSAMP       = {2'b00, 3'b100};

localparam MPI_MMUL_3        = {2'b00, 3'b000};
localparam MPI_MADD_3        = {2'b01, 3'b001};
localparam MPI_MSUB_3        = {2'b01, 3'b010};
localparam MPI_MACC_1        = {2'b01, 3'b100};
localparam MPI_MROR          = {2'b10, 3'b000};

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
localparam DIS_OPRC_RS3 = 8;  // Operand C sources RS3

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
`ifdef RVFI

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
