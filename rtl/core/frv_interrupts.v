
//
// module: frv_interrupts
//
//  Handles internal and external interrupts.
//
module frv_interrupt (

input               g_clk           , //
input               g_resetn        , //

input               mstatus_mie     , // Global interrupt enable.

input               mie_meie        , // External interrupt enable.
input               mie_mtie        , // Timer interrupt enable.
input               mie_msie        , // Software interrupt enable.

input  wire         nmi_pending     , // Non-maskable interrupt pending.
input  wire         ex_pending      , // External interrupt pending?
input  wire [ 3:0]  ex_cause        , // External interrupt cause.
input  wire         ti_pending      , // From mrv_counters is mtime pending?
input  wire         sw_pending      , // Software interrupt pending?

output reg          mip_meip        , // External interrupt pending
output reg          mip_mtip        , // Timer interrupt pending
output reg          mip_msip        , // Software interrupt pending

output wire         int_trap_req    , // Request WB stage trap an interrupt
output wire [ 5:0]  int_trap_cause  , // Cause of interrupt
input  wire         int_trap_ack      // WB stage acknowledges the taken trap.

);

`include "frv_common.vh"

// NMI pending bit,
reg mip_nmi;

always @(posedge g_clk) begin
    if(!g_resetn) begin
        mip_meip <= 1'b0        ;
        mip_mtip <= 1'b0        ;
        mip_msip <= 1'b0        ;
        mip_nmi  <= 1'b0        ;
    end else begin
        mip_meip <= ex_pending  ;
        mip_mtip <= ti_pending  ;
        mip_msip <= sw_pending  ;
        mip_nmi  <= nmi_pending ;
    end
end

wire   raise_mei    = mstatus_mie && mie_meie && mip_meip;
wire   raise_mti    = mstatus_mie && mie_mtie && mip_mtip;
wire   raise_msi    = mstatus_mie && mie_msie && mip_msip;
wire   raise_nmi    = mstatus_mie &&             mip_nmi ;

assign int_trap_req = raise_mei || raise_mti || raise_msi || raise_nmi;

wire        use_extern_cause = |ex_cause;

wire [5:0]  extern_cause     = raise_nmi        ? TRAP_INT_NMI      :
                               use_extern_cause ? {2'b1, ex_cause}  :
                                                  TRAP_INT_MEI      ;

assign int_trap_cause = 
    raise_mei   ? extern_cause  :
    raise_mti   ? TRAP_INT_MTI  :
    raise_msi   ? TRAP_INT_MSI  :
                             0  ;

endmodule
