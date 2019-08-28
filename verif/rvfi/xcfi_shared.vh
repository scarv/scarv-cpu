
//
// function: clmul_ref
//
//  32-bit carryless multiply reference function.
//
function [63:0] clmul_ref;
    input [31:0] lhs;
    input [31:0] rhs;

    reg [63:0] result;
    integer i;

    result =  rhs[0] ? lhs : 0;

    for(i = 1; i < 32; i = i + 1) begin
        
        result = result ^ (rhs[i] ? lhs<<i : 32'b0);

    end

    clmul_ref = result;

endfunction
