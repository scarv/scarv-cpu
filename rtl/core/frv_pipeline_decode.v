

//
// module: frv_pipeline_decode
//
//  Decode stage of the CPU, responsible for turning RISC-V encoded
//  instructions into wider pipeline encodings.
//
module frv_pipeline_decode(

input  wire        d_valid      , // Is the input data valid?
input  wire [31:0] d_data       , // Data word to decode.
input  wire        d_error      , // Is d_data associated with a fetch error?

output wire [ 4:0] p_rd         , // Destination register address
output wire [ 4:0] p_rs1        , // Source register address 1
output wire [ 4:0] p_rs2        , // Source register address 2
output wire [31:0] p_imm        , // Decoded immediate
output wire [ 4:0] p_uop        , // Micro-op code
output wire [ 4:0] p_fu         , // Functional Unit (alu/mem/jump/mul/csr)
output wire        p_trap       , // Raise a trap?
output wire [ 7:0] p_opr_src    , // Operand sources for dispatch stage.
output wire [ 1:0] p_size       , // Size of the instruction.
output wire [31:0] p_instr        // The instruction word

);

// Common core parameters and constants
`include "frv_common.vh"

//
// Instruction Decoding
// -------------------------------------------------------------------------

// Includes individual instruction decoding.
`include "frv_pipeline_decode.vh"

//
// Functional Unit Decoding / Selection
// -------------------------------------------------------------------------

assign p_fu[P_FU_ALU] = 
    dec_add        || dec_addi       || dec_c_add      || dec_c_addi     ||
    dec_c_addi16sp || dec_c_addi4spn || dec_c_mv       || dec_auipc      ||
    dec_c_sub      || dec_sub        || dec_and        || dec_andi       ||
    dec_c_and      || dec_c_andi     || dec_lui        || dec_c_li       ||
    dec_c_lui      || dec_c_nop      || dec_or         || dec_ori        ||
    dec_c_or       || dec_c_xor      || dec_xor        || dec_xori       ||
    dec_slt        || dec_slti       || dec_sltu       || dec_sltiu      ||
    dec_sra        || dec_srai       || dec_c_srai     || dec_c_srli     ||
    dec_srl        || dec_srli       || dec_sll        || dec_slli       ||
    dec_c_slli     ;

assign p_fu[P_FU_MUL] = 
    dec_div        || dec_divu       || dec_mul        || dec_mulh       ||
    dec_mulhsu     || dec_mulhu      || dec_rem        || dec_remu       ;

assign p_fu[P_FU_CFU] = 
    dec_beq        || dec_c_beqz     || dec_bge        || dec_bgeu       ||
    dec_blt        || dec_bltu       || dec_bne        || dec_c_bnez     ||
    dec_c_ebreak   || dec_ebreak     || dec_ecall      || dec_c_j        ||
    dec_c_jr       || dec_c_jal      || dec_jal        || dec_c_jalr     ||
    dec_jalr       || dec_mret       ;

assign p_fu[P_FU_LSU] = 
    dec_lb         || dec_lbu       || dec_lh          || dec_lhu        ||
    dec_lw         || dec_c_lw      || dec_c_lwsp      || dec_c_sw       ||
    dec_c_swsp     || dec_sb        || dec_sh          || dec_sw         ;

assign p_fu[P_FU_CSR] =
    dec_csrrc      || dec_csrrci     || dec_csrrs      || dec_csrrsi     ||
    dec_csrrw      || dec_csrrwi     ;

//
// Encoding field extraction
// -------------------------------------------------------------------------

wire [4:0] dec_rs1_32 = d_data[19:15];
wire [4:0] dec_rs2_32 = d_data[24:20];
wire [4:0] dec_rd_32  = d_data[11: 7];

wire       instr_16bit= d_data[1:0] != 2'b11;
wire       instr_32bit= d_data[1:0] == 2'b11;

assign     p_size[0]  = instr_16bit;
assign     p_size[1]  = instr_32bit;

