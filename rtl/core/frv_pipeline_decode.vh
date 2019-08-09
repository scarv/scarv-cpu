wire dec_lui        = d_data[6:2] == 5'h0D && d_data[1:0] == 2'd3;
wire dec_auipc      = d_data[6:2] == 5'h05 && d_data[1:0] == 2'd3;
wire dec_jal        = d_data[6:2] == 5'h1b && d_data[1:0] == 2'd3;
wire dec_jalr       = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h19 && d_data[1:0] == 2'd3;
wire dec_beq        = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bne        = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_blt        = d_data[14:12] == 3'd4 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bge        = d_data[14:12] == 3'd5 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bltu       = d_data[14:12] == 3'd6 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_bgeu       = d_data[14:12] == 3'd7 && d_data[6:2] == 5'h18 && d_data[1:0] == 2'd3;
wire dec_lb         = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lh         = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lw         = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lbu        = d_data[14:12] == 3'd4 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_lhu        = d_data[14:12] == 3'd5 && d_data[6:2] == 5'h00 && d_data[1:0] == 2'd3;
wire dec_sb         = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h08 && d_data[1:0] == 2'd3;
wire dec_sh         = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h08 && d_data[1:0] == 2'd3;
wire dec_sw         = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h08 && d_data[1:0] == 2'd3;
wire dec_addi       = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_slti       = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_sltiu      = d_data[14:12] == 3'd3 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_xori       = d_data[14:12] == 3'd4 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_ori        = d_data[14:12] == 3'd6 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_andi       = d_data[14:12] == 3'd7 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_slli       = d_data[31:27] == 5'd0 && d_data[14:12] == 3'd1 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_srli       = d_data[31:27] == 5'd0 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_srai       = d_data[31:27] == 5'd8 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h04 && d_data[1:0] == 2'd3;
wire dec_add        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sub        = d_data[31:25] == 7'd32 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sll        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd1 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_slt        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd2 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sltu       = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd3 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_xor        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd4 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_srl        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_sra        = d_data[31:25] == 7'd32 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_or         = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd6 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_and        = d_data[31:25] == 7'd0 && d_data[14:12] == 3'd7 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_fence      = d_data[14:12] == 3'd0 && d_data[6:2] == 5'h03 && d_data[1:0] == 2'd3;
wire dec_fence_i    = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h03 && d_data[1:0] == 2'd3;
wire dec_mul        = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_mulh       = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd1 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_mulhsu     = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd2 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_mulhu      = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd3 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_div        = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd4 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_divu       = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd5 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_rem        = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd6 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_remu       = d_data[31:25] == 7'd1 && d_data[14:12] == 3'd7 && d_data[6:2] == 5'h0C && d_data[1:0] == 2'd3;
wire dec_ecall      = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h000 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_ebreak     = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h001 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_mret       = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h302 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_wfi        = d_data[11:7] == 5'd0 && d_data[19:15] == 5'd0 && d_data[31:20] == 12'h105 && d_data[14:12] == 3'd0 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrw      = d_data[14:12] == 3'd1 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrs      = d_data[14:12] == 3'd2 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrc      = d_data[14:12] == 3'd3 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrwi     = d_data[14:12] == 3'd5 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrsi     = d_data[14:12] == 3'd6 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_csrrci     = d_data[14:12] == 3'd7 && d_data[6:2] == 5'h1C && d_data[1:0] == 2'd3;
wire dec_c_addi4spn = d_data[1:0] == 2'd0 && d_data[15:13] == 3'd0 && d_data[12:5] != 0;
wire dec_c_lw       = d_data[1:0] == 2'd0 && d_data[15:13] == 3'd2;
wire dec_c_sw       = d_data[1:0] == 2'd0 && d_data[15:13] == 3'd6;
wire dec_c_nop      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd0 && d_data[12:12] == 1'd0 && d_data[11:7] == 5'd0 && d_data[6:2] == 5'd0;
wire dec_c_addi     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd0;
wire dec_c_jal      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd1;
wire dec_c_li       = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd2;
wire dec_c_addi16sp = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd3 && d_data[11:7] == 5'd2;
wire dec_c_lui      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd3 && d_data[11:7] != 5'd2 && {d_data[12],d_data[6:2]} != 0;
wire dec_c_srli     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[11:10] == 2'd0 && d_data[12] == 1'b0;
wire dec_c_srai     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[11:10] == 2'd1 && d_data[12] == 1'b0;
wire dec_c_andi     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[11:10] == 2'd2;
wire dec_c_sub      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd0;
wire dec_c_xor      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd1;
wire dec_c_or       = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd2;
wire dec_c_and      = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[11:10] == 2'd3 && d_data[6:5] == 2'd3;
wire dec_c_j        = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd5;
wire dec_c_beqz     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd6;
wire dec_c_bnez     = d_data[1:0] == 2'd1 && d_data[15:13] == 3'd7;
wire dec_c_slli     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd0 && d_data[12] == 1'b0;
wire dec_c_lwsp     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd2 && d_data[11:7] != 0;
wire dec_c_jr       = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[6:2] == 5'd0 && d_data[11:7] != 0;
wire dec_c_mv       = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd0 && d_data[6:2] != 0;
wire dec_c_ebreak   = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd1 && d_data[11:7] == 5'd0 && d_data[6:2] == 5'd0;
wire dec_c_jalr     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd1 && d_data[6:2] == 5'd0 && d_data[11:7] != 0;
wire dec_c_add      = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd4 && d_data[12:12] == 1'd1 && d_data[6:2] != 5'd0;
wire dec_c_swsp     = d_data[1:0] == 2'd2 && d_data[15:13] == 3'd6;

