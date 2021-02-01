
//
// package: sme_pkg
//
//  Package containing common useful functions / types for the SME
//  implementation.
//
package sme_pkg;

// Width of architectural registers
parameter XLEN  = 32      ;
parameter XL    = XLEN - 1;


//
// Wrapper for testing if SME is turned on based on the value of smectl.
function sme_is_on();
    input [XL:0] smectl;
    sme_is_on = |smectl[8:5];
endfunction


//
// Is the supplied register address _potentially_ an SME share?
// If we come up with a complex mapping between share registers and
// addresses later, we only need to change this function.
function sme_is_share_reg();
    input [4:0] addr;
    sme_is_share_reg = addr[4];
endfunction


//
// Holds all information on an instruction going _into_ the SME pipeline.
typedef struct packed {

logic [ 3:0] rs1_addr ;
logic [XL:0] rs1_rdata;

logic [ 3:0] rs2_addr ;
logic [XL:0] rs2_rdata;

logic [ 3:0] rd_addr ;

} sme_instr_t;


//
// Holds all information on an instruction result going from SME to the host.
typedef struct packed {

logic [XL:0] rd_wdata;
logic [ 3:0] rd_addr ;

} sme_result_t;

endpackage

