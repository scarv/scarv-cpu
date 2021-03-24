
// Assign to an array element from a packed signal.
`define SME_P2A(ARRAY,PACKED,WIDTH,I) assign ARRAY[I]=PACKED[I*WIDTH+:WIDTH];

// Assign to a slice in a packed signal from an array element.
`define SME_A2P(PACKED,ARRAY,WIDTH,I) assign PACKED[I*WIDTH+:WIDTH] = ARRAY[I];

// Unpack a long packed singal into array elements.
`define SME_UNPACK(ARRAY, PACKED, WIDTH, N, GV)       \
    generate for(GV = 0; GV < N; GV=GV+1) begin \
        `SME_P2A(ARRAY, PACKED, WIDTH, GV)          \
    end endgenerate

// Pack array elements into a long packed signal.
`define SME_PACK(PACKED, ARRAY, WIDTH, N, GV)     \
    generate for(GV = 0; GV < N; GV=GV+1) begin \
        `SME_A2P(PACKED, ARRAY, WIDTH, GV)          \
    end endgenerate

//
// Wrapper for testing if SME is turned on based on the value of smectl.
`define SME_IS_ON(SMECTL) (|smectl[8:5])


//
// Is the supplied register address _potentially_ an SME share?
// If we come up with a complex mapping between share registers and
// addresses later, we only need to change this function.
`define sme_is_share_reg(ADDR) (addr[4])
