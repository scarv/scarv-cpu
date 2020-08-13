
//
// module: scarv_ccx_ic
//
//  Core complex memory interconnect. A very simple, completely combinatorial
//  memory interconnect.
//
//  Interconnection Matrix:
//
//      Peripheral  |   CPU IMem    | CPU DMem
//      ------------|---------------|-----------------
//      rom         |       x       |  x
//      ram_a       |       x       |   
//      ram_b       |               |  x
//      ext         |       x       |  x
//      mmio        |               |  x
//
module scarv_ccx_ic #(
parameter   ROM_BASE    = 32'h0000_0000,
parameter   ROM_SIZE    = 32'h0000_0400,
parameter   RAM_BASE    = 32'h0001_0000,
parameter   RAM_SIZE    = 32'h0001_0000,
parameter   MMIO_BASE   = 32'h0002_0000,
parameter   MMIO_SIZE   = 32'h0000_0100,
parameter   EXT_BASE    = 32'h1000_0000,
parameter   EXT_SIZE    = 32'h1000_0000 
)(

input  wire      g_clk      ,
input  wire      g_resetn   ,

scarv_ccx_memif.RSP cpu_imem   , // CPU instruction memory
scarv_ccx_memif.RSP cpu_dmem   , // CPU data        memory

scarv_ccx_memif.REQ if_rom     ,
scarv_ccx_memif.REQ if_ram_a   ,
scarv_ccx_memif.REQ if_ram_b   ,
scarv_ccx_memif.REQ if_ext     ,
scarv_ccx_memif.REQ if_mmio

);

//
// Internal bus routing wires.

scarv_ccx_memif #() cpu_imem_rom ();
scarv_ccx_memif #() cpu_imem_ext ();
scarv_ccx_memif #() cpu_imem_mmio();

scarv_ccx_memif #() cpu_dmem_rom ();
scarv_ccx_memif #() cpu_dmem_ext ();

//
// Router Instances
// ------------------------------------------------------------

//
// Instruction Memory Request Router.
scarv_ccx_ic_router #(
.D0_BASE   (ROM_BASE   ),
.D0_SIZE   (ROM_SIZE   ),
.D1_BASE   (RAM_BASE   ),
.D1_SIZE   (RAM_SIZE   ),
.D2_BASE   (MMIO_BASE  ),
.D2_SIZE   (MMIO_SIZE  ),
.D3_BASE   (EXT_BASE   ),
.D3_SIZE   (EXT_SIZE   ) 
) i_router_imem (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.if_core    (cpu_imem       ),
.if_d0      (cpu_imem_rom   ),
.if_d1      (if_ram_a       ),
.if_d2      (cpu_imem_mmio  ),
.if_d3      (cpu_imem_ext   )
);

//
// Data Memory Request Router.
scarv_ccx_ic_router #(
.D0_BASE   (ROM_BASE   ),
.D0_SIZE   (ROM_SIZE   ),
.D1_BASE   (RAM_BASE   ),
.D1_SIZE   (RAM_SIZE   ),
.D2_BASE   (MMIO_BASE  ),
.D2_SIZE   (MMIO_SIZE  ),
.D3_BASE   (EXT_BASE   ),
.D3_SIZE   (EXT_SIZE   ) 
) i_router_dmem (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.if_core    (cpu_dmem       ),
.if_d0      (cpu_dmem_rom   ),
.if_d1      (if_ram_b       ),
.if_d2      (if_mmio        ),
.if_d3      (cpu_dmem_ext   )
);

//
// Arbiter and stub Instances
// ------------------------------------------------------------

scarv_ccx_ic_arbiter i_arbiter_rom (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.req_0      (cpu_imem_rom   ), // Requestor 0 (primary)
.req_1      (cpu_dmem_rom   ), // Requestor 1 (primary)
.rsp        (if_rom         )  // Responder   (secondary)
);


scarv_ccx_ic_arbiter i_arbiter_ext (
.g_clk      (g_clk          ),
.g_resetn   (g_resetn       ),
.req_0      (cpu_imem_ext   ), // Requestor 0 (primary)
.req_1      (cpu_dmem_ext   ), // Requestor 1 (primary)
.rsp        (if_ext         )  // Responder   (secondary)
);

//
// Instruction memory MMIO stub responder. Always returns an error response.
scarv_ccx_ic_stub i_imem_mmio_stub(.memif(cpu_imem_mmio));

endmodule

