
//
// module: frv_pipeline_front
//
//  Front-end of the pipeline. Responsible for instruction fetch and decode.
//
module frv_pipeline_front (

input                   g_clk       , // global clock
input                   g_resetn    , // synchronous reset

input  wire             cf_req      , // Control flow change request
input  wire [     XL:0] cf_target   , // Control flow change destination
output wire             cf_ack      , // Control flow change acknolwedge

output wire             imem_cen    , // Chip enable
output wire             imem_wen    , // Write enable
input  wire             imem_error  , // Error
input  wire             imem_stall  , // Memory stall
output wire [   XL/8:0] imem_strb   , // Write strobe
output wire [     XL:0] imem_addr   , // Read/Write address
input  wire [     XL:0] imem_rdata  , // Read data
output wire [     XL:0] imem_wdata  , // Write data

output wire             s2_p_valid  , // Pipeline control signals
output wire             s2_p_busy   , // Pipeline control signals

output wire [      4:0] s2_rd       , // Destination register address
output wire [      4:0] s2_rs1      , // Source register address 1
output wire [      4:0] s2_rs2      , // Source register address 2
output wire [     31:0] s2_imm      , // Decoded immediate
output wire [      4:0] s2_uop      , // Micro-op code
output wire [      4:0] s2_fu       , // Functional Unit
output wire             s2_trap     , // Raise a trap?
output wire [      7:0] s2_opr_src  , // Operand sources for dispatch stage.
output wire [      1:0] s2_size     , // Size of the instruction.
output wire [     31:0] s2_instr      // The instruction word.

);

// Value taken by the PC on a reset.
parameter FRV_PC_RESET_VALUE = 32'h8000_0000;

// Use a buffered handshake for the front-end output pipeline register.
parameter FRONT_PIPE_REG_BUFFERED = 1;

// If set, trace the instruction word through the pipeline. Otherwise,
// set it to zeros and let it be optimised away.
parameter TRACE_INSTR_WORD = 1'b1;

// Width in bits of the front-end output pipeline register
localparam FRONT_PIPE_REG_WIDTH = 68;

