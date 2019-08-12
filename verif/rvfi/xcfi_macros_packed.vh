//
// SCARV Project
// 
// University of Bristol
// 
// RISC-V Cryptographic Instruction Set Extension
// 
// Reference Implementation
// 
// 

//
// file: xcfi_macros_packed.vh
//
//  Contains various macros for verifying packed arithmetic operations.
//

`define PW_16   2'b11
`define PW_8    2'b10
`define PW_4    2'b01
`define PW_2    2'b00

//
// Pull the pack width encoding from an instruction.
//
`define INSTR_PACK_WIDTH d_data[31:30]

//
// Rotate pack width operation macro
//
//      Applies "OP" to the right sizes of data type and then writes
//      the results back,
//
`define PACK_WIDTH_ROTATE_RIGHT_OPERATION(AMNT) \
reg [31:0] result15, result14, result13, result12, result11, \
           result10, result9 , result8 , result7 , result6 , \
           result5 , result4 , result3 , result2 , result1 , \
           result0 ; \
reg [31:0] result; \
always @(*) begin \
    result15 = 0; result14 = 0; result13 = 0; result12 = 0; result11 = 0; \
    result10 = 0; result9  = 0; result8  = 0; result7  = 0; result6  = 0; \
    result5  = 0; result4  = 0; result3  = 0; result2  = 0; result1  = 0; \
    result0  = 0; result   = 0; \
    if(pw == `PW_16) begin \
        result1 = {4{`RS1[31:16]}} >> AMNT; \
        result0 = {4{`RS1[15: 0]}} >> AMNT; \
        result = {result1[15: 0],result0[15: 0]}; \
    end else if(pw ==  `PW_8) begin \
        result3 = {8{`RS1[31:24]}} >> AMNT; \
        result2 = {8{`RS1[23:16]}} >> AMNT; \
        result1 = {8{`RS1[15: 8]}} >> AMNT; \
        result0 = {8{`RS1[ 7: 0]}} >> AMNT; \
        result  = {result3[7:0],result2[7:0],result1[7:0],result0[7:0]};\
    end else if(pw ==  `PW_4) begin \
        result7 = {16{`RS1[31:28]}} >> AMNT; \
        result6 = {16{`RS1[27:24]}} >> AMNT; \
        result5 = {16{`RS1[23:20]}} >> AMNT; \
        result4 = {16{`RS1[19:16]}} >> AMNT; \
        result3 = {16{`RS1[15:12]}} >> AMNT; \
        result2 = {16{`RS1[11: 8]}} >> AMNT; \
        result1 = {16{`RS1[ 7: 4]}} >> AMNT; \
        result0 = {16{`RS1[ 3: 0]}} >> AMNT; \
        result  = {result7[3:0],result6[3:0],result5[3:0],result4[3:0],  \
                   result3[3:0],result2[3:0],result1[3:0],result0[3:0]}; \
    end else if(pw ==  `PW_2) begin \
        result15 = {32{`RS1[31:30]}} >> AMNT; \
        result14 = {32{`RS1[29:28]}} >> AMNT; \
        result13 = {32{`RS1[27:26]}} >> AMNT; \
        result12 = {32{`RS1[25:24]}} >> AMNT; \
        result11 = {32{`RS1[23:22]}} >> AMNT; \
        result10 = {32{`RS1[21:20]}} >> AMNT; \
        result9  = {32{`RS1[19:18]}} >> AMNT; \
        result8  = {32{`RS1[17:16]}} >> AMNT; \
        result7  = {32{`RS1[15:14]}} >> AMNT; \
        result6  = {32{`RS1[13:12]}} >> AMNT; \
        result5  = {32{`RS1[11:10]}} >> AMNT; \
        result4  = {32{`RS1[ 9: 8]}} >> AMNT; \
        result3  = {32{`RS1[ 7: 6]}} >> AMNT; \
        result2  = {32{`RS1[ 5: 4]}} >> AMNT; \
        result1  = {32{`RS1[ 3: 2]}} >> AMNT; \
        result0  = {32{`RS1[ 1: 0]}} >> AMNT; \
        result  = {result15[1:0],result14[1:0],result13[1:0],result12[1:0], \
                   result11[1:0],result10[1:0],result9 [1:0],result8 [1:0], \
                   result7 [1:0],result6 [1:0],result5 [1:0],result4 [1:0], \
                   result3 [1:0],result2 [1:0],result1 [1:0],result0 [1:0]};\
    end \
end \


//
// Shift pack width operation macro
//
//      Applies "OP" to the right sizes of data type and then writes
//      the results back,
//
`define PACK_WIDTH_SHIFT_OPERATION_RESULT(OP,AMNT) \
reg [31:0] result  ; \
always @(*) begin \
    result = 0; \
    if(pw == `PW_16) begin \
        result = {`RS1[31:16] OP AMNT, \
                  `RS1[15: 0] OP AMNT}; \
    end else if(pw ==  `PW_8) begin \
        result = {`RS1[31:24] OP AMNT, \
                  `RS1[23:16] OP AMNT, \
                  `RS1[15: 8] OP AMNT, \
                  `RS1[ 7: 0] OP AMNT}; \
    end else if(pw ==  `PW_4) begin \
        result = {`RS1[31:28] OP AMNT, \
                  `RS1[27:24] OP AMNT, \
                  `RS1[23:20] OP AMNT, \
                  `RS1[19:16] OP AMNT, \
                  `RS1[15:12] OP AMNT, \
                  `RS1[11: 8] OP AMNT, \
                  `RS1[ 7: 4] OP AMNT, \
                  `RS1[ 3: 0] OP AMNT}; \
    end else if(pw ==  `PW_2) begin \
        result = {`RS1[31:30] OP AMNT, \
                  `RS1[29:28] OP AMNT, \
                  `RS1[27:26] OP AMNT, \
                  `RS1[25:24] OP AMNT, \
                  `RS1[23:22] OP AMNT, \
                  `RS1[21:20] OP AMNT, \
                  `RS1[19:18] OP AMNT, \
                  `RS1[17:16] OP AMNT, \
                  `RS1[15:14] OP AMNT, \
                  `RS1[13:12] OP AMNT, \
                  `RS1[11:10] OP AMNT, \
                  `RS1[ 9: 8] OP AMNT, \
                  `RS1[ 7: 6] OP AMNT, \
                  `RS1[ 5: 4] OP AMNT, \
                  `RS1[ 3: 2] OP AMNT, \
                  `RS1[ 1: 0] OP AMNT}; \
    end \
end \


//
// Arithmetic pack width operation macro
//
//      Applies "OP" to the right sizes of data type and then writes
//      the results back,
//
//      If "HI" is set, the high half of the X bit partial result is
//      selected for the final packed result. Otherwise the low half
//      is used. This is used to represent the high and low packed
//      multiply operations.
//
//      Makes the register "result" available for checking the result of
//      A packed arithmetic operation.
//
`define PACK_WIDTH_ARITH_OPERATION_RESULT(OP,HI) \
reg [63:0] result15, result14, result13, result12, result11, \
           result10, result9 , result8 , result7 , result6 , \
           result5 , result4 , result3 , result2 , result1 , \
           result0 ; \
reg [31:0] result  ; \
always @(*) begin \
    result15 = 0; result14 = 0; result13 = 0; result12 = 0; result11 = 0; \
    result10 = 0; result9  = 0; result8  = 0; result7  = 0; result6  = 0; \
    result5  = 0; result4  = 0; result3  = 0; result2  = 0; result1  = 0; \
    result0  = 0; result   = 0; \
    if(pw == `PW_16) begin \
        result1 = `RS1[31:16] OP `RS2[31:16]; \
        result0 = `RS1[15: 0] OP `RS2[15: 0]; \
        result = HI ? \
            {result1[31:16],result0[31:16]} : \
            {result1[15: 0],result0[15: 0]} ; \
    end else if(pw ==  `PW_8) begin \
        result3 = `RS1[31:24] OP `RS2[31:24]; \
        result2 = `RS1[23:16] OP `RS2[23:16]; \
        result1 = `RS1[15: 8] OP `RS2[15: 8]; \
        result0 = `RS1[ 7: 0] OP `RS2[ 7: 0]; \
        result  = HI ?                                             \
            {result3[15:8],result2[15:8],result1[15:8],result0[15:8]}: \
            {result3[7 :0],result2[ 7:0],result1[ 7:0],result0[ 7:0]}; \
    end else if(pw ==  `PW_4) begin \
        result7 = `RS1[31:28] OP `RS2[31:28]; \
        result6 = `RS1[27:24] OP `RS2[27:24]; \
        result5 = `RS1[23:20] OP `RS2[23:20]; \
        result4 = `RS1[19:16] OP `RS2[19:16]; \
        result3 = `RS1[15:12] OP `RS2[15:12]; \
        result2 = `RS1[11: 8] OP `RS2[11: 8]; \
        result1 = `RS1[ 7: 4] OP `RS2[ 7: 4]; \
        result0 = `RS1[ 3: 0] OP `RS2[ 3: 0]; \
        result  = HI ?                                                   \
                  {result7[7:4],result6[7:4],result5[7:4],result4[7:4],  \
                   result3[7:4],result2[7:4],result1[7:4],result0[7:4]}: \
                  {result7[3:0],result6[3:0],result5[3:0],result4[3:0],  \
                   result3[3:0],result2[3:0],result1[3:0],result0[3:0]}; \
    end else if(pw ==  `PW_2) begin \
        result15 = `RS1[31:30] OP `RS2[31:30]; \
        result14 = `RS1[29:28] OP `RS2[29:28]; \
        result13 = `RS1[27:26] OP `RS2[27:26]; \
        result12 = `RS1[25:24] OP `RS2[25:24]; \
        result11 = `RS1[23:22] OP `RS2[23:22]; \
        result10 = `RS1[21:20] OP `RS2[21:20]; \
        result9  = `RS1[19:18] OP `RS2[19:18]; \
        result8  = `RS1[17:16] OP `RS2[17:16]; \
        result7  = `RS1[15:14] OP `RS2[15:14]; \
        result6  = `RS1[13:12] OP `RS2[13:12]; \
        result5  = `RS1[11:10] OP `RS2[11:10]; \
        result4  = `RS1[ 9: 8] OP `RS2[ 9: 8]; \
        result3  = `RS1[ 7: 6] OP `RS2[ 7: 6]; \
        result2  = `RS1[ 5: 4] OP `RS2[ 5: 4]; \
        result1  = `RS1[ 3: 2] OP `RS2[ 3: 2]; \
        result0  = `RS1[ 1: 0] OP `RS2[ 1: 0]; \
        result  = HI ?                                                      \
              {result15[3:2],result14[3:2],result13[3:2],result12[3:2],   \
               result11[3:2],result10[3:2],result9 [3:2],result8 [3:2],   \
               result7 [3:2],result6 [3:2],result5 [3:2],result4 [3:2],   \
               result3 [3:2],result2 [3:2],result1 [3:2],result0 [3:2]} : \
              {result15[1:0],result14[1:0],result13[1:0],result12[1:0],   \
               result11[1:0],result10[1:0],result9 [1:0],result8 [1:0],   \
               result7 [1:0],result6 [1:0],result5 [1:0],result4 [1:0],   \
               result3 [1:0],result2 [1:0],result1 [1:0],result0 [1:0]} ; \
    end \
end \


//
// Implement a 32x32 carryless multiply expression.
//
`define PW_CLMUL32(A,B,W)  (                \
    ( (B>>0 )&1'b1 ? {{64-W{1'b0}},A} << 0  : 64'b0) ^              \
    ( (B>>1 )&1'b1 ? {{64-W{1'b0}},A} << 1  : 64'b0) ^              \
    ( (B>>2 )&1'b1 ? {{64-W{1'b0}},A} << 2  : 64'b0) ^              \
    ( (B>>3 )&1'b1 ? {{64-W{1'b0}},A} << 3  : 64'b0) ^              \
    ( (B>>4 )&1'b1 ? {{64-W{1'b0}},A} << 4  : 64'b0) ^              \
    ( (B>>5 )&1'b1 ? {{64-W{1'b0}},A} << 5  : 64'b0) ^              \
    ( (B>>6 )&1'b1 ? {{64-W{1'b0}},A} << 6  : 64'b0) ^              \
    ( (B>>7 )&1'b1 ? {{64-W{1'b0}},A} << 7  : 64'b0) ^              \
    ( (B>>8 )&1'b1 ? {{64-W{1'b0}},A} << 8  : 64'b0) ^              \
    ( (B>>9 )&1'b1 ? {{64-W{1'b0}},A} << 9  : 64'b0) ^              \
    ( (B>>10)&1'b1 ? {{64-W{1'b0}},A} << 10 : 64'b0) ^              \
    ( (B>>11)&1'b1 ? {{64-W{1'b0}},A} << 11 : 64'b0) ^              \
    ( (B>>12)&1'b1 ? {{64-W{1'b0}},A} << 12 : 64'b0) ^              \
    ( (B>>13)&1'b1 ? {{64-W{1'b0}},A} << 13 : 64'b0) ^              \
    ( (B>>14)&1'b1 ? {{64-W{1'b0}},A} << 14 : 64'b0) ^              \
    ( (B>>15)&1'b1 ? {{64-W{1'b0}},A} << 15 : 64'b0) ^              \
    ( (B>>16)&1'b1 ? {{64-W{1'b0}},A} << 16 : 64'b0) ^              \
    ( (B>>17)&1'b1 ? {{64-W{1'b0}},A} << 17 : 64'b0) ^              \
    ( (B>>18)&1'b1 ? {{64-W{1'b0}},A} << 18 : 64'b0) ^              \
    ( (B>>19)&1'b1 ? {{64-W{1'b0}},A} << 19 : 64'b0) ^              \
    ( (B>>20)&1'b1 ? {{64-W{1'b0}},A} << 20 : 64'b0) ^              \
    ( (B>>21)&1'b1 ? {{64-W{1'b0}},A} << 21 : 64'b0) ^              \
    ( (B>>22)&1'b1 ? {{64-W{1'b0}},A} << 22 : 64'b0) ^              \
    ( (B>>23)&1'b1 ? {{64-W{1'b0}},A} << 23 : 64'b0) ^              \
    ( (B>>24)&1'b1 ? {{64-W{1'b0}},A} << 24 : 64'b0) ^              \
    ( (B>>25)&1'b1 ? {{64-W{1'b0}},A} << 25 : 64'b0) ^              \
    ( (B>>26)&1'b1 ? {{64-W{1'b0}},A} << 26 : 64'b0) ^              \
    ( (B>>27)&1'b1 ? {{64-W{1'b0}},A} << 27 : 64'b0) ^              \
    ( (B>>28)&1'b1 ? {{64-W{1'b0}},A} << 28 : 64'b0) ^              \
    ( (B>>29)&1'b1 ? {{64-W{1'b0}},A} << 29 : 64'b0) ^              \
    ( (B>>30)&1'b1 ? {{64-W{1'b0}},A} << 30 : 64'b0) ^              \
    ( (B>>31)&1'b1 ? {{64-W{1'b0}},A} << 31 : 64'b0) )

