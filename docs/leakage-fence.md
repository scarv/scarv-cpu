
# Leakage Fence Instruction

*This document describes the implementation of the `leakage barrier`
instructions.*

---

## Overview

The leakage barrier functionality consists of two instructions:

- `xc.lkgconf` - Writes a configuration register (`lkgcfg`) with a single
  source register word.

- `xc.lkgfence` - Clears / resets the micro-architectural state as
  specified in the `lkgcfg` register.

**Note:** Hereafter, the stating that a register is "cleared" should be
read as meaning either "set to zero" or "randomised".

The exact set of micro-architectural state controllable via the
instruction is implementation specific.

What follows is a description of how these instructions are implemented
inside the `scarv-cpu`.

## State

The following table lists the state which can be manage by the leakage
barrier instructions.

See "[docs/pipeline.md](pipeline.md)" for more information on the
pipeline structure of the core.

### Core Resources 

#### Fetch Stage

- No resources in the fetch stage are managed by leakage fences, since they
  are never data dependant.

#### Decode Stage

The decode stage operand registers are each controlled individually:

- `s2_opr_a`
- `s2_opr_b`
- `s2_opr_c`

#### Execute Stage

The execute stage pipeline result registers are controlled individually:

- `s3_opr_a`
- `s3_opr_b`

Other execute stage resources which can be cleared:

- The multiplier functional unit accumulator registers.
- The AES `mix` and `sub` functional units.

#### Memory Stage

The memory stage pipeline result registers are controlled individually:

- `s4_opr_a`
- `s4_opr_b`

### Uncore Resources

Three external pins will be provided to signal that un-core resources
should be cleared.
These can be used to control:

- Buffers in the memory hierarchy.

- Secret-sensitive peripherals.

## Configuration Register

This table describes which bits of the leakage barrier configuration
register control which resources.

Bit | Resource    | Description
----|-------------|----------------
0   | `s2_opr_a`  | Decode -> Execute operand A
1   | `s2_opr_b`  | Decode -> Execute operand B
2   | `s2_opr_c`  | Decode -> Execute operand C
3   | `s3_opr_a`  | Execute -> Memory result register A
4   | `s3_opr_b`  | Execute -> Memory result register B
5   | `fu_mult`   | Multiplier accumulate registers.
6   | `fu_aessub` | AES sub-bytes registers.
7   | `fu_aesmix` | AES mix registers.
8   | `s4_opr_a`  | Memory -> Writeback result register A
9   | `s4_opr_b`  | Memory -> Writeback result register B
10  | `uncore_0`  | Un-core resource 0
11  | `uncore_1`  | Un-core resource 1
12  | `uncore_2`  | Un-core resource 2

## RTL Information

Some notes on the RTL implementation of these instructions:

- The `lkgcfg` register will live inside the decode stage.

  - It's value will be made available to all downstream stages.
    
    - This is done just by making the wire available. It's value is
      *not* transmitted down the pipeline registers as this defeats the
      object of the instruction somewhat.

  - Forwarding / instruction consistency is *not* a consideration for it.

    - Hence if an a fence immediately follows a configure instruction, we
      don't bubble the pipeline. There are no archtiectural effects which
      might be ruined by this. It is upto the programmer to use the
      instruction sensibly.

  - We only care that it's value is set correctly with respect to (not-)taken
    control flow paths.

  - Hence, the instruction to set it's value must reach the writeback stage
    before writing the control register.

- Uncore resources are signalled to be cleared from the *memory* stage,
  since this is the only stage where the CPU can normally access
  uncore resources.

- The "clearing" or "randomising" of a resource is controlled by
  a synthesis time parameter.

  - The randomness source is a simple 32-bit LFSR.

  - The LFSR is updated *only* when a fence instruction is executed.

  - The LFSR will live in the decode stage with the `lkgcfg` register.

- The `xc.lkgfence` instruction can be configured at *synthesis time* to
  bubble the pipeline.

  - This causes a 3-cycle performance penalty, but ensures that there
    are no interractions with the forwarding network.

