
`include "xcfi_macros.sv"

//
// module: xcfi_insn_checker
//
//  Checking code which verifies that expected values match the
//  traced values for all instructions.
//
module xcfi_insn_checker(

    `XCFI_TRACE_INPUTS     ,

    input clock            ,
    input reset            ,
    input check            

);

parameter ILEN = 32                    ;
parameter NRET = 1                     ;
parameter XLEN = 32                    ;
parameter XL   = XLEN - 1              ;

wire                  spec_valid    ;
wire                  spec_trap     ;
wire [         4 : 0] spec_rs1_addr ;
wire [         4 : 0] spec_rs2_addr ;
wire [         4 : 0] spec_rs3_addr ;
wire [         4 : 0] spec_rd_addr  ;
wire                  spec_rd_wide  ;
wire [XLEN   - 1 : 0] spec_rd_wdata ;
wire [XLEN   - 1 : 0] spec_rd_wdatahi;
wire [XLEN   - 1 : 0] spec_pc_wdata ;
wire [XLEN   - 1 : 0] spec_mem_addr ;
wire [XLEN/8 - 1 : 0] spec_mem_rmask;
wire [XLEN/8 - 1 : 0] spec_mem_wmask;
wire [XLEN   - 1 : 0] spec_mem_wdata;

parameter channel_idx = 0;
        
(* keep *) wire valid = !reset && rvfi_valid[channel_idx];
(* keep *) wire [ILEN   - 1 : 0] insn      = rvfi_insn     [channel_idx*ILEN   +: ILEN];
(* keep *) wire                  trap      = rvfi_trap     [channel_idx];
(* keep *) wire                  halt      = rvfi_halt     [channel_idx];
(* keep *) wire                  intr      = rvfi_intr     [channel_idx];
(* keep *) wire [         4 : 0] rs1_addr  = rvfi_rs1_addr [channel_idx*5  +:  5];
(* keep *) wire [         4 : 0] rs2_addr  = rvfi_rs2_addr [channel_idx*5  +:  5];
(* keep *) wire [         4 : 0] rs3_addr  = rvfi_rs3_addr [channel_idx*5  +:  5];
(* keep *) wire [XLEN   - 1 : 0] rs1_rdata = rvfi_rs1_rdata[channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN   - 1 : 0] rs2_rdata = rvfi_rs2_rdata[channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN   - 1 : 0] rs3_rdata = rvfi_rs3_rdata[channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN   - 1 : 0] aux_data  = rvfi_aux      [channel_idx*XLEN   +: XLEN];
(* keep *) wire [         4 : 0] rd_addr   = rvfi_rd_addr  [channel_idx*5  +:  5];
(* keep *) wire [XLEN   - 1 : 0] rd_wdata  = rvfi_rd_wdata [channel_idx*XLEN   +: XLEN];
(* keep *) wire                  rd_wide   = rvfi_rd_wide  [channel_idx];
(* keep *) wire [XLEN   - 1 : 0] rd_wdatahi=rvfi_rd_wdatahi[channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN   - 1 : 0] pc_rdata  = rvfi_pc_rdata [channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN   - 1 : 0] pc_wdata  = rvfi_pc_wdata [channel_idx*XLEN   +: XLEN];

(* keep *) wire [XLEN   - 1 : 0] mem_addr  = rvfi_mem_addr [channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN/8 - 1 : 0] mem_rmask = rvfi_mem_rmask[channel_idx*XLEN/8 +: XLEN/8];
(* keep *) wire [XLEN/8 - 1 : 0] mem_wmask = rvfi_mem_wmask[channel_idx*XLEN/8 +: XLEN/8];
(* keep *) wire [XLEN   - 1 : 0] mem_rdata = rvfi_mem_rdata[channel_idx*XLEN   +: XLEN];
(* keep *) wire [XLEN   - 1 : 0] mem_wdata = rvfi_mem_wdata[channel_idx*XLEN   +: XLEN];

wire insn_pma_x = 1;
wire mem_pma_r = 1;
wire mem_pma_w = 1;

wire mem_access_fault = 1'b0;

reg integer i;

always @* begin
    if (!reset) begin
        cover(spec_valid);
        cover(spec_valid && !trap);
        cover(check && spec_valid);
        cover(check && spec_valid && !trap);
    end
    if (!reset && check) begin
        assume(spec_valid);

        if (!insn_pma_x || mem_access_fault) begin
            assert(trap);
            assert(rd_addr == 0);
            assert(rd_wdata == 0);
            assert(rd_wdatahi == 0);
            assert(mem_wmask == 0);
        end else begin

            if (rs1_addr == 0)
                assert(rs1_rdata == 0);

            if (rs2_addr == 0)
                assert(rs2_rdata == 0);

            if (!spec_trap) begin
                if (spec_rs1_addr != 0)
                    assert(spec_rs1_addr == rs1_addr);

                if (spec_rs2_addr != 0)
                    assert(spec_rs2_addr == rs2_addr);
                
                if (spec_rs3_addr != 0)
                    assert(spec_rs3_addr == rs3_addr);

                assert(spec_rd_addr == rd_addr);
                assert(spec_rd_wide == rd_wide);
                assert(spec_rd_wdata == rd_wdata);
                assert(spec_rd_wdatahi == rd_wdatahi);
                assert(spec_pc_wdata == pc_wdata);

                if (spec_mem_wmask || spec_mem_rmask) begin
                    assert(spec_mem_addr == mem_addr);
                end

                for (i = 0; i < XLEN/8; i = i+1) begin
                    if (spec_mem_wmask[i]) begin
                        assert(mem_wmask[i]);
                        assert(spec_mem_wdata[i*8 +: 8] == mem_wdata[i*8 +: 8]);
                    end else if (mem_wmask[i]) begin
                        assert(mem_rmask[i]);
                        assert(mem_rdata[i*8 +: 8] == mem_wdata[i*8 +: 8]);
                    end
                    if (spec_mem_rmask[i]) begin
                        assert(mem_rmask[i]);
                    end
                end
            end

            assert(spec_trap == trap);
        end
    end
end

xcfi_insn_spec i_insn_spec(
    .clock(clock),
    .reset(reset),
    `XCFI_TRACE_CONNECT,
    `XCFI_SPEC_CONNECT
);

endmodule
