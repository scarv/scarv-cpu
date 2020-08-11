
# Instruction Table

**Integer ALU Instructions:**

Instruction  | Action                   
-------------|--------------------------
`add        `| rd <= rs1 + rs2          
`addi       `| rd <= rs1 + imm          
`c_add      `| rd <= rs1 + rs2          
`c_addi     `| rd <= rs1 + imm          
`c_addi16sp `| rd <= rs1 + imm          
`c_addi4spn `| rd <= rs1 + imm          
`c_mv       `| rd <= rs1                
`auipc      `| rd <= pc + imm20         
`c_sub      `| rd <= rs1 - rs2          
`sub        `| rd <= rs1 - rs2          
`and        `| rd <= rs1 & rs2          
`andi       `| rd <= rs1 & rs2          
`c_and      `| rd <= rs1 & rs2          
`c_andi     `| rd <= rs1 & imm          
`lui        `| rd <= {imm20, 12'b0}     
`c_li       `| rd <= imm                
`c_lui      `| rd <= imm                
`c_nop      `| nop                      
`or         `| rd <= rs1 or rs2         
`ori        `| rd <= rs1 or rs2         
`c_or       `| rd <= rs1 or rs2         
`c_xor      `| rd <= rs1 ^ rs2          
`xor        `| rd <= rs1 ^ rs2          
`xori       `| rd <= rs1 ^ imm          
`slt        `| rd <= rs1 < rs2          
`slti       `| rd <= rs1 < imm          
`sltu       `| rd <= rs1 < rs2          
`sltiu      `| rd <= rs1 < imm          
`sra        `| rd <= rs1 >>> rs2        
`srai       `| rd <= rs1 >>> rs2        
`c_srai     `| rd <= rs1 >>> imm        
`c_srli     `| rd <= rs1 >>  imm        
`srl        `| rd <= rs1 >> rs2         
`srli       `| rd <= rs1 >> rs2         
`sll        `| rd <= rs1 << rs2         
`slli       `| rd <= rs1 << rs2         
`c_slli     `| rd <= rs1 <<  imm        
`clz        `| rd <= f(rs1)
`ctz        `| rd <= f(rs1)
`gorc       `| rd <= f(rs1,rs2)
`gorci      `| rd <= f(rs1,rs2)
`max        `| rd <= f(rs1,rs2)
`maxu       `| rd <= f(rs1,rs2)
`min        `| rd <= f(rs1,rs2)
`minu       `| rd <= f(rs1,rs2)
`pcnt       `| rd <= f(rs1)
`sext_b     `| rd <= f(rs1)
`sext_h     `| rd <= f(rs1)
`slo        `| rd <= f(rs1, rs2)
`sloi       `| rd <= f(rs1, imm)
`sro        `| rd <= f(rs1, rs2)
`sroi       `| rd <= f(rs1, imm)


**Control Flow Instructions:**

Instruction  | Action                               
-------------|--------------------------------------
`beq        `| pc <= pc + (rs1 == rs2 ? imm : 4)    
`c_beqz     `| pc <= pc + (rs1==rs2 ? imm : 2)      
`bge        `| pc <= pc + (rs1 >= rs2 ? imm : 4)    
`bgeu       `| pc <= pc + (rs1 >= rs2 ? imm : 4)    
`blt        `| pc <= pc + (rs1 <  rs2 ? imm : 4)    
`bltu       `| pc <= pc + (rs1 <  rs2 ? imm : 4)    
`bne        `| pc <= pc + (rs1 != rs2 ? imm : 4)    
`c_bnez     `| pc <= pc + (rs1!=rs2 ? imm : 2)      
`c_ebreak   `| pc <= mtvec                          
`ebreak     `| pc <= mtvec                          
`ecall      `| pc <= mtvec                          
`c_j        `| pc <= pc + imm                       
`c_jr       `| pc <= rs1                            
`c_jal      `| pc <= pc + imm, rd <= pc + 2         
`jal        `| pc <= pc + imm, rd <= pc + 4         
`c_jalr     `| pc <= rs1, rd <= pc + 2              
`jalr       `| pc <= pc + rs1, rd <= pc + 4         
`mret       `| pc <= mepc                           


**Memory Instructions:**

Instruction  | Action                   
-------------|--------------------------
`lb         `| rd <= mem[rs1 + imm]     
`lbu        `| rd <= mem[rs1 + imm]     
`lh         `| rd <= mem[rs1 + imm]     
`lhu        `| rd <= mem[rs1 + imm]     
`lw         `| rd <= mem[rs1 + imm]     
`c_lw       `| rd <= mem[rs1 + imm]     
`c_lwsp     `| rd <= mem[rs1 + imm]     
`c_sw       `| mem[rs1+imm] <= rs2      
`c_swsp     `| mem[rs1+imm] <= rs2      
`sb         `| mem[rs2+imm] <= rs1      


**CSR Instructions:**

Instruction  | Action                   
-------------|--------------------------
`csrrc      `| rd <= csr, csr <= rs1    
`csrrci     `| rd <= csr, csr <= rs1    
`csrrs      `| rd <= csr, csr <= rs1    
`csrrsi     `| rd <= csr, csr <= rs1    
`csrrw      `| rd <= csr, csr <= rs1    
`csrrwi     `| rd <= csr, csr <= rs1    


**Mul/Div Instructions:**

Instruction  | Action                   
-------------|--------------------------
`div        `| rd <= rs1 / rs2          
`divu       `| rd <= rs1 / rs2          
`rem        `| rd <= rs1 % rs2          
`remu       `| rd <= rs1 % rs2          
`mul        `| rd <= rs1 * rs2          
`mulh       `| rd <= rs1 * rs2          
`mulhsu     `| rd <= rs1 * rs2          
`mulhu      `| rd <= rs1 * rs2          


**Bit Manipulation Instructions:**

Instruction  | Action                   
-------------|--------------------------
`ror        `| rd <= rs1 >>> rs2[4:0]
`rol        `| rd <= rs1 <<< rs2[4:0]
`rori       `| rd <= rs1 >>> imm
`andn       `| rd <= rs1 & ~rs2
`orn        `| rd <= rs1 | ~rs2
`xnor       `| rd <= rs1 ^ ~rs2
`pack       `| rd <= {rs2[15: 0], rs1[15: 0]}
`packu      `| rd <= {rs2[31:16], rs1[31:16]}
`packh      `| rd <= ZEXT({rs2[ 7: 0], rs1[ 7: 0]})
`grev       `| rd <= f(rs1,rs2)         
`grevi      `| rd <= f(rs1,rs2)         
`shfl       `| rd <= f(rs1,rs2)
`unshfl     `| rd <= f(rs1,rs2)
`shfli      `| rd <= f(rs1,rs2)
`unshfli    `| rd <= f(rs1,rs2)
`clmul      `| rd <= rs1 . rs2
`clmulh     `| rd <= rs1 . rs2
`clmulr     `| rd <= rs1 . rs2
`xperm      `| rd <= f(rs1,rs2)


**Cryptographic ISE instructions:**

Instruction  | Action                   
-------------|--------------------------
`ssm4.ed        `| 
`ssm4.ks        `| 
`saes32.encsm   `| 
`saes32.encs    `| 
`saes32.decsm   `| 
`saes32.decs    `| 
`ssha256.sig0   `| 
`ssha256.sig1   `| 
`ssha256.sum0   `| 
`ssha256.sum1   `| 
`ssm3.p0        `| 
`ssm3.p1        `| 
`ssha512.sig0l  `| 
`ssha512.sig0h  `| 
`ssha512.sig1l  `| 
`ssha512.sig1h  `| 
`ssha512.sum0r  `| 
`ssha512.sum1r  `| 
`pollentropy    `| 

---

# Dispatch Stage Operand Assignment.

**Integer ALU Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`add        `|  rs1         |  rs2          |  0
`addi       `|  rs1         |  imm          |  0
`c_add      `|  rs1         |  rs2          |  0
`c_addi     `|  rs1         |  imm          |  0
`c_addi16sp `|  rs1         |  rs2          |  0
`c_addi4spn `|  rs1         |  rs2          |  0
`c_mv       `|  rs1         |  0            |  0
`auipc      `|  PC+imm      |  0            |  0
`c_sub      `|  rs1         |  rs2          |  0
`sub        `|  rs1         |  rs2          |  0
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
`srli       `|  rs1         |  imm          |  0
`sll        `|  rs1         |  rs2          |  0
`slli       `|  rs1         |  imm          |  0
`c_slli     `|  rs1         |  imm          |  0
`clz        `|  rs1         |  0            |  0
`ctz        `|  rs1         |  0            |  0
`gorc       `|  rs1         |  rs2          |  0
`gorci      `|  rs1         |  rs2          |  0
`max        `|  rs1         |  rs2          |  0
`maxu       `|  rs1         |  rs2          |  0
`min        `|  rs1         |  rs2          |  0
`minu       `|  rs1         |  rs2          |  0
`pcnt       `|  rs1         |  0            |  0
`sext_b     `|  rs1         |  0            |  0
`sext_h     `|  rs1         |  0            |  0
`slo        `|  rs1         |  rs2          |  0
`sloi       `|  rs1         |  imm          |  0
`sro        `|  rs1         |  rs2          |  0
`sroi       `|  rs1         |  imm          |  0


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
`c_lw       `|  rs1         |  imm          | 0
`c_lwsp     `|  rs1         |  imm          | 0
`c_sw       `|  rs1         |  imm          | rs2
`c_swsp     `|  rs1         |  imm          | rs2
`sb         `|  rs1         |  imm          | rs2
`sh         `|  rs1         |  imm          | rs2
`sw         `|  rs1         |  imm          | rs2


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
`mulh       `|  rs1         |  rs2          | 0
`mulhsu     `|  rs1         |  rs2          | 0
`mulhu      `|  rs1         |  rs2          | 0
`rem        `|  rs1         |  rs2          | 0
`remu       `|  rs1         |  rs2          | 0


**Bit Manipulation Instructions:**

Instruction  | `opr_a`      | `opr_b`       | `opr_c`
-------------|--------------|---------------|-----------------
`ror        `| rs1          | rs2           | 
`rol        `| rs1          | rs2           | 
`rori       `| rs1          | imm           | 
`andn       `| rs1          | rs2           | 
`orn        `| rs1          | rs2           | 
`xnor       `| rs1          | rs2           | 
`pack       `| rs1          | rs2           | 
`packu      `| rs1          | rs2           | 
`packh      `| rs1          | rs2           | 
`grev       `| rs1          | rs2           | 
`grevi      `| rs1          | rs2           | 
`shfl       `| rs1          | rs2           | 
`unshfl     `| rs1          | rs2           | 
`shfli      `| rs1          | rs2           | 
`unshfli    `| rs1          | rs2           | 
`clmul      `| rs1          | rs2           | 
`clmulh     `| rs1          | rs2           | 
`clmulr     `| rs1          | rs2           | 
`xperm      `| rs1          | rs2           | 


**Cryptographic ISE instructions:**

Instruction        |`opr_a`      | `opr_b`       | `opr_c`    
-------------------|-------------|---------------|------------
`ssm4.ed        `| rs1           |     rs2       |  -
`ssm4.ks        `| rs1           |     rs2       |  -
`saes32.encsm   `| rs1           |     rs2       |  -
`saes32.encs    `| rs1           |     rs2       |  -
`saes32.decsm   `| rs1           |     rs2       |  -
`saes32.decs    `| rs1           |     rs2       |  -
`ssha256.sig0   `| rs1           |     -         |  -
`ssha256.sig1   `| rs1           |     -         |  -
`ssha256.sum0   `| rs1           |     -         |  -
`ssha256.sum1   `| rs1           |     -         |  -
`ssm3.p0        `| rs1           |     rs2       |  -
`ssm3.p1        `| rs1           |     rs2       |  -
`ssha512.sig0l  `| rs1           |     rs2       |  -
`ssha512.sig0h  `| rs1           |     rs2       |  -
`ssha512.sig1l  `| rs1           |     rs2       |  -
`ssha512.sig1h  `| rs1           |     rs2       |  -
`ssha512.sum0r  `| rs1           |     rs2       |  -
`ssha512.sum1r  `| rs1           |     rs2       |  -
`pollentropy    `|               |               |  -
