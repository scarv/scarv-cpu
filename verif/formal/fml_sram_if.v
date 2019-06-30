
//
// module: fml_sram_if.v
//
//  Contains various formal checks to lock down the functionality
//  of the SRAM interfaces
//
module fml_sram_if (
input               g_clk           , // global clock
input               g_resetn        , // synchronous reset

input  wire         mem_cen         , // Chip enable
input  wire         mem_wen         , // Write enable
input  wire         mem_error       , // Error
input  wire         mem_stall       , // Memory stall
input  wire [3:0]   mem_strb        , // Write strobe
input  wire [31:0]  mem_addr        , // Read/Write address
input  wire [31:0]  mem_rdata       , // Read data
input  wire [31:0]  mem_wdata         // Write data
);

//
// Initially, assume reset
initial begin
    assume(!g_resetn);
end

always @(posedge g_clk) begin

    if(g_resetn) begin
            
            
        // If there is an active write transaction
        if(mem_cen && mem_wen) begin
            
            // At least one bit of the strobe lines must be set.
            assert(mem_strb[0] || mem_strb[1] ||
                   mem_strb[2] || mem_strb[3] );

        end

        // If transaction was stalled in the previous cycle, it should
        // still be outstanding.
        if($past(mem_cen) && $past(mem_stall)) begin

            assert($past(mem_cen));

        end

        // If this is a stalled transaction
        if(mem_cen && $past(mem_cen) && $past(mem_stall)) begin
            
            // Address must remain stable
            assert($stable(mem_addr ));

            // Write enable must remain stable
            assert($stable(mem_wen  ));
            
            // If write enable is set
            if(mem_wen) begin
                
                // Wdata and wstrb must also be stable.
                assert($stable(mem_wdata));
                assert($stable(mem_strb));

            end

        end

    end

end

endmodule
