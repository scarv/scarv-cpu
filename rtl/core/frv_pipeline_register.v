
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
output wire             o_busy   , // Stage N+1 ready to continue?

output wire [ RLEN-1:0] mr_data  , // Most recent data into the stage.

input  wire             flush    , // Flush the contents of the pipeline
input  wire [ RLEN-1:0] flush_dat, // Data to flush *into* the pipeline.

output reg  [ RLEN-1:0] o_data   , // Output data for stage N+1
output wire             o_valid  , // Input data from stage N valid?
input  wire             i_busy     // Stage N+1 ready to continue?

);

parameter RLEN             = 8; // Width of the pipeline register.
parameter BUFFER_HANDSHAKE = 0; // Implement buffered handshake protocol?

generate if(BUFFER_HANDSHAKE == 0) begin

    assign o_busy  = i_busy ;
    assign o_valid = i_valid;

    assign mr_data = o_data ;

    wire   progress= i_valid && !i_busy;

    always @(posedge g_clk) begin
        if(!g_resetn) begin
            o_data <= {RLEN{1'b0}};
        end else if(flush) begin
            o_data <= flush_dat;
        end else if(progress) begin
            o_data <= i_data;
        end
    end

end else begin

    reg [RLEN-1:0] b_data;
    reg            b_full;

    reg            ro_busy ;
    reg            ro_valid;
    
    assign o_busy  = ro_busy ;
    assign o_valid = ro_valid;

    assign mr_data = b_full ? b_data : o_data;

    always @(posedge g_clk) begin

        if(!g_resetn) begin
            
            b_full  <= 0;
            ro_busy  <= 0;
            ro_valid <= 0;
            o_data  <= 0;

        end else if(flush) begin

            b_full  <= 0;
            ro_busy  <= 0;
            ro_valid <= 0;
            b_data  <= flush_dat;
            o_data  <= flush_dat;

        end else if(!i_busy) begin
            
            // The next stage is not busy. We can emit either the buffered data,
            // or any valid data in the previous stage waiting to progress.

            if(!b_full) begin
                
                // Nothing in the buffer, so propagate previous stage to
                // next stage directly.
                ro_valid <= i_valid;
                o_data  <= i_data ;

            end else begin
                    
                // Propagate buffered content to the next stage.
                ro_valid <= 1'b1;
                o_data  <= b_data;

            end

            // Clear the stall condition
            ro_busy <= 1'b0;

            // Declare the buffer empty.
            b_full <= 1'b0;

        end else if(!ro_valid) begin
            
            // This stage is empty. n_busy = 1'b1

            // We can't be busy, as there's no data to work on.
            ro_busy  <= 1'b0;

            // Propagate previous stage inputs to next stage outputs.
            ro_valid <= i_valid;
            o_data  <= i_data;

            // Buffer is empty.
            b_full  <= 1'b0;


        end else if(i_valid && !ro_busy) begin
            
            // Next stage is busy with data, and this stage is recieving
            // something.
            // n_busy = 1'b1, ro_valid = 1'b1

            // The buffer will fill up now, since the next stage is busy
            // and the previous stage is also sending us new data.
            b_full  <= i_valid && ro_valid;
            ro_busy  <= i_valid && ro_valid;

        end

    end

    //
    // Update the data buffer.
    always @(posedge g_clk) begin
        if(!g_resetn) begin
            b_data <= 0;
        end else if(!o_busy) begin
            b_data <= i_data;
        end
    end

end endgenerate

endmodule
