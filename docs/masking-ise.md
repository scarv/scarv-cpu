
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
