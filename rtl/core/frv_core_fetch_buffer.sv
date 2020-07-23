
//
// module: frv_core_fetch_buffer
//
//  A buffer which eats 4-byte memory read data responses, and
//  emits 2 or 4-byte instructions.
//
module frv_core_fetch_buffer (

input              g_clk        , // Global clock
input              g_resetn     , // Global negative level triggered reset

input              flush        ,

input              f_4byte      , // Input data valid
input              f_2byte      , // Load only the 2 MS bytes
input              f_err        , // Input error
input  [XL:0]      f_in         , // Input data
output             f_ready      , // Buffer can accept more bytes.

output  [2:0]      buf_depth    , // Current buffer depth
output  [2:0]      n_buf_depth  ,
output             buf_16       , // 16 bit instruction next to be output
output             buf_32       , // 32 bit instruction next to be output
output [XL:0]      buf_out      , // Output data
output             buf_out_2    , // Buffer has 2 byte instruction.
output             buf_out_4    , // Buffer has 4 byte instruction.
output             buf_err      , // Output error bit
output             buf_valid    , // D output data is valid
input              buf_ready      // Eat 2/4 bytes

);

// Common core parameters and constants
`include "frv_common.svh"

parameter BWIDTH = 80;
parameter BW     = BWIDTH-1;
parameter HWS    = BWIDTH/16;   // halfwords in buffer.
parameter BE     = HWS-1;

reg  [BW:0] buffer  ;
wire [BW:0] n_buffer;

reg  [BE:0] buffer_err;
wire [BE:0] n_buffer_err;

reg  [ 2:0] bdepth  ;
wire [ 2:0] n_bdepth;
    
wire   buf_overflow   = {4'b0,bdepth} > HWS;

`ifdef DESIGNER_ASSERTION_FETCH_BUFFER
        
    always @(posedge g_clk) if(g_resetn) begin
        assert(!buf_overflow);
    end

`endif

// Is the buffer ready for new data to be inserted.
assign f_ready   = {4'b0,n_bdepth} <= HWS-2; 

assign buf_out   =  buffer    [31:0];
assign buf_err   = |buffer_err[ 1:0];

assign buf_16    = buf_out[1:0] != 2'b11 && |bdepth;
assign buf_32    = buf_out[1:0] == 2'b11 && |bdepth;
assign buf_depth = bdepth;
assign n_buf_depth = n_bdepth;

assign buf_out_2 = bdepth >= 3'd1 && buf_16;
assign buf_out_4 = bdepth >= 3'd2 && buf_32;

// 2 byte instruction being removed from the buffer.
wire   eat_2     = buf_out_2 && buf_ready;

// 4 byte instruction being removed from the buffer.
wire   eat_4     = buf_out_4 && buf_ready;

assign buf_valid = buf_out_2 || buf_out_4 ;

// Amount of stuff being added to the buffer this cycle.
wire [ 2:0] bdepth_add = {1'b0, f_4byte, f_2byte};

// Amount of stuff being removed from the buffer this cycle.
wire [ 2:0] bdepth_sub = {1'b0, eat_4  , eat_2  };

// Where to insert new data into the buffer.
wire [ 2:0] insert_at  = bdepth - bdepth_sub;

// Buffer depth in the next cycle.
assign      n_bdepth   = bdepth + bdepth_add - bdepth_sub;

wire [31:0] n_buffer_d      = f_2byte ? {16'b0, f_in[31:16]} :
                              f_4byte ?         f_in         :
                                                32'b0        ;

wire [BW:0] n_buffer_or_in  = {48'b0,n_buffer_d} << (16*insert_at );
wire [BW:0] n_buffer_shf_out= buffer             >> (16*bdepth_sub);

assign      n_buffer        = n_buffer_or_in | n_buffer_shf_out;

wire        n_err_in        = f_err && (f_2byte || f_4byte);
wire [BE:0] n_err_or_in     = {3'b0, {2{n_err_in}}} << insert_at;
wire [BE:0] n_err_shf_out   = buffer_err            >> insert_at;

assign      n_buffer_err    = n_err_or_in    | n_err_shf_out;

wire        update_buffer   = f_4byte || f_2byte || buf_ready;


//
// Register updates.
always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        buffer      <= 0;
        buffer_err  <= 0;
        bdepth      <= 0;
    end else if(update_buffer) begin
        buffer      <= n_buffer    ;
        buffer_err  <= n_buffer_err;
        bdepth      <= n_bdepth    ;
    end
end

endmodule