// TODO: Switch to turn on/off.
assign     p_instr    = instr_16bit ? {16'b0, d_data[15:0]} : d_data ;

//
// Micro-OP Decoding / Selection
// -------------------------------------------------------------------------

wire [4:0] uop_alu = 
    {5{dec_add       }} & ALU_ADD   |
    {5{dec_addi      }} & ALU_ADD   |
    {5{dec_c_add     }} & ALU_ADD   |
    {5{dec_c_addi    }} & ALU_ADD   |
    {5{dec_c_addi16sp}} & ALU_ADD   |
    {5{dec_c_addi4spn}} & ALU_ADD   |
    {5{dec_c_mv      }} & ALU_ADD   |
    {5{dec_auipc     }} & ALU_ADD   |
    {5{dec_c_sub     }} & ALU_SUB   |
    {5{dec_sub       }} & ALU_SUB   |
    {5{dec_and       }} & ALU_AND   |
    {5{dec_andi      }} & ALU_AND   |
    {5{dec_c_and     }} & ALU_AND   |
    {5{dec_c_andi    }} & ALU_AND   |
    {5{dec_lui       }} & ALU_OR    |
    {5{dec_c_li      }} & ALU_OR    |
    {5{dec_c_lui     }} & ALU_OR    |
    {5{dec_c_nop     }} & ALU_OR    |
    {5{dec_or        }} & ALU_OR    |
    {5{dec_ori       }} & ALU_OR    |
    {5{dec_c_or      }} & ALU_OR    |
    {5{dec_c_xor     }} & ALU_XOR   |
    {5{dec_xor       }} & ALU_XOR   |
    {5{dec_xori      }} & ALU_XOR   |
    {5{dec_slt       }} & ALU_SLT   |
    {5{dec_slti      }} & ALU_SLT   |
    {5{dec_sltu      }} & ALU_SLTU  |
    {5{dec_sltiu     }} & ALU_SLTU  |
    {5{dec_sra       }} & ALU_SRA   |
    {5{dec_srai      }} & ALU_SRA   |
    {5{dec_c_srai    }} & ALU_SRA   |
    {5{dec_c_srli    }} & ALU_SRL   |
    {5{dec_srl       }} & ALU_SRL   |
    {5{dec_srli      }} & ALU_SRL   |
    {5{dec_sll       }} & ALU_SLL   |
    {5{dec_slli      }} & ALU_SLL   |
    {5{dec_c_slli    }} & ALU_SLL   ;

wire [4:0] uop_cfu =
    {5{dec_beq       }} & CFU_BEQ   |
    {5{dec_c_beqz    }} & CFU_BEQ   |
    {5{dec_bge       }} & CFU_BGE   |
    {5{dec_bgeu      }} & CFU_BGEU  |
    {5{dec_blt       }} & CFU_BLT   |
    {5{dec_bltu      }} & CFU_BLTU  |
    {5{dec_bne       }} & CFU_BNE   |
    {5{dec_c_bnez    }} & CFU_BNE   |
    {5{dec_c_ebreak  }} & CFU_EBREAK|
    {5{dec_ebreak    }} & CFU_EBREAK|
    {5{dec_ecall     }} & CFU_ECALL |
    {5{dec_c_j       }} & CFU_JALI  |
    {5{dec_c_jr      }} & CFU_JALR  |
    {5{dec_c_jal     }} & CFU_JALI  |
    {5{dec_jal       }} & CFU_JALI  |
    {5{dec_c_jalr    }} & CFU_JALR  |
    {5{dec_jalr      }} & CFU_JALR  |
    {5{dec_mret      }} & CFU_MRET  ;

wire [1:0] lsu_width = 
    {2{dec_lb        }} & LSU_BYTE |
    {2{dec_lbu       }} & LSU_BYTE |
    {2{dec_lh        }} & LSU_HALF |
    {2{dec_lhu       }} & LSU_HALF |
    {2{dec_lw        }} & LSU_WORD |
    {2{dec_c_lw      }} & LSU_WORD |
    {2{dec_c_lwsp    }} & LSU_WORD |
    {2{dec_c_sw      }} & LSU_WORD |
    {2{dec_c_swsp    }} & LSU_WORD |
    {2{dec_sb        }} & LSU_BYTE |
    {2{dec_sh        }} & LSU_HALF |
    {2{dec_sw        }} & LSU_WORD ;

wire [4:0] uop_lsu;

assign uop_lsu[2:1]      = lsu_width;

assign uop_lsu[LSU_LOAD] = 
    dec_lb     ||
    dec_lbu    ||
    dec_lh     ||
    dec_lhu    ||
    dec_lw     ||
    dec_c_lw   ||
    dec_c_lwsp ;

assign uop_lsu[LSU_STORE] = 
    dec_sb     ||
    dec_sh     ||
    dec_sw     ||
    dec_c_sw   ||
    dec_c_swsp ;

assign uop_lsu[LSU_SIGNED] = 
    dec_lb     ||
    dec_lh     ; 

wire [4:0] uop_mul = 
    {5{dec_div   }} & MUL_DIV    |
    {5{dec_divu  }} & MUL_DIVU   |
    {5{dec_mul   }} & MUL_MUL    |
    {5{dec_mulh  }} & MUL_MULH   |
    {5{dec_mulhsu}} & MUL_MULHSU |
    {5{dec_mulhu }} & MUL_MULHU  |
    {5{dec_rem   }} & MUL_REM    |
    {5{dec_remu  }} & MUL_REMU   ;

wire [4:0] uop_csr;

wire       csr_op = 
    dec_csrrc  || dec_csrrci || dec_csrrs  || dec_csrrsi || dec_csrrw  ||
    dec_csrrwi ;

assign uop_csr[CSR_READ ] = csr_op && dec_rd_32  != 0;
assign uop_csr[CSR_WRITE] = csr_op && dec_rs1_32 != 0;
assign uop_csr[CSR_SET  ] = dec_csrrs || dec_csrrsi ;
assign uop_csr[CSR_CLEAR] = dec_csrrc || dec_csrrci ;
assign uop_csr[CSR_SWAP ] = dec_csrrw || dec_csrrwi ;

assign p_uop =
    uop_alu |
    uop_cfu |
    uop_lsu |
    uop_mul |
    uop_csr ;

//
// Register Address Decoding
// -------------------------------------------------------------------------

// Source register 1, given a 16-bit instruction
wire [4:0] dec_rs1_16 = 
    {5{dec_c_add     }} & {d_data[11:7]      } |
    {5{dec_c_addi    }} & {d_data[11:7]      } |
    {5{dec_c_jalr    }} & {d_data[11:7]      } |
    {5{dec_c_jr      }} & {d_data[11:7]      } |
    {5{dec_c_slli    }} & {d_data[11:7]      } |
    {5{dec_c_swsp    }} & {REG_SP            } |
    {5{dec_c_addi16sp}} & {REG_SP            } |
    {5{dec_c_addi4spn}} & {REG_SP            } |
    {5{dec_c_lwsp    }} & {REG_SP            } |
    {5{dec_c_and     }} & {2'b01, d_data[9:7]} |
    {5{dec_c_andi    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_beqz    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_bnez    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_lw      }} & {2'b01, d_data[9:7]} |
    {5{dec_c_or      }} & {2'b01, d_data[9:7]} |
    {5{dec_c_srai    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_srli    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_sub     }} & {2'b01, d_data[9:7]} |
    {5{dec_c_sw      }} & {2'b01, d_data[9:7]} |
    {5{dec_c_xor     }} & {2'b01, d_data[9:7]} ;
    
// Source register 2, given a 16-bit instruction
wire [4:0] dec_rs2_16 = 
    {5{dec_c_beqz    }} & {       REG_ZERO   } |
    {5{dec_c_bnez    }} & {       REG_ZERO   } |
    {5{dec_c_add     }} & {       d_data[6:2]} |
    {5{dec_c_mv      }} & {       d_data[6:2]} |
    {5{dec_c_swsp    }} & {       d_data[6:2]} |
    {5{dec_c_and     }} & {2'b01, d_data[4:2]} |
    {5{dec_c_or      }} & {2'b01, d_data[4:2]} |
    {5{dec_c_sub     }} & {2'b01, d_data[4:2]} |
    {5{dec_c_sw      }} & {2'b01, d_data[4:2]} |
    {5{dec_c_xor     }} & {2'b01, d_data[4:2]} ;

// Destination register, given a 16-bit instruction
wire [4:0] dec_rd_16 = 
    {5{dec_c_addi16sp}} & {REG_SP} |
    {5{dec_c_addi4spn}} & {2'b01, d_data[4:2]} |
    {5{dec_c_and     }} & {2'b01, d_data[9:7]} |
    {5{dec_c_andi    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_jal     }} & {REG_RA} |
    {5{dec_c_jalr    }} & {REG_RA} |
    {5{dec_c_add     }} & {d_data[11:7]} |
    {5{dec_c_addi    }} & {d_data[11:7]} |
    {5{dec_c_li      }} & {d_data[11:7]} |
    {5{dec_c_lui     }} & {d_data[11:7]} |
    {5{dec_c_lwsp    }} & {d_data[11:7]} |
    {5{dec_c_mv      }} & {d_data[11:7]} |
    {5{dec_c_slli    }} & {d_data[11:7]} |
    {5{dec_c_lw      }} & {2'b01, d_data[4:2]} |
    {5{dec_c_or      }} & {2'b01, d_data[9:7]} |
    {5{dec_c_srai    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_srli    }} & {2'b01, d_data[9:7]} |
    {5{dec_c_sub     }} & {2'b01, d_data[9:7]} |
    {5{dec_c_xor     }} & {2'b01, d_data[9:7]} ;


assign p_rs1 = instr_16bit ? dec_rs1_16 : dec_rs1_32;
assign p_rs2 = instr_16bit ? dec_rs2_16 : dec_rs2_32;

// Destination register address carries trap cause if need be.
assign p_rd    = p_trap           ? trap_cause[4:0]   :
                 {5{instr_16bit}} & dec_rd_16 | 
                 {5{instr_32bit}} & dec_rd_32 ;

//
// Immediate Decoding
// -------------------------------------------------------------------------

wire [31:0] imm32_i = {{20{d_data[31]}}, d_data[31:20]};

wire [11:0] imm_csr_a = d_data[31:20];

wire [31:0] imm32_s = {{20{d_data[31]}}, d_data[31:25], d_data[11:7]};

wire [31:0] imm32_b = 
    {{19{d_data[31]}},d_data[31],d_data[7],d_data[30:25],d_data[11:8],1'b0};

wire [31:0] imm32_u = {d_data[31:12], 12'b0};

wire [31:0] imm32_j = 
    {{11{d_data[31]}},d_data[31],d_data[19:12],d_data[20],d_data[30:21],1'b0};

wire [31:0] imm_addi16sp = {
    {23{d_data[12]}},d_data[4:3],d_data[5],d_data[2],d_data[6],4'b0};

wire [31:0] imm_addi4spn = {
    22'b0, d_data[10:7],d_data[12:11],d_data[5],d_data[6],2'b00};

wire [31:0] imm_c_lsw = {
    25'b0,d_data[5],d_data[12:10], d_data[6], 2'b00};

wire [31:0] imm_c_addi = {
    {27{d_data[12]}}, d_data[6:2]};

wire [31:0] imm_c_lui  = {
    {15{d_data[12]}}, d_data[6:2],12'b0};

wire [31:0] imm_c_shamt = {
    27'b0,d_data[6:2]};

wire [31:0] imm_c_lwsp = {
    24'b0,d_data[3:2], d_data[12], d_data[6:4], 2'b00};

wire [31:0] imm_c_swsp = {
    24'b0,d_data[8:7], d_data[12:9], 2'b0};

wire [31:0] imm_c_j = {
    {21{d_data[12]}}, // 11 - sign extended
    d_data[8], // 10
    d_data[10:9], // 9:8
    d_data[6], // 7
    d_data[7], // 6
    d_data[2], // 5
    d_data[11], // 4
    d_data[5:3], // 3:1,
    1'b00
};

wire [31:0] imm_c_bz = {
    {24{d_data[12]}},d_data[6:5],d_data[2],d_data[11:10],d_data[4:3],1'b0
};

wire use_imm32_i = dec_andi || dec_slti   || dec_jalr   || dec_lb     ||
                   dec_lbu  || dec_lh     || dec_lhu    || dec_lw     ||
                   dec_ori  || dec_sltiu  || dec_xori   || dec_addi   ; 
wire use_imm32_j = dec_jal  ;
wire use_imm32_s = dec_sb   || dec_sh     || dec_sw     ;
wire use_imm32_u = dec_auipc|| dec_lui    ;
wire use_imm32_b = dec_beq  || dec_bge    || dec_bgeu   || dec_blt    ||
                   dec_bltu || dec_bne  ;
wire use_imm_csr = dec_csrrc || dec_csrrs || dec_csrrw;
wire use_imm_csri= dec_csrrci || dec_csrrsi || dec_csrrwi;
wire use_imm_shfi= dec_slli || dec_srli || dec_srai;

wire use_pc_imm  = use_imm32_b  || use_imm32_j  || dec_c_beqz   ||
                   dec_c_bnez   || dec_c_j      || dec_c_jal     ;

// Immediate which will be added to the program counter.
wire [31:0] p_imm_pc = 
    {32{use_imm32_b   }} & imm32_b      |
    {32{use_imm32_j   }} & imm32_j      |
    {32{dec_c_beqz    }} & imm_c_bz     |
    {32{dec_c_bnez    }} & imm_c_bz     |
    {32{dec_c_j       }} & imm_c_j      |
    {32{dec_c_jal     }} & imm_c_j      ;

assign p_imm = 
                           p_imm_pc     |
    {32{use_imm32_i   }} & imm32_i      |
    {32{use_imm32_u   }} & imm32_u      |
    {32{use_imm32_s   }} & imm32_s      |
    {32{dec_c_addi    }} & imm_c_addi   |
    {32{dec_c_addi16sp}} & imm_addi16sp |
    {32{dec_c_addi4spn}} & imm_addi4spn |
    {32{dec_c_andi    }} & imm_c_addi   |
    {32{dec_c_li      }} & imm_c_addi   |
    {32{dec_c_lui     }} & imm_c_lui    |
    {32{dec_c_lw      }} & imm_c_lsw    |
    {32{dec_c_lwsp    }} & imm_c_lwsp   |
    {32{dec_c_slli    }} & imm_c_shamt  |
    {32{dec_c_srli    }} & imm_c_shamt  |
    {32{dec_c_srai    }} & imm_c_shamt  |
    {32{dec_c_sw      }} & imm_c_lsw    |
    {32{dec_c_swsp    }} & imm_c_swsp   |
    {32{use_imm_csri  }} & {imm_csr_a, 15'b0, d_data[19:15]} |
    {32{use_imm_csr   }} & {imm_csr_a, 20'b0} |
    {32{dec_fence_i   }} & 32'd4        |
    {32{use_imm_shfi  }} & {27'b0, d_data[24:20]} ;

//
// Operand Sourcing.
// -------------------------------------------------------------------------

assign p_opr_src[DIS_OPRA_RS1 ] = // Operand A sources RS1
    dec_add        || dec_addi       || dec_c_add      || dec_c_addi     ||
    dec_c_addi16sp || dec_c_addi4spn || dec_c_mv       || dec_c_sub      ||
    dec_sub        || dec_and        || dec_andi       || dec_c_and      ||
    dec_c_andi     || dec_or         || dec_ori        || dec_c_or       ||
    dec_c_xor      || dec_xor        || dec_xori       || dec_slt        ||
    dec_slti       || dec_sltu       || dec_sltiu      || dec_sra        ||
    dec_srai       || dec_c_srai     || dec_c_srli     || dec_srl        ||
    dec_srli       || dec_sll        || dec_slli       || dec_c_slli     ||
    dec_beq        || dec_c_beqz     || dec_bge        || dec_bgeu       ||
    dec_blt        || dec_bltu       || dec_bne        || dec_c_bnez     ||
    dec_c_jr                         || dec_c_jalr     || dec_jalr       ||
    dec_lb         || dec_lbu        || dec_lh         || dec_lhu        ||
    dec_lw         || dec_c_lw       || dec_c_lwsp     || dec_c_sw       ||
    dec_c_swsp     || dec_sb         || dec_sh         || dec_sw         ||
    dec_csrrc      || dec_csrrs      || dec_csrrw      || dec_div        ||
    dec_divu       || dec_mul        || dec_mulh       || dec_mulhsu     ||
    dec_mulhu      || dec_rem        || dec_remu       ;

assign p_opr_src[DIS_OPRA_PCIM] = // Operand A sources PC+immediate
    dec_auipc       ;

assign p_opr_src[DIS_OPRA_CSRI] = // Operand A sources CSR mask immediate
    dec_csrrci     || dec_csrrsi     || dec_csrrwi     ;


assign p_opr_src[DIS_OPRB_RS2 ] = // Operand B sources RS2
    dec_add        || dec_c_add      || 
    dec_c_sub      || dec_sub        || dec_and        || dec_c_and      ||
    dec_or         || dec_c_or       || dec_c_xor      || dec_xor        ||
    dec_slt        || dec_sltu       || dec_sra        || dec_srl        ||
    dec_sll        || dec_beq        || dec_c_beqz     || dec_bge        ||
    dec_bgeu       || dec_blt        || dec_bltu       || dec_bne        ||
    dec_c_bnez     || dec_div        || dec_divu       || dec_mul        ||
    dec_mulh       || dec_mulhsu     || dec_mulhu      || dec_rem        ||
    dec_remu        ;

assign p_opr_src[DIS_OPRB_IMM ] = // Operand B sources immediate
    dec_addi       || dec_c_addi     || dec_andi       || dec_c_andi     ||
    dec_lui        || dec_c_li       || dec_c_lui      || dec_ori        ||
    dec_xori       || dec_slti       || dec_sltiu      || dec_srai       ||
    dec_c_srai     || dec_c_srli     || dec_srli       || dec_slli       ||
    dec_c_slli                       || dec_jalr       || dec_lb         ||
    dec_lbu        || dec_lh         || dec_lhu        || dec_lw         ||
    dec_c_lw       || dec_c_lwsp     || dec_c_sw       || dec_c_swsp     ||
    dec_sb         || dec_sh         || dec_sw         || dec_c_addi16sp ||
    dec_c_addi4spn  ;


assign p_opr_src[DIS_OPRC_RS2 ] = // Operand C sources RS2
    dec_c_sw       || dec_c_swsp     || dec_sb         || dec_sh         ||
    dec_sw          ;

assign p_opr_src[DIS_OPRC_CSRA] = // Operand C sources CSR address immediate
    dec_csrrc      || dec_csrrci     || dec_csrrs      || dec_csrrsi     ||
    dec_csrrw      || dec_csrrwi      ;

assign p_opr_src[DIS_OPRC_PCIM] = // Operand C sources PC+immediate
    dec_beq        || dec_c_beqz     || dec_bge        || dec_bgeu       ||
    dec_blt        || dec_bltu       || dec_bne        || dec_c_bnez     ||
    dec_c_j        || dec_c_jal      || dec_jal         ;

//
// Trap catching
// -------------------------------------------------------------------------

wire [5:0] trap_cause =
    invalid_instr   ? TRAP_IOPCODE  :
    d_error         ? TRAP_IACCESS  :
                      0             ;

assign p_trap         = d_valid && (d_error || invalid_instr);

endmodule