wire dec_xc_ldr_b       = (d_data & 32'hfe00707f) == 32'h7003;
wire dec_xc_ldr_h       = (d_data & 32'hfe00707f) == 32'h2007003;
wire dec_xc_ldr_w       = (d_data & 32'hfe00707f) == 32'h4007003;
wire dec_xc_ldr_d       = (d_data & 32'hfe00707f) == 32'h6007003;
wire dec_xc_ldr_bu      = (d_data & 32'hfe00707f) == 32'h8007003;
wire dec_xc_ldr_hu      = (d_data & 32'hfe00707f) == 32'ha007003;
wire dec_xc_str_b       = (d_data & 32'h6007fff) == 32'h4023;
wire dec_xc_str_h       = (d_data & 32'h6007fff) == 32'h40a3;
wire dec_xc_str_w       = (d_data & 32'h6007fff) == 32'h4123;
wire dec_xc_mmul_3      = (d_data & 32'h60070ff) == 32'h4004023;
wire dec_xc_macc_1      = (d_data & 32'h60070ff) == 32'h40040a3;
wire dec_xc_madd_3      = (d_data & 32'h60070ff) == 32'h6004023;
wire dec_xc_msub_3      = (d_data & 32'h60070ff) == 32'h60050a3;
wire dec_xc_mror        = (d_data & 32'h60070ff) == 32'h5023;
wire dec_xc_rngtest     = (d_data & 32'hfffff07f) == 32'h300073;
wire dec_xc_rngsamp     = (d_data & 32'hfffff07f) == 32'h500073;
wire dec_xc_rngseed     = (d_data & 32'hfff07fff) == 32'h700073;
wire dec_xc_lut         = (d_data & 32'hfe00707f) == 32'h62006033;
wire dec_xc_bop         = (d_data & 32'h7e00707f) == 32'h64006033;
wire dec_xc_padd        = (d_data & 32'h3e00707f) == 32'h2000073;
wire dec_xc_psub        = (d_data & 32'h3e00707f) == 32'h4000073;
wire dec_xc_pror        = (d_data & 32'h3e00707f) == 32'h6000073;
wire dec_xc_psll        = (d_data & 32'h3e00707f) == 32'h8000073;
wire dec_xc_psrl        = (d_data & 32'h3e00707f) == 32'ha000073;
wire dec_xc_pror_i      = (d_data & 32'h3c00707f) == 32'h30007003;
wire dec_xc_psll_i      = (d_data & 32'h3c00707f) == 32'h2c007003;
wire dec_xc_psrl_i      = (d_data & 32'h3c00707f) == 32'h28007003;
wire dec_xc_pmul_l      = (d_data & 32'h3e00707f) == 32'hc000073;
wire dec_xc_pmul_h      = (d_data & 32'h3e00707f) == 32'he000073;
wire dec_xc_pclmul_l    = (d_data & 32'h3e00707f) == 32'h10000033;
wire dec_xc_pclmul_h    = (d_data & 32'h3e00707f) == 32'h12000033;
wire dec_xc_scatter_b   = (d_data & 32'h6007fff) == 32'h4223;
wire dec_xc_scatter_h   = (d_data & 32'h6007fff) == 32'h42a3;
wire dec_xc_gather_b    = (d_data & 32'hfe00707f) == 32'h3c001013;
wire dec_xc_gather_h    = (d_data & 32'hfe00707f) == 32'h3e001013;
wire dec_xc_aessub_enc  = (d_data & 32'hfe00707f) == 32'h1a007003;
wire dec_xc_aessub_encrot = (d_data & 32'hfe00707f) == 32'h1c007003;
wire dec_xc_aessub_dec  = (d_data & 32'hfe00707f) == 32'h1e007003;
wire dec_xc_aessub_decrot = (d_data & 32'hfe00707f) == 32'h20007003;
wire dec_xc_aesmix_enc  = (d_data & 32'hfe00707f) == 32'h22007003;
wire dec_xc_aesmix_dec  = (d_data & 32'hfe00707f) == 32'h24007003;
wire dec_xc_sha3_xy     = (d_data & 32'h3e00707f) == 32'h10007003;
wire dec_xc_sha3_x1     = (d_data & 32'h3e00707f) == 32'h12007003;
wire dec_xc_sha3_x2     = (d_data & 32'h3e00707f) == 32'h14007003;
wire dec_xc_sha3_x4     = (d_data & 32'h3e00707f) == 32'h16007003;
wire dec_xc_sha3_yx     = (d_data & 32'h3e00707f) == 32'h18007003;
wire dec_xc_sha256_s0   = (d_data & 32'hfff0707f) == 32'he007003;
wire dec_xc_sha256_s1   = (d_data & 32'hfff0707f) == 32'he107003;
wire dec_xc_sha256_s2   = (d_data & 32'hfff0707f) == 32'he207003;
wire dec_xc_sha256_s3   = (d_data & 32'hfff0707f) == 32'he307003;
wire dec_b_cmov        = (d_data & 32'h600707f) == 32'h6005033;
wire dec_b_rol         = (d_data & 32'hfe00707f) == 32'h60001033;
wire dec_b_ror         = (d_data & 32'hfe00707f) == 32'h60005033;
wire dec_b_rori        = (d_data & 32'hfc00707f) == 32'h60005013;
wire dec_b_fsl         = (d_data & 32'h600707f) == 32'h4001033;
wire dec_b_fsr         = (d_data & 32'h600707f) == 32'h4005033;
wire dec_b_fsri        = (d_data & 32'h400707f) == 32'h4005013;
wire dec_b_clmul       = (d_data & 32'hfe00707f) == 32'ha001033;
wire dec_b_clmulr      = (d_data & 32'hfe00707f) == 32'ha002033;
wire dec_b_clmulh      = (d_data & 32'hfe00707f) == 32'ha003033;
wire dec_b_bdep        = (d_data & 32'hfe00707f) == 32'h8002033;
wire dec_b_bext        = (d_data & 32'hfe00707f) == 32'h8006033;
wire dec_b_grev        = (d_data & 32'hfe00707f) == 32'h40001033;
wire dec_b_grevi       = (d_data & 32'hfc00707f) == 32'h40001013;

wire invalid_instr = !(dec_lui       ||dec_auipc     ||dec_jal
||dec_jalr      ||dec_beq       ||dec_bne       ||dec_blt       ||dec_bge
||dec_bltu      ||dec_bgeu      ||dec_lb        ||dec_lh        ||dec_lw
||dec_lbu       ||dec_lhu       ||dec_sb        ||dec_sh        ||dec_sw
||dec_addi      ||dec_slti      ||dec_sltiu     ||dec_xori      ||dec_ori
||dec_andi      ||dec_slli      ||dec_srli      ||dec_srai      ||dec_add
||dec_sub       ||dec_sll       ||dec_slt       ||dec_sltu      ||dec_xor
||dec_srl       ||dec_sra       ||dec_or        ||dec_and       ||dec_fence
||dec_fence_i   ||dec_mul       ||dec_mulh      ||dec_mulhsu    ||dec_mulhu
||dec_div       ||dec_divu      ||dec_rem       ||dec_remu      
||dec_ecall     ||dec_ebreak    ||dec_mret      ||dec_wfi
||dec_csrrw     ||dec_csrrs     ||dec_csrrc     ||dec_csrrwi    ||dec_csrrsi
||dec_csrrci    ||dec_c_addi4spn||dec_c_lw      ||dec_c_sw      ||dec_c_nop
||dec_c_addi    ||dec_c_jal     ||dec_c_li      ||dec_c_addi16sp||dec_c_lui
||dec_c_srli    ||dec_c_srai    ||dec_c_andi    ||dec_c_sub     ||dec_c_xor
||dec_c_or      ||dec_c_and     ||dec_c_j       ||dec_c_beqz    ||dec_c_bnez
||dec_c_slli    ||dec_c_lwsp    ||dec_c_jr      ||dec_c_mv
||dec_c_ebreak  ||dec_c_jalr    ||dec_c_add     ||dec_c_swsp 
||dec_b_bdep  || dec_b_bext  || dec_b_clmul  || dec_b_clmulh   || dec_b_clmulr
|| dec_b_cmov   || dec_b_grev  || dec_b_grevi   || dec_b_fsl   || dec_b_fsr
|| dec_b_fsri || dec_b_rol   || dec_b_ror  || dec_b_rori  || dec_xc_aesmix_dec
|| dec_xc_aesmix_enc  || dec_xc_aessub_dec   || dec_xc_aessub_decrot   ||
dec_xc_aessub_enc   || dec_xc_aessub_encrot   || dec_xc_bop   ||
dec_xc_gather_b   || dec_xc_gather_h   || dec_xc_ldr_b   || dec_xc_ldr_bu   ||
dec_xc_ldr_h   || dec_xc_ldr_hu   || dec_xc_ldr_w || dec_xc_lut   ||
dec_xc_macc_1   || dec_xc_madd_3   || dec_xc_mmul_3   || dec_xc_mror   ||
dec_xc_msub_3   || dec_xc_padd   || dec_xc_pclmul_h  || dec_xc_pclmul_l   ||
dec_xc_pmul_h   || dec_xc_pmul_l   || dec_xc_pror   || dec_xc_pror_i   ||
dec_xc_psll  || dec_xc_psll_i   || dec_xc_psrl   || dec_xc_psrl_i   ||
dec_xc_psub   || dec_xc_rngsamp   || dec_xc_rngseed   || dec_xc_rngtest   ||
dec_xc_scatter_b   || dec_xc_scatter_h || dec_xc_sha256_s0   ||
dec_xc_sha256_s1   || dec_xc_sha256_s2   || dec_xc_sha256_s3   ||
dec_xc_sha3_x1   || dec_xc_sha3_x2   || dec_xc_sha3_x4 || dec_xc_sha3_xy  ||
dec_xc_sha3_yx || dec_xc_str_b
|| dec_xc_str_h   || dec_xc_str_w   );
