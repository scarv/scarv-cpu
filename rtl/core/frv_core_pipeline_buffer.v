
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

output [XL:0]      buf_out      , // Output data
output             buf_out_2    , // Buffer has 2 byte instruction.
output             buf_out_4    , // Buffer has 4 byte instruction.
output             buf_err      , // Output error bit
output             buf_valid    , // D output data is valid
input              buf_ready      // Eat 2/4 bytes

);

// Common core parameters and constants
`include "frv_common.vh"

reg [16:0] buffer    [2:0];
reg [16:0] n_buffer  [2:0];
reg [ 1:0] bdepth         ;
reg [ 1:0] n_bdepth       ;

assign f_ready = bdepth  < 2'd2                     ||
                 bdepth == 2'd2 && (eat_2 || eat_4) ||
                 bdepth == 2'd3 && (         eat_4) ;

assign buf_out   = {buffer[1][15:0], buffer[0][15:0]};
assign buf_err   =  buffer[0][16  ];

wire   buf_16    = buf_out[1:0] != 2'b11;
wire   buf_32    = buf_out[1:0] == 2'b11;

assign buf_out_2 = bdepth >= 2'd1 && buf_16;
assign buf_out_4 = bdepth >= 2'd2 && buf_32;

wire   eat_2     = buf_out_2 && buf_ready;
wire   eat_4     = buf_out_4 && buf_ready;

assign buf_valid = buf_out_2 || buf_out_4 ;

always @(*) begin
    // Stay the same by default
    n_bdepth      = bdepth   ;
    n_buffer[0]   = buffer[0];
    n_buffer[1]   = buffer[1];
    n_buffer[2]   = buffer[2];
    
    case(bdepth)
    0 : begin // empty
        if(f_4byte) begin
            n_buffer[0] = {f_err,f_in[15: 0]};
            n_buffer[1] = {f_err,f_in[31:16]};
            n_bdepth    = 2;
            //`FRV_COVER(1);
        end else if(f_2byte) begin
            n_buffer[0] = {f_err,f_in[31:16]};
            n_bdepth    = 1;
            //`FRV_COVER(1);
        end
    end
    1 : begin // 1 halfword
        if(f_4byte) begin
            if(eat_2) begin// Load 4, eat 2
                n_buffer[0] = {f_err,f_in[15: 0]};
                n_buffer[1] = {f_err,f_in[31:16]};
                n_bdepth    = 2;
                //`FRV_COVER(1);
            end else begin          // Load 4
                n_buffer[1] = {f_err,f_in[15: 0]};
                n_buffer[2] = {f_err,f_in[31:16]};
                n_bdepth    = 3;
                //`FRV_COVER(1);
            end
        end else begin              // Nothing being added
            if(eat_2) begin// eat 2
                n_bdepth    = 0;
                //`FRV_COVER(1);
            end
        end
    end
    2 : begin // 2 halfwords
        if(f_4byte) begin
            if(eat_4) begin         // Load 4, eat 4
                n_buffer[0] = {f_err,f_in[15: 0]};
                n_buffer[1] = {f_err,f_in[31:16]};
                n_bdepth    = 2;
                //`FRV_COVER(1);
            end else if(eat_2) begin// Load 4, eat 2
                n_buffer[0] = buffer[1];
                n_buffer[1] = {f_err,f_in[15: 0]};
                n_buffer[2] = {f_err,f_in[31:16]};
                n_bdepth    = 3;
                //`FRV_COVER(1);
            end
        end else begin              // Nothing being added
            if(eat_4) begin         // eat 4
                n_bdepth    = 0;
                //`FRV_COVER(1);
            end else if(eat_2) begin// eat 2
                n_buffer[0] = buffer[1];
                n_bdepth    = 1;
                //`FRV_COVER(1);
            end
        end
    end
    3 : begin // 3 halfwords
        if(f_4byte) begin
            if(eat_4) begin         // Load 4, eat 4
                n_buffer[0] = buffer[2];
                n_buffer[1] = {f_err,f_in[15: 0]};
                n_buffer[2] = {f_err,f_in[31:16]};
                n_bdepth    = 3;
                //`FRV_COVER(1);
            end
        end else begin              // Nothing being added
            if(eat_4) begin         // eat 4
                n_buffer[0] = buffer[2];
                n_bdepth    = 1;
                //`FRV_COVER(1);
            end else if(eat_2) begin// eat 2
                n_buffer[0] = buffer[1];
                n_buffer[1] = buffer[2];
                n_bdepth    = 2;
                //`FRV_COVER(1);
            end
        end
    end
    endcase
end

always @(posedge g_clk) begin
    if(!g_resetn || flush) begin
        bdepth      <= 0;
        buffer[0]   <= 0;
        buffer[1]   <= 0;
        buffer[2]   <= 0;
    end else begin
        bdepth      <= n_bdepth   ;
        buffer[0]   <= n_buffer[0];
        buffer[1]   <= n_buffer[1];
        buffer[2]   <= n_buffer[2];
    end
end

endmodule
