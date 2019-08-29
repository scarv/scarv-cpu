
# Instruction Table

**Integer ALU Instructions:**

Instruction  | Action                   | uOP code    | Pack Widths 
-------------|--------------------------|-------------|-------------
`add        `| rd <= rs1 + rs2          | {00, 001}   | 32          
`xc.padd    `| rd <= rs1 p+ rs2         | {00, 001}   | 16/8/4/2    
`addi       `| rd <= rs1 + imm          | {00, 001}   | 32          
`c_add      `| rd <= rs1 + rs2          | {00, 001}   | 32          
`c_addi     `| rd <= rs1 + imm          | {00, 001}   | 32          
`c_addi16sp `| rd <= rs1 + imm          | {00, 001}   | 32          
`c_addi4spn `| rd <= rs1 + imm          | {00, 001}   | 32          
`c_mv       `| rd <= rs1                | {00, 001}   | 32          
`auipc      `| rd <= pc + imm20         | {00, 001}   | 32          
`c_sub      `| rd <= rs1 - rs2          | {00, 000}   | 32          
`sub        `| rd <= rs1 - rs2          | {00, 000}   | 32          
`xc.psub    `| rd <= rs1 p- rs2         | {00, 000}   | 16/8/4/2    
`and        `| rd <= rs1 & rs2          | {01, 001}   | 32          
`andi       `| rd <= rs1 & rs2          | {01, 001}   | 32          
`c_and      `| rd <= rs1 & rs2          | {01, 001}   | 32          
`c_andi     `| rd <= rs1 & imm          | {01, 001}   | 32          
`lui        `| rd <= {imm20, 12'b0}     | {01, 010}   | 32          
`c_li       `| rd <= imm                | {01, 010}   | 32          
`c_lui      `| rd <= imm                | {01, 010}   | 32          
`c_nop      `| nop                      | {01, 010}   | 32          
`or         `| rd <= rs1 or rs2         | {01, 010}   | 32          
`ori        `| rd <= rs1 or rs2         | {01, 010}   | 32          
`c_or       `| rd <= rs1 or rs2         | {01, 010}   | 32          
`c_xor      `| rd <= rs1 ^ rs2          | {01, 100}   | 32          
`xor        `| rd <= rs1 ^ rs2          | {01, 100}   | 32          
`xori       `| rd <= rs1 ^ imm          | {01, 100}   | 32          
`slt        `| rd <= rs1 < rs2          | {10, 001}   | 32          
`slti       `| rd <= rs1 < imm          | {10, 001}   | 32          
`sltu       `| rd <= rs1 < rs2          | {10, 010}   | 32          
`sltiu      `| rd <= rs1 < imm          | {10, 010}   | 32          
`sra        `| rd <= rs1 >>> rs2        | {11, 001}   | 32          
`srai       `| rd <= rs1 >>> rs2        | {11, 001}   | 32          
`c_srai     `| rd <= rs1 >>> imm        | {11, 001}   | 32          
`c_srli     `| rd <= rs1 >>  imm        | {11, 010}   | 32          
`srl        `| rd <= rs1 >> rs2         | {11, 010}   | 32          
`srli       `| rd <= rs1 >> rs2         | {11, 010}   | 32          
`xc.psrl    `| rd <= rs1 p>> rs2        | {11, 010}   | 16/8/4/2    
`xc.psrl.i  `| rd <= rs1 p>> imm        | {11, 010}   | 16/8/4/2    
`sll        `| rd <= rs1 << rs2         | {11, 100}   | 32          
`slli       `| rd <= rs1 << rs2         | {11, 100}   | 32          
`xc.psll    `| rd <= rs1 p>> rs2        | {11, 100}   | 16/8/4/2    
`xc.psll.i  `| rd <= rs1 p>> imm        | {11, 100}   | 16/8/4/2    
`c_slli     `| rd <= rs1 <<  imm        | {11, 100}   | 32          
`ror        `| rd <= rs1 >> rs2         | {11, 110}   | 32          
`rori       `| rd <= rs1 >> rs2         | {11, 110}   | 32          
`xc.pror    `| rd <= rs1 p>> rs2        | {11, 110}   | 16/8/4/2    
`xc.pror.i  `| rd <= rs1 p>> imm        | {11, 110}   | 16/8/4/2    


**Control Flow Instructions:**

Instruction  | Action                               | uOP code
-------------|--------------------------------------|-------------------------
`beq        `| pc <= pc + (rs1 == rs2 ? imm : 4)    | {00, 001}
`c_beqz     `| pc <= pc + (rs1==rs2 ? imm : 2)      | {00, 001}
`bge        `| pc <= pc + (rs1 >= rs2 ? imm : 4)    | {00, 010}
`bgeu       `| pc <= pc + (rs1 >= rs2 ? imm : 4)    | {00, 011}
`blt        `| pc <= pc + (rs1 <  rs2 ? imm : 4)    | {00, 100}
`bltu       `| pc <= pc + (rs1 <  rs2 ? imm : 4)    | {00, 101}
`bne        `| pc <= pc + (rs1 != rs2 ? imm : 4)    | {00, 110}
`c_bnez     `| pc <= pc + (rs1!=rs2 ? imm : 2)      | {00, 110}
`c_ebreak   `| pc <= mtvec                          | {01, 000}
`ebreak     `| pc <= mtvec                          | {01, 000}
`ecall      `| pc <= mtvec                          | {01, 000}
`c_j        `| pc <= pc + imm                       | {10, 000}
`c_jr       `| pc <= rs1                            | {10, 000}
`c_jal      `| pc <= pc + imm, rd <= pc + 2         | {10, 001}
`jal        `| pc <= pc + imm, rd <= pc + 4         | {10, 001}
`c_jalr     `| pc <= rs1, rd <= pc + 2              | {10, 001}
`jalr       `| pc <= pc + rs1, rd <= pc + 4         | {10, 001}
`mret       `| pc <= mepc                           | {11, 000}


**Memory Instructions:**

Instruction  | Action                   | uOP code
-------------|--------------------------|-------------------------------------
`lb         `| rd <= mem[rs1 + imm]     | {01, 011}
`xc.ldr.b   `| rd <= mem[rs1 + rs2]     | {01, 011}
`lbu        `| rd <= mem[rs1 + imm]     | {01, 010}
`xc.ldr.bu  `| rd <= mem[rs1 + rs2]     | {01, 010}
`lh         `| rd <= mem[rs1 + imm]     | {01, 101}
`xc.ldr.h   `| rd <= mem[rs1 + rs2]     | {01, 101}
`lhu        `| rd <= mem[rs1 + imm]     | {01, 100}
`xc.ldr.hu  `| rd <= mem[rs1 + rs2]     | {01, 100}
`lw         `| rd <= mem[rs1 + imm]     | {01, 110}
`xc.ldr.w   `| rd <= mem[rs1 + rs2]     | {01, 110}
`c_lw       `| rd <= mem[rs1 + imm]     | {01, 110}
`c_lwsp     `| rd <= mem[rs1 + imm]     | {01, 110}
`c_sw       `| mem[rs1+imm] <= rs2      | {10, 110}
`c_swsp     `| mem[rs1+imm] <= rs2      | {10, 110}
`sb         `| mem[rs2+imm] <= rs1      | {10, 010}
`xc.str.b   `| mem[rs2+rs1] <= rs3      | {10, 010}
`sh         `| mem[rs2+imm] <= rs1      | {10, 100}
`xc.str.h   `| mem[rs2+rs1] <= rs3      | {10, 100}
`sw         `| mem[rs2+imm] <= rs1      | {10, 110}
`xc.str.w   `| mem[rs2+rs1] <= rs3      | {10, 110}
`xc.scatter.h`|           .             | {00, 110}
`xc.scatter.b`|           .             | {00, 101}
`xc.gather.h `|           .             | {00, 010}
`xc.gather.b `|           .             | {00, 001}


**CSR Instructions:**

Instruction  | Action                   | uOP code
-------------|--------------------------|-------------------------------------
`csrrc      `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrci     `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrs      `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrsi     `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrw      `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrwi     `| rd <= csr, csr <= rs1    | {rw,scf}


**Mul/Div Instructions:**

Instruction  | Action                   | uOP code  | Pack Widths
-------------|--------------------------|-----------|-------------------------
`div        `| rd <= rs1 / rs2          | {11, 000} | 32
`divu       `| rd <= rs1 / rs2          | {11, 001} | 32
`rem        `| rd <= rs1 % rs2          | {11, 100} | 32
`remu       `| rd <= rs1 % rs2          | {11, 101} | 32
`mul        `| rd <= rs1 * rs2          | {01, 000} | 32
`xc.pmul.l  `| rd <= rs1 * rs2          | {01, 000} | 16/8/4/2
`mulh       `| rd <= rs1 * rs2          | {01, 100} | 32
`xc.pmul.h  `| rd <= rs1 * rs2          | {01, 001} | 16/8/4/2
`mulhsu     `| rd <= rs1 * rs2          | {01, 111} | 32
`mulhu      `| rd <= rs1 * rs2          | {01, 101} | 32
`xc.mmul.3  `|  .                       | {10, 000} | 32
`xc.madd.3  `|  .                       | {10, 001} | 32
`xc.msub.3  `|  .                       | {10, 010} | 32
`xc.macc.1  `|  .                       | {10, 100} | 32
`clmul      `| rd <= rs1 x rs2          | {00, 000} | 32
`clmulr     `| rd <= rs1 x rs2          | {00, 001} | 32
`clmulh     `| rd <= rs1 x rs2          | {00, 010} | 32
`xc.pclmul.l`| rd <= rs1 x rs2          | {00, 100} | 16/8/4/2
`xc.pclmul.h`| rd <= rs1 x rs2          | {00, 101} | 16/8/4/2


**Bit Manipulation Instructions:**

Instruction  | Action                   | uOP code  
-------------|--------------------------|------------------------
`bdep       `| rd <= f(rs1,rs2)         | {01, 000} 
`bext       `| rd <= f(rs1,rs2)         | {01, 001} 
`grev       `| rd <= f(rs1,rs2)         | {10, 000} 
`grevi      `| rd <= f(rs1,rs2)         | {10, 001} 
`xc.lut     `| rd <= f(rs1,rs2,rs3)     | {11, 000} 
`xc.bop     `| rd <= f(rs1,rs2,rs3)     | {11, 001} 
`cmov       `| rd <= rs3 ? rs1 : rs2    | {11, 100}
`fsl        `| rd <= rs1 || rs2 << rs3  | {00, 000}
`fsr        `| rd <= rs1 || rs2 << rs3  | {00, 001}
`fsri       `| rd <= rs1 || rs2 << imm  | {00, 001}
`xc.mror    `| rdm <= rs1||rs2 >> rs3   | {00, 011}


**Algorithm Specific Instructions:**

Instruction  | Action                   | uOP code  
-------------|--------------------------|------------------------
`xc.aessub.enc   ` | rd <= f(rs1,rs2)   | {01,000}
`xc.aessub.encrot` | rd <= f(rs1,rs2)   | {01,010}
`xc.aessub.dec   ` | rd <= f(rs1,rs2)   | {01,001}
`xc.aessub.decrot` | rd <= f(rs1,rs2)   | {01,011}
`xc.aesmix.enc   ` | rd <= f(rs1,rs2)   | {01,100}
`xc.aesmix.dec   ` | rd <= f(rs1,rs2)   | {01,101}
`xc.sha3.xy      ` | rd <= f(rs1,rs2)   | {10,000}
`xc.sha3.x1      ` | rd <= f(rs1,rs2)   | {10,001}
`xc.sha3.x2      ` | rd <= f(rs1,rs2)   | {10,010}
`xc.sha3.x4      ` | rd <= f(rs1,rs2)   | {10,011}
`xc.sha3.yx      ` | rd <= f(rs1,rs2)   | {10,100}
`xc.sha256.s0    ` | rd <= f(rs1,rs2)   | {11,000}
`xc.sha256.s1    ` | rd <= f(rs1,rs2)   | {11,001}
`xc.sha256.s2    ` | rd <= f(rs1,rs2)   | {11,010}
`xc.sha256.s3    ` | rd <= f(rs1,rs2)   | {11,011}


**RNG Instructions:**

Instruction  | Action                   | uOP code  
-------------|--------------------------|------------------------
`xc.rngtest` |  .                       | {00,001}
`xc.rngseed` |  .                       | {00,010}
`xc.rngsamp` |  .                       | {00,100}

---

# Dispatch Stage Operand Assignment.

**Integer ALU Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`add        `|  rs1         |  rs2          |  0
`xc.padd    `|  rs1         |  rs2          |  0
`addi       `|  rs1         |  imm          |  0
`c_add      `|  rs1         |  rs2          |  0
`c_addi     `|  rs1         |  imm          |  0
`c_addi16sp `|  rs1         |  rs2          |  0
`c_addi4spn `|  rs1         |  rs2          |  0
`c_mv       `|  rs1         |  0            |  0
`auipc      `|  PC+imm      |  0            |  0
`c_sub      `|  rs1         |  rs2          |  0
`sub        `|  rs1         |  rs2          |  0
`xc.psub    `|  rs1         |  rs2          |  0
`and        `|  rs1         |  rs2          |  0
`andi       `|  rs1         |  imm          |  0
`c_and      `|  rs1         |  rs2          |  0
`c_andi     `|  rs1         |  imm          |  0
`lui        `|  0           |  imm          |  0
`c_li       `|  0           |  imm          |  0
`c_lui      `|  0           |  imm          |  0
`c_nop      `|  0           |  0            |  0
`or         `|  rs1         |  rs2          |  0
`ori        `|  rs1         |  imm          |  0
`c_or       `|  rs1         |  rs2          |  0
`c_xor      `|  rs1         |  rs2          |  0
`xor        `|  rs1         |  rs2          |  0
`xori       `|  rs1         |  imm          |  0
`slt        `|  rs1         |  rs2          |  0
`slti       `|  rs1         |  imm          |  0
`sltu       `|  rs1         |  rs2          |  0
`sltiu      `|  rs1         |  imm          |  0
`sra        `|  rs1         |  rs2          |  0
`srai       `|  rs1         |  imm          |  0
`c_srai     `|  rs1         |  imm          |  0
`c_srli     `|  rs1         |  imm          |  0
`srl        `|  rs1         |  rs2          |  0
`xc.psrl    `|  rs1         |  rs2          |  0
`srli       `|  rs1         |  imm          |  0
`xc.psrl.i  `|  rs1         |  imm          |  0
`sll        `|  rs1         |  rs2          |  0
`xc.psll    `|  rs1         |  rs2          |  0
`slli       `|  rs1         |  imm          |  0
`xc.psll.i  `|  rs1         |  imm          |  0
`c_slli     `|  rs1         |  imm          |  0
`ror        `|  rs1         |  rs2          |  0
`rori       `|  rs1         |  imm          |  0
`xc.pror    `|  rs1         |  rs2          |  0
`xc.pror.i  `|  rs1         |  imm          |  0
`xc.mror    `| rs1          | rs2           | rs3


**Control Flow Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`beq        `|  rs1         |  rs2          | PC+imm
`c_beqz     `|  rs1         |  rs2          | PC+imm
`bge        `|  rs1         |  rs2          | PC+imm
`bgeu       `|  rs1         |  rs2          | PC+imm
`blt        `|  rs1         |  rs2          | PC+imm
`bltu       `|  rs1         |  rs2          | PC+imm
`bne        `|  rs1         |  rs2          | PC+imm
`c_bnez     `|  rs1         |  rs2          | PC+imm
`c_ebreak   `|  0           |  0            | 0
`ebreak     `|  0           |  0            | 0
`ecall      `|  0           |  0            | 0                  
`c_j        `|  0           |  0            | PC+imm
`c_jal      `|  0           |  0            | PC+imm
`jal        `|  0           |  0            | PC+imm
`c_jr       `|  rs1         |  0            | 0
`c_jalr     `|  rs1         |  0            | 0
`jalr       `|  rs1         |  imm          | 0
`mret       `|  0           |  0            | 0


**Memory Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`lb         `|  rs1         |  imm          | 0
`lbu        `|  rs1         |  imm          | 0
`lh         `|  rs1         |  imm          | 0
`lhu        `|  rs1         |  imm          | 0
`lw         `|  rs1         |  imm          | 0
`xc.ldr.b   `|  rs1         |  rs2          | 0
`xc.ldr.bu  `|  rs1         |  rs2          | 0
`xc.ldr.h   `|  rs1         |  rs2<<1       | 0
`xc.ldr.hu  `|  rs1         |  rs2<<1       | 0
`xc.ldr.w   `|  rs1         |  rs2<<2       | 0
`c_lw       `|  rs1         |  imm          | 0
`c_lwsp     `|  rs1         |  imm          | 0
`c_sw       `|  rs1         |  imm          | rs2
`c_swsp     `|  rs1         |  imm          | rs2
`sb         `|  rs1         |  imm          | rs2
`sh         `|  rs1         |  imm          | rs2
`sw         `|  rs1         |  imm          | rs2
`xc.str.b   `|  rs1         |  rs2          | rs3
`xc.str.h   `|  rs1         |  rs2<<1       | rs3
`xc.str.w   `|  rs1         |  rs2<<2       | rs3
`xc.scatter.h`| rs1         |  rs2          | rs3
`xc.scatter.b`| rs1         |  rs2          | rs3
`xc.gather.h `| rs1         |  rs2          | rs3
`xc.gather.b `| rs1         |  rs2          | rs3


**CSR Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`csrrc      `|  rs1         |  o            | csraddr
`csrrci     `|  imm         |  o            | csraddr
`csrrs      `|  rs1         |  o            | csraddr
`csrrsi     `|  imm         |  o            | csraddr
`csrrw      `|  rs1         |  o            | csraddr
`csrrwi     `|  imm         |  o            | csraddr


**Mul/Div Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`div        `|  rs1         |  rs2          | 0
`divu       `|  rs1         |  rs2          | 0
`mul        `|  rs1         |  rs2          | 0
`xc.pmul.l  `|  rs1         |  rs2          | 0
`mulh       `|  rs1         |  rs2          | 0
`xc.pmul.h  `|  rs1         |  rs2          | 0
`mulhsu     `|  rs1         |  rs2          | 0
`mulhu      `|  rs1         |  rs2          | 0
`rem        `|  rs1         |  rs2          | 0
`remu       `|  rs1         |  rs2          | 0
`xc.pclmul.l`|  rs1         |  rs2          | 0
`xc.pclmul.h`|  rs1         |  rs2          | 0
`xc.clmul   `|  rs1         |  rs2          | 0
`xc.clmulr  `|  rs1         |  rs2          | 0
`xc.clmulh  `|  rs1         |  rs2          | 0
`xc.mmul.3  `|  rs1         | rs2           | rs3
`xc.madd.3  `|  rs1         | rs2           | rs3
`xc.msub.3  `|  rs1         | rs2           | rs3
`xc.macc.1  `|  rs1         | rs2           | rs3


**Bit Manipulation Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`bdep       `|  rs1         | rs2           | 0
`bext       `|  rs1         | rs2           | 0
`grev       `|  rs1         | rs2           | 0
`grevi      `|  rs1         | rs2           | 0
`xc.lut     `|  rs1         | rs2           | rs3
`xc.bop     `|  rs1         | rs2           | rs3
`cmov       `|  rs1         | rs2           | rs3
`fsl        `|  rs1         | rs2           | rs3
`fsr        `|  rs1         | rs2           | rs3
`fsri       `|  rs1         | rs2           | rs3


**Algorithm Specific Instructions:**

Instruction        |`opr_a`      | `opr_b`       | `opr_c`    
-------------------|-------------|---------------|------------
`xc.aessub.enc   ` | rs1         | 0             | rs2
`xc.aessub.encrot` | rs1         | 0             | rs2
`xc.aessub.dec   ` | rs1         | 0             | rs2
`xc.aessub.decrot` | rs1         | 0             | rs2
`xc.aesmix.enc   ` | rs1         | 0             | rs2
`xc.aesmix.dec   ` | rs1         | 0             | rs2
`xc.sha3.xy      ` | rs1         | shamt         | rs2
`xc.sha3.x1      ` | rs1         | shamt         | rs2
`xc.sha3.x2      ` | rs1         | shamt         | rs2
`xc.sha3.x4      ` | rs1         | shamt         | rs2
`xc.sha3.yx      ` | rs1         | shamt         | rs2
`xc.sha256.s0    ` | rs1         | 0             | rs2
`xc.sha256.s1    ` | rs1         | 0             | rs2
`xc.sha256.s2    ` | rs1         | 0             | rs2
`xc.sha256.s3    ` | rs1         | 0             | rs2


**RNG Instructions:**

Instruction  |`opr_a`      | `opr_b`       | `opr_c`    
-------------|-------------|---------------|------------
`xc.rngtest` |             |               |
`xc.rngseed` | rs1         |               |
`xc.rngsamp` |             |               |

