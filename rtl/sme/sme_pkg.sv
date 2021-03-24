
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
// Holds all information on an instruction going _into_ the SME pipeline.
typedef struct packed {

logic [ 3:0] rs1_addr ;
logic [XL:0] rs1_rdata;

logic [ 3:0] rs2_addr ;
logic [XL:0] rs2_rdata;

logic [ 4:0] shamt    ; // Shift amount for shift/rotate.

logic [ 3:0] rd_addr ;

} sme_data_t;

typedef struct packed {

logic   op_xor   ;
logic   op_and   ;
logic   op_or    ;
logic   op_notrs2; // invert 0'th share of rs2 for andn/orn/xnor.
logic   op_shift ;
logic   op_rotate;
logic   op_left  ;
logic   op_right ;
logic   op_add   ;
logic   op_sub   ;
logic   op_mask  ; // Enmask 0'th element of rs1 based on smectl_t
logic   op_unmask; // Unmask rs1
logic   op_remask; // remask rs1 based on smectl_t

} sme_alu_t;

typedef struct packed {

logic [ 1:0] bs       ; // Byte select for AES operations.

logic   op_aeses    ;
logic   op_aesesm   ;
logic   op_aesds    ;
logic   op_aesdsm   ;

} sme_cry_t;


//
// Holds all information on an instruction result going from SME to the host.
typedef struct packed {

logic [XL:0] rd_wdata;
logic [ 3:0] rd_addr ;

} sme_result_t;

endpackage

