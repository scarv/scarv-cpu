
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
localparam P_FU_CRY     = 5;    // Crypto FU

localparam FU           = 5;    // Width-1 of functional unit specifier field
localparam OP           = 5;    // Width-1 of micro-op specifier field.

localparam ALU_ADD      = {2'b00, 4'b0000};
localparam ALU_SUB      = {2'b00, 4'b0001};
localparam ALU_SLT      = {2'b00, 4'b0101};
localparam ALU_SLTU     = {2'b00, 4'b0111};
localparam ALU_MIN      = {2'b00, 4'b1000};
localparam ALU_MINU     = {2'b00, 4'b1010};
localparam ALU_MAX      = {2'b00, 4'b1001};
localparam ALU_MAXU     = {2'b00, 4'b1011};

localparam ALU_AND      = {2'b01, 4'b0001};
localparam ALU_OR       = {2'b01, 4'b0010};
localparam ALU_XOR      = {2'b01, 4'b0011};
localparam ALU_ANDN     = {2'b01, 4'b0101};
localparam ALU_ORN      = {2'b01, 4'b0110};
localparam ALU_XNOR     = {2'b01, 4'b0111};
localparam ALU_CLZ      = {2'b01, 4'b1000};
localparam ALU_CTZ      = {2'b01, 4'b1001};
localparam ALU_PCNT     = {2'b01, 4'b1010};

localparam ALU_PACK     = {2'b10, 4'b0001};
localparam ALU_PACKU    = {2'b10, 4'b0010};
localparam ALU_PACKH    = {2'b10, 4'b0100};
localparam ALU_SEXTH    = {2'b10, 4'b0101};
localparam ALU_SEXTB    = {2'b10, 4'b0110};
localparam ALU_XPERMN   = {2'b10, 4'b0111};
localparam ALU_XPERMB   = {2'b10, 4'b1110};
localparam ALU_GREV     = {2'b10, 4'b1001};
localparam ALU_SHFL     = {2'b10, 4'b1010};
localparam ALU_UNSHFL   = {2'b10, 4'b1100};
localparam ALU_GORC     = {2'b10, 4'b1111};

localparam ALU_SRA      = {2'b11, 4'b0001};
localparam ALU_SRL      = {2'b11, 4'b0000};
localparam ALU_SRO      = {2'b11, 4'b0010};
localparam ALU_SLL      = {2'b11, 4'b0100};
localparam ALU_SLO      = {2'b11, 4'b0110};
localparam ALU_ROR      = {2'b11, 4'b1000};
localparam ALU_ROL      = {2'b11, 4'b1100};

localparam CFU_BEQ      = {2'b00, 4'b0001};
localparam CFU_BGE      = {2'b00, 4'b0010};
localparam CFU_BGEU     = {2'b00, 4'b0011};
localparam CFU_BLT      = {2'b00, 4'b0100};
localparam CFU_BLTU     = {2'b00, 4'b0101};
localparam CFU_BNE      = {2'b00, 4'b0110};
localparam CFU_EBREAK   = {2'b01, 4'b0001};
localparam CFU_ECALL    = {2'b01, 4'b0010};
localparam CFU_MRET     = {2'b01, 4'b0100};
localparam CFU_JMP      = {2'b10, 4'b0001};
localparam CFU_JALI     = {2'b10, 4'b0010};
localparam CFU_JALR     = {2'b10, 4'b0100};
localparam CFU_TAKEN    = {2'b11, 4'b0001};
localparam CFU_NOT_TAKEN= {2'b11, 4'b0000};

localparam LSU_SIGNED   = 0;
localparam LSU_LOAD     = 3;
localparam LSU_STORE    = 4;
localparam LSU_BYTE     = 2'b01;
localparam LSU_HALF     = 2'b10;
localparam LSU_WORD     = 2'b11;

localparam MUL_DIV      = {2'b11, 4'b000};
localparam MUL_DIVU     = {2'b11, 4'b001};
localparam MUL_REM      = {2'b11, 4'b100};
localparam MUL_REMU     = {2'b11, 4'b101};
localparam MUL_MUL      = {2'b01, 4'b100};
localparam MUL_MULH     = {2'b01, 4'b110};
localparam MUL_MULHSU   = {2'b01, 4'b111};
localparam MUL_MULHU    = {2'b01, 4'b101};
localparam MUL_CLMUL    = {2'b10, 4'b001};
localparam MUL_CLMULH   = {2'b10, 4'b010};
localparam MUL_CLMULR   = {2'b10, 4'b100};

localparam CRY_SAES32_ENCS   = 6'b00_0000; // AES Encrypt SBox
localparam CRY_SAES32_ENCSM  = 6'b00_0001; // AES Encrypt SBox + MixCols
localparam CRY_SAES32_DECS   = 6'b00_0010; // AES Decrypt SBox
localparam CRY_SAES32_DECSM  = 6'b00_0011; // AES Decrypt SBox + MixCols
localparam CRY_SSM4_KS       = 6'b00_0100; // SSM4 KeySchedule
localparam CRY_SSM4_ED       = 6'b00_0101; // SSM4 Encrypt/Decrypt
localparam CRY_SSM3_P0       = 6'b00_1000; // SSM3 P0
localparam CRY_SSM3_P1       = 6'b00_1001; // SSM3 P1
localparam CRY_SSHA256_SIG0  = 6'b10_1000; // SHA256 Sigma 0
localparam CRY_SSHA256_SIG1  = 6'b10_1001; // SHA256 Sigma 1
localparam CRY_SSHA256_SUM0  = 6'b10_1010; // SHA256 Sum 0
localparam CRY_SSHA256_SUM1  = 6'b10_1011; // SHA256 Sum 1
localparam CRY_SSHA512_SUM0R = 6'b01_1000; // SHA512 Sum 0
localparam CRY_SSHA512_SUM1R = 6'b01_1001; // SHA512 Sum 1
localparam CRY_SSHA512_SIG0L = 6'b01_1010; // SHA512 Sigma 0 low
localparam CRY_SSHA512_SIG0H = 6'b01_1011; // SHA512 Sigma 0 high
localparam CRY_SSHA512_SIG1L = 6'b01_1100; // SHA512 Sigma 1 low
localparam CRY_SSHA512_SIG1H = 6'b01_1101; // SHA512 Sigma 1 high

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
localparam TRAP_INT_NMI = 6'd16;

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
