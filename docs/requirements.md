
# Requirements

---

## Architecture

- Base Architecture: `RV32I`
  - `M` Extension
  - `C` Extension
  - `Zicsr` Extension
  - `Zifencei` Extension
  - System instructions: `ecall`, `ebreak`, `mret`.
- Priviledged ISA:
  - M mode only.
  - Memory mapped `mtime` and `mtimecmp`
  - CSRs:
    - `misa`
    - `mvendorid`
    - `marchid`
    - `mimpid`
    - `mhartid`
    - `mstatus`
    - `mtvec`
    - `medeleg`
    - `mideleg`
    - `mip`
    - `mie`
    - `instret`
    - `cycle` / `time`
    - `mtime`
    - `mtimecmp`
    - `mscratch`
    - `mepc`
    - `mcause`
    - `mtval`
- Interrupts:
  - Timer interrupt
  - Software interrupt
  - External interrupt

## Micro-architecture

- PPA Targets:
  - When implemented on Xilinx Artix-7 FPGA
  - Frequency: 200MHz
  - LUTs: 2000
  - FFs: 2000
- 5 Stage pipeline
  - Fetch
  - Decode
  - Operand Gather
  - Execute
  - Writeback
- Slow multiply / divide
