
`include "xcfi_macros.sv"

//
// module: xcfi_testbench
//
//  The toplevel testbench for the XCFI checking.
//
module xcfi_testbench (
    input clock,
    input reset
);

parameter XCFI_CHECK_CYCLE  = 19       ;

parameter ILEN              = 32       ;
parameter NRET              = 1        ;
parameter XLEN              = 32       ;
parameter XL                = XLEN - 1 ;

assume property (reset == $initstate);

reg [7:0] cycle_reg = 0;

always @(posedge clock) begin
    cycle_reg <= reset ? 1 : cycle_reg + (cycle_reg != 255);
end

wire    check = cycle_reg == XCFI_CHECK_CYCLE;

// All `rvfi_*` wires.
`XCFI_TRACE_WIRES

xcfi_insn_checker i_insn_checker(
.clock            (clock            ),
.reset            (reset            ),
.check            (check            ),
`XCFI_TRACE_CONNECT
);

//
// instance: xcfi_wrapper
//
//  Wrapper module around the DUT.
//
xcfi_wrapper i_wrapper(
.clock            (clock            ),
.reset            (reset            ),
`XCFI_TRACE_CONNECT
);

endmodule
