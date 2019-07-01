
//
// module: frv_pipeline_register
//
//  Represents a single pipeline stage register in the CPU core.
//
module frv_pipeline_register (

input  wire             g_clk    , // global clock
input  wire             g_resetn , // synchronous reset

input  wire [ RLEN-1:0] i_data   , // Input data from stage N
input  wire             i_valid  , // Input data valid?
output wire             o_ready  , // Stage N+1 ready to continue?

input  wire             flush    , // Flush the contents of the pipeline

output reg  [ RLEN-1:0] o_data   , // Output data for stage N+1
output wire             o_valid  , // Input data from stage N valid?
input  wire             i_ready    // Stage N+1 ready to continue?

);

parameter RLEN             = 8; // Width of the pipeline register.
parameter BUFFER_HANDSHAKE = 0; // Implement buffered handshake protocol?

generate if(BUFFER_HANDSHAKE == 0) begin

    assign o_ready = i_ready;
    assign o_valid = i_valid;

    wire   progress= i_valid && i_ready;

    always @(posedge g_clk) begin
        if(!g_resetn) begin
            o_data <= {RLEN{1'b0}};
        end else if(flush) begin
            o_data <= {RLEN{1'b0}};
        end else if(progress) begin
            o_data <= i_data;
        end
    end

end else begin

initial $display("ERROR: Buffered pipeline handshake not implemented.");

end endgenerate

endmodule
