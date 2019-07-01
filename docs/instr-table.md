
# Instruction Table

---

**Integer ALU Instructions:**

Instruction  | Action                   | uOP code
-------------|--------------------------|--------------------------------------
`add        `| rd <= rs1 + rs2          | {00, 001}
`addi       `| rd <= rs1 + imm          | {00, 001}
`c_add      `| rd <= rs1 + rs2          | {00, 001}
`c_addi     `| rd <= rs1 + imm          | {00, 001}
`c_addi16sp `| rd <= rs1 + imm          | {00, 001}
`c_addi4spn `| rd <= rs1 + imm          | {00, 001}
`c_mv       `| rd <= rs1                | {00, 001}
`auipc      `| rd <= pc + imm20         | {00, 001}
`c_sub      `| rd <= rs1 - rs2          | {00, 000}
`sub        `| rd <= rs1 - rs2          | {00, 000}
`and        `| rd <= rs1 & rs2          | {01, 001}
`andi       `| rd <= rs1 & rs2          | {01, 001}
`c_and      `| rd <= rs1 & rs2          | {01, 001}
`c_andi     `| rd <= rs1 & imm          | {01, 001}
`lui        `| rd <= {imm20, 12'b0}     | {01, 010}
`c_li       `| rd <= imm                | {01, 010}
`c_lui      `| rd <= imm                | {01, 010}
`c_nop      `| nop                      | {01, 010}
`or         `| rd <= rs1 or rs2         | {01, 010}
`ori        `| rd <= rs1 or rs2         | {01, 010}
`c_or       `| rd <= rs1 or rs2         | {01, 010}
`c_xor      `| rd <= rs1 ^ rs2          | {01, 100}
`xor        `| rd <= rs1 ^ rs2          | {01, 100}
`xori       `| rd <= rs1 ^ imm          | {01, 100}
`slt        `| rd <= rs1 < rs2          | {10, 001}
`slti       `| rd <= rs1 < imm          | {10, 001}
`sltu       `| rd <= rs1 < rs2          | {10, 010}
`sltiu      `| rd <= rs1 < imm          | {10, 010}
`sra        `| rd <= rs1 >>> rs2        | {11, 001}
`srai       `| rd <= rs1 >>> rs2        | {11, 001}
`c_srai     `| rd <= rs1 >>> imm        | {11, 001}
`c_srli     `| rd <= rs1 >>  imm        | {11, 010}
`srl        `| rd <= rs1 >> rs2         | {11, 010}
`srli       `| rd <= rs1 >> rs2         | {11, 010}
`sll        `| rd <= rs1 << rs2         | {11, 100}
`slli       `| rd <= rs1 << rs2         | {11, 100}
`c_slli     `| rd <= rs1 <<  imm        | {11, 100}


**Control Flow Instructions:**

Instruction  | Action                               | uOP code
-------------|--------------------------------------|--------------------------
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
-------------|--------------------------|--------------------------------------
`lb         `| rd <= mem[rs1 + imm]     | {01, 011}
`lbu        `| rd <= mem[rs1 + imm]     | {01, 010}
`lh         `| rd <= mem[rs1 + imm]     | {01, 101}
`lhu        `| rd <= mem[rs1 + imm]     | {01, 100}
`lw         `| rd <= mem[rs1 + imm]     | {01, 110}
`c_lw       `| rd <= mem[rs1 + imm]     | {01, 110}
`c_lwsp     `| rd <= mem[rs1 + imm]     | {01, 110}
`c_sw       `| mem[rs1+imm] <= rs2      | {10, 110}
`c_swsp     `| mem[rs1+imm] <= rs2      | {10, 110}
`sb         `| mem[rs2+imm] <= rs1      | {10, 010}
`sh         `| mem[rs2+imm] <= rs1      | {10, 100}
`sw         `| mem[rs2+imm] <= rs1      | {10, 110}


**CSR Instructions:**

Instruction  | Action                   | uOP code
-------------|--------------------------|--------------------------------------
`csrrc      `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrci     `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrs      `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrsi     `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrw      `| rd <= csr, csr <= rs1    | {rw,scf}
`csrrwi     `| rd <= csr, csr <= rs1    | {rw,scf}


**Mul/Div Instructions:**

Instruction  | Action                   | uOP code
-------------|--------------------------|--------------------------------------
`div        `| rd <= rs1 / rs2          | {11, 000}
`divu       `| rd <= rs1 / rs2          | {11, 001}
`mul        `| rd <= rs1 * rs2          | {01, 000}
`mulh       `| rd <= rs1 * rs2          | {01, 100}
`mulhsu     `| rd <= rs1 * rs2          | {01, 111}
`mulhu      `| rd <= rs1 * rs2          | {01, 101}
`rem        `| rd <= rs1 % rs2          | {10, 000}
`remu       `| rd <= rs1 % rs2          | {10, 001}

