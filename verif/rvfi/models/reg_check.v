
`include "xcfi_macros.sv"

//
// Responsible for checking that all register reads/writes are
// consistent, including double width writebacks and RS3 reads.
//
// WIP
//
module xcfi_insn_spec (

    `XCFI_TRACE_INPUTS,

    `XCFI_SPEC_OUTPUTS

);
`XCFI_INSN_CHECK_COMMON

wire [ 4:0] reg_num     = $anyconst;
reg         reg_written ;
reg  [XL:0] reg_value   ;

wire        reg_write_wide  = rvfi_rd_addr[4:1] == reg_num[4:1] &&
                              reg_num[0]                        &&
                              rvfi_rd_wide                      ;

wire        reg_write_en    = rvfi_valid && (
    rvfi_rd_addr == reg_num || reg_write_wide
);

wire [XL:0] reg_write_value = reg_write_wide ? rvfi_rd_wdatahi  :
                                               rvfi_rd_wdata    ;

//
// Update the register value as needed
always @(posedge clock) begin
    if(reset) begin
        reg_written <= 1'b0;
        reg_value   <= 0;
    end else if (reg_write_en) begin
        reg_written <= 1'b1;
        reg_value   <= reg_write_value;
    end
end

//
// Check that any subsequent reads of the register get the right value.
always @(posedge clock) begin
    if(!reset && rvfi_valid && reg_written) begin
        if(rvfi_rs1_addr == reg_num) begin
            assert(rvfi_rs1_rdata == reg_value);
        end
        if(rvfi_rs2_addr == reg_num) begin
            assert(rvfi_rs2_rdata == reg_value);
        end
        if(rvfi_rs3_addr == reg_num) begin
            assert(rvfi_rs3_rdata == reg_value);
        end
    end
end

//
// We don't use the instruction check logic
assign spec_valid       = 1'b0;
assign spec_trap        = 1'b0;
assign spec_rs1_addr    = `FIELD_RS1_ADDR;
assign spec_rs2_addr    = `FIELD_RS2_ADDR;
assign spec_rs3_addr    = `FIELD_RS3_ADDR;
assign spec_rd_addr     = `FIELD_RD_ADDR;
assign spec_rd_wdata    = 32'b0;
assign spec_rd_wide     = 1'b0;
assign spec_rd_wdatahi  = 32'b0;
assign spec_pc_wdata    = 0;
assign spec_mem_addr    = 0;
assign spec_mem_rmask   = 0;
assign spec_mem_wmask   = 0;
assign spec_mem_wdata   = 0;

endmodule

