
# Masking ISE Implementation

*Notes and information on the masking ISE implementation in the scarv-cpu.*

---

## Feature identification:

*How can I tell if the scarv-cpu has been simulated / synthesised / implemented
with the masking ISE?*

- Bit 13 of the `uxcrypto` CSR is *set* iff the Masking ISE is implemented.

- If the Masking ISE is not implemented, then bit 13 of `uxcrypto` is *clear*
  and attempting to execute a Masking ISE instruction will raise an
  `Illegal Opcode` exception.

## Decode Stage Operand Assignments

- `rsX.lo` refers to the *low*/*even* register in an odd/even register source
  pair.

- `rsX.hi` then refers to the *high*/*odd* register in that same pair.

Instruction     | Operand A | Operand B | Operand C | Operand D
----------------|-----------|-----------|-----------|------------
`mask_b2a`      | `rs1.lo`  |           | `rs1.hi`  |
`mask_a2b`      | `rs1.lo`  |           | `rs1.hi`  |
`mask_b_mask`   | `rs1`     |           |           |
`mask_b_unmask` | `rs1.lo`  |           | `rs1.hi`  |
`mask_b_remask` | `rs1.lo`  |           | `rs1.hi`  |
`mask_a_mask`   | `rs1`     |           |           |
`mask_a_unmask` | `rs1.lo`  |           | `rs1.hi`  |
`mask_a_remask` | `rs1.lo`  |           | `rs1.hi`  |
`mask_b_not`    | `rs1.lo`  | `rs2.lo`  | `rs1.hi`  | `rs2.hi`
`mask_b_and`    | `rs1.lo`  | `rs2.lo`  | `rs1.hi`  | `rs2.hi`
`mask_b_ior`    | `rs1.lo`  | `rs2.lo`  | `rs1.hi`  | `rs2.hi`
`mask_b_xor`    | `rs1.lo`  | `rs2.lo`  | `rs1.hi`  | `rs2.hi`
`mask_b_add`    | `rs1.lo`  | `rs2.lo`  | `rs1.hi`  | `rs2.hi`
`mask_b_sub`    | `rs1.lo`  | `rs2.lo`  | `rs1.hi`  | `rs2.hi`
