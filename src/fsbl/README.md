
# First Stage Boot Loader

This is a *very* simple boot rom which will pull a program binary
from a UART port into memory before jumping to it.

It is designed to work with the Xilinx UARTLite IP core.

## FSBL Assumptions

- That there is a Xilinx UARTLite IP core accessible at
  `0x40600000`.

- That there is a Xilinx AXI GPIO IP core accessible at
  `0x40000000`.

- That the FSBL runs out of a *read only* memory.

- That the core is set up such that the post-reset PC value points
  at the base address of the memory the FSBL occupies.

- The FSBL program starts at the base address of the memory it
  occupies.

- The FSBL is *position independent*.

## FSBL Procedure

1. Initially the core is in reset.

2. The core is taken out of reset, and the PC is set to the
   base address of the FSBL rom.

3. The FSBL runs, minimally configuring any on-core state as needed.

4. The FSBL waits to recieve 8 bytes from the UART peripheral.

  - The first 4 bytes are the size of the program to download from the
    UART.

  - The second 4 bytes are the address to jump too when the program is
    finished downloading. This is typically the start address of the
    downloaded program.

5. The FSBL downloads the program, as per the specified length.

6. The FSBL jumps to the specified start address, and relinquishes
   control to the downloaded program.

At each step, an additional GPIO LED is turned on as a sort of "progress"
indicator for debugging.