// Common core parameters and constants
`include "frv_common.vh"

//
// Event detection
// -------------------------------------------------------------------------

// A control flow change has completed this cycle.
wire cf_change_now = cf_req && cf_ack;

// -------------------------------------------------------------------------

wire         s1_p_busy              ; // Next Pipeline stage busy output.

wire [FRONT_PIPE_REG_WIDTH-1:0] p_pipe_input;
wire [FRONT_PIPE_REG_WIDTH-1:0] p_pipe_output;

wire         fe_flush = cf_change_now; // Flush stage
wire         fe_stall = s1_p_busy    ; // Stall stage
wire         fe_ready                ; // Stage ready to progress

wire [XL:0]  d_data                 ; // Data to be decoded.
wire         d_error                ; // Data was subject to an ifetch error.

//
// Sub-module instantiations.
// -------------------------------------------------------------------------


//
// instance : frv_pipeline_fetch
//
//  Fetch pipeline stage.
//
frv_pipeline_fetch #(
.FRV_PC_RESET_VALUE(FRV_PC_RESET_VALUE)
) i_pipeline_fetch (
.g_clk          (g_clk          ), // global clock
.g_resetn       (g_resetn       ), // synchronous reset
.cf_req         (cf_req         ), // Control flow change
.cf_target      (cf_target      ), // Control flow change target
.cf_ack         (cf_ack         ), // Acknowledge control flow change
.imem_cen       (imem_cen       ), // Chip enable
.imem_wen       (imem_wen       ), // Write enable
.imem_error     (imem_error     ), // Error
.imem_stall     (imem_stall     ), // Memory stall
.imem_strb      (imem_strb      ), // Write strobe
.imem_addr      (imem_addr      ), // Read/Write address
.imem_rdata     (imem_rdata     ), // Read data
.imem_wdata     (imem_wdata     ), // Write data
.fe_flush       (fe_flush       ), // Flush stage
.fe_stall       (fe_stall       ), // Stall stage
.fe_ready       (fe_ready       ), // Stage ready to progress
.d_data         (d_data         ), // Data to be decoded.
.d_error        (d_error        )
);


//
// ------------[Pipeline Stage / d_* outputs are registerd]-------------
//


//
// These wires go straight from the decoder into the next pipeline register.
wire [ 4:0] p_rd         ; // Destination register address
wire [ 4:0] p_rs1        ; // Source register address 1
wire [ 4:0] p_rs2        ; // Source register address 2
wire [31:0] p_imm        ; // Decoded immediate
wire [31:0] p_pc         ; // Program counter
wire [ 4:0] p_uop        ; // Micro-op code
wire [ 4:0] p_fu         ; // Functional Unit (alu/mem/jump/mul/csr)
wire        p_trap       ; // Raise a trap?
wire [ 7:0] p_opr_src    ; // Operand sources for dispatch stage.
wire [ 1:0] p_size       ; // Size of the instruction.
wire [31:0] p_instr      ; // The instruction word

assign p_pipe_input = {
    p_rd         , // Destination register address
    p_rs1        , // Source register address 1
    p_rs2        , // Source register address 2
    p_imm        , // Decoded immediate
    p_uop        , // Micro-op code
    p_fu         , // Functional Unit (alu/mem/jump/mul/csr)
    p_trap       , // Raise a trap?
    p_opr_src    , // Operand sources for dispatch stage.
    p_size         // Size of the instruction.
};

assign {
    s2_rd         , // Destination register address
    s2_rs1        , // Source register address 1
    s2_rs2        , // Source register address 2
    s2_imm        , // Decoded immediate
    s2_uop        , // Micro-op code
    s2_fu         , // Functional Unit (alu/mem/jump/mul/csr)
    s2_trap       , // Raise a trap?
    s2_opr_src    , // Operand sources for dispatch stage.
    s2_size         // Size of the instruction.
} = p_pipe_output;


//
// instance : frv_pipeline_decode
//
//  Decode stage of the CPU, responsible for turning RISC-V encoded
//  instructions into wider pipeline encodings.
//
frv_pipeline_decode #(
.TRACE_INSTR_WORD(TRACE_INSTR_WORD)
) i_pipeline_decode (
.d_valid     (fe_ready    ), // Is the input data valid.
.d_data      (d_data      ), // Data word to decode.
.d_error     (d_error     ), // Is d_data associated with a fetch error?
.p_rd        (p_rd        ), // Destination register address
.p_rs1       (p_rs1       ), // Source register address 1
.p_rs2       (p_rs2       ), // Source register address 2
.p_imm       (p_imm       ), // Decoded immediate
.p_uop       (p_uop       ), // Micro-op code
.p_fu        (p_fu        ), // Functional Unit (alu/mem/jump/mul/csr)
.p_trap      (p_trap      ), // Raise a trap?
.p_opr_src   (p_opr_src   ), // Operand sources for dispatch stage.
.p_size      (p_size      ), // Size of the instruction.
.p_instr     (p_instr     )  // The instruction word.
);

//
// module: frv_pipeline_register
//
//  Represents a single pipeline stage register in the CPU core.
//
frv_pipeline_register #(
.RLEN(FRONT_PIPE_REG_WIDTH),
.BUFFER_HANDSHAKE(FRONT_PIPE_REG_BUFFERED)
) i_core_front_register (
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (p_pipe_input     ), // Input data from stage N
.i_valid  (fe_ready         ), // Input data valid?
.o_busy   (s1_p_busy        ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Unconnected.
.flush    (fe_flush         ), // Flush the contents of the pipeline
.o_data   (p_pipe_output    ), // Output data for stage N+1
.o_valid  (s2_p_valid       ), // Input data from stage N valid?
.i_busy   (s2_p_busy        )  // Stage N+1 ready to continue?
);

generate if(TRACE_INSTR_WORD) begin

// Conditionally generated pipeline register to hold traced
// instruction words.
frv_pipeline_register #(
.RLEN(32),
.BUFFER_HANDSHAKE(FRONT_PIPE_REG_BUFFERED)
) i_core_front_instr_reg(
.g_clk    (g_clk            ), // global clock
.g_resetn (g_resetn         ), // synchronous reset
.i_data   (p_instr          ), // Input data from stage N
.i_valid  (fe_ready         ), // Input data valid?
.o_busy   (                 ), // Stage N+1 ready to continue?
.mr_data  (                 ), // Unconnected.
.flush    (fe_flush         ), // Flush the contents of the pipeline
.o_data   (s2_instr         ), // Output data for stage N+1
.o_valid  (                 ), // Input data from stage N valid?
.i_busy   (s2_p_busy        )  // Stage N+1 ready to continue?
);

end else begin

    assign s2_instr = 32'b0;

end endgenerate

endmodule
