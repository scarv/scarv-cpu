
module tb_sme_aes_sbox (
input g_clk,
input g_resetn,
output reg [7:0] dut_out_y,
output reg [7:0] grm_out_y
);

parameter   SMAX    = 3     ;
localparam  SM      = SMAX-1;

//
// Input generation
// ------------------------------------------------------------

integer ctr;
initial ctr = 0;

// DUT inputs
reg     [ 7:0] dut_in_x                     ;
reg     [ 7:0] dut_in_x_masked [SM:0]       ;
reg            dut_en    =1'b1;             ;
reg     [31:0] dut_rng         [SM:0]       ;
reg            dut_dec =1'b1                ;

// DUT/GRM outputs.
wire    [ 7:0] dut_out_y_masked[SM:0]       ;
wire    [ 7:0] grm_out_w                    ;

// Unmask the dut output
always @(*) begin : unmask_output
    integer i;
    dut_out_y = dut_out_y_masked[0];
    for(i = 1; i < SMAX; i=i+1) begin
        dut_out_y = dut_out_y ^ dut_out_y_masked[i];
    end
end

always @(posedge g_clk) begin
    integer i;
    ctr <= ctr + 1;
    if(ctr % 3==0) begin
        for(i = 0; i < SMAX; i=i+1) begin
            /* verilator lint_off WIDTH */
            dut_in_x   <= $random;
            dut_rng[i] <= $random;
            if(i  > 0) begin
                dut_in_x_masked[i] <= $random;
            end
            dut_dec    <= $random;
            /* verilator lint_on  WIDTH */
        end
    end
    grm_out_y <= grm_out_w;
    if(g_resetn && ctr%3==0) begin
        if(dut_out_y != grm_out_y) begin
            $display("ERROR");
            $finish;
        end
    end
end

always @(*) begin
    integer i;
    dut_in_x_masked[0] = dut_in_x;
    for (i = 1; i < SMAX; i=i+1) begin
        dut_in_x_masked[0] = dut_in_x_masked[0] ^ dut_in_x_masked[i];
    end
end

always @(posedge g_clk) begin
end

initial begin
    $dumpfile("work/waves-sme-aes.vcd");
    $dumpvars(0, tb_sme_aes_sbox);
end

//
// Submodule instances
// ------------------------------------------------------------

//
// Golden reference / un-masked.
riscv_crypto_aes_sbox i_grm(
.dec(dut_dec  ),
.in (dut_in_x ),
.fx (grm_out_w)
);

//
// DUT / Masked
sme_sbox_aes #(
.SMAX(SMAX)
) i_dut (
.g_clk      (g_clk      ),
.g_resetn   (g_resetn   ),
.en         (dut_en     ),
.rng        (dut_rng    ),
.dec        (dut_dec    ),
.sbox_in    (dut_in_x_masked ),
.sbox_out   (dut_out_y_masked)
);

endmodule

