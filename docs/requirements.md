
# Requirements

---

## Architecture

- Base Architecture: `RV32I`
  - `M` Extension
  - `C` Extension
  - `Zicsr` Extension
  - `Zifencei` Extension
  - System instructions: `ecall`, `ebreak`, `mret`.
- Extended Architecture: `XCrypto`
  - Support the full set of XCrypto instruction extensions.
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
