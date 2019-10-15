
# Pipeline

*Description of the CPU pipeline stages and progression.*

- [Overview](#Overview)
- [Signal Naming](#Signal-Naming)
- [Pipeline Registers.](#Pipeline-Registers.)
- [Stalling, Forwarding and Bubbling.](#Stalling,-Forwarding-and-Bubbling.)
- [Control-flow changes](#Control-flow-changes)
- [Register Fields](#Register-Fields)
- [Exceptions](#Exceptons)

---

## Overview

- The pipeline will have **5** stages.
  - There will hence be **4** pipeline registers.
- The pipleine will use handshakes to signal progression from one stage
  to another.
- The stages of the pipeline will be:
  - Fetch: Responsible for fetching data from memory and presenting it
    to the decode stage.
  - Decode: Transforms RISC-V encoded instructions into pipeline
    encodings. Gathers all operands needed to execute an instruction.
  - Execute: Performs compute on the instruction as needed.
  - Memory: Accesses data memory.
  - Writeback: Commits results to architectural state, sends control
    flow changes to the fetch stage, interracts with CSR registers.

![Pipeline Diagram](scarv-cpu-uarch.png)

## Signal Naming

Signals originating in a stage are prefixed depending on the stage,
and whether they are register or combinatorially driven.

Source Stage    | Combinatorial Prefix  | Registered Prefix
----------------|-----------------------|--------------------------
Fetch           | `c0_`                 | `r0_`
Decode          | `c1_`                 | `r1_`
Execute         | `c2_`                 | `r2_`
Memory          | `c3_`                 | `r3_`
Writeback       | `c4_`                 | `r4_`

A signal which crosses from one pipeline stage into another is
named for the stage it is aligned to.
For example, the instruction word to be decoded passes from Fetch
into Decode.
- The Fetch aligned version is called `c0_data`, since it is
  combinatorially driven into the pipeline register from the fetch
  stage.
- The Decode aligned version is called `r1_data`, since it is driven
  directly from the pipeline register into the decode stage.


## Pipeline Registers.

There are 4 pipeline registers:
- `p0` - Fetch -> Decode
- `p1` - Decode -> Execute 
- `p2` - Execute -> Memory
- `p3` - Memory -> Writeback 

The pipeline will be organised into a module hierarchy:

```
    +------------------------#------------------------+
    |                        |                        |  
    |   frv_pipeline         | Memory I/F             |
    |                        |                        |  
    |   +--------------------|-------------------+    |
    |   |              frv_fetch           s0    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg         p0    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_decode          s1    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg         p1    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_execute         s2    |----|---# RNG I/F
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg         p2    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_memory          s3    |----|---# Data Memory I/F
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg         p3    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_writeback       s4    |    |
    |   +----------------------------------------+    |
    |                                                 |
    +-------------------------------------------------+
```
## Stalling, Forwarding and Bubbling.

Stages which can *cause* a pipeline bubble:
- Dispatch

Stages which can *cause* a pipeline stall:
- Fetch
  - Not enough buffered data to form a valid instruction.
- Dispatch
  - Stalls Fetch and decode to insert a bubble.
- Execute
  - Waiting for data memory accesses to complete.
  - Waiting for slow multiply/divide operations to complete.

Stages which forward values to decode and why:
- Execute - to prevent RAW hazards.
- Writeback - to feed CSR and memory load values back into the pipe.


## Control-flow changes

All control flow changes occur from the writeback stage.
This can be due to one of:
- Direct jump (PC + Immediate)
- Indirect jump (Register + Immediate)
- Conditonal Jump (PC + Immediate)
- Exception Trap.
- Interrupt Trap.
- An `mret` instruction.

The destination addresses for conditional branch instructions
are computed in the decode stage.

The destination addresses for jump instructions are computed in
the execute stage.
Whether or not to perform a branch is also computed in the execute stage.

The destination address for a trap is held in the `mtvec` CSR.

The destination address for an `mret` instruction is held in the
`mepc` CSR.

## Register Fields

### Fetch Decode Pipeline Register

- Signals from fetch stage into register are prefixed with `c0_`.
- Signals from register into decode are prefixed with `r1_`.

Signal     | Size  | Description
-----------|-------|-------------------------------------------------------
`data`     | 32    | Input instruction word to the decode stage
`ferr`     |  1    | A fetch error occured so raise an exception


### Decode Execute Pipeline Register

- Signals from decode stage into register are prefixed with `c2_`.
- Signals from register into execute are prefixed with `r3_`.

Signal     | Size  | Description
-----------|-------|-------------------------------------------------------
`rd`       |  5    | Destination register address
`pc`       |  32   | Program counter
`opr_a`    |  32   | Operand A
`opr_b`    |  32   | Operand B
`opr_c`    |  32   | Operand C
`uop`      |  5    | Micro-op code
`fu`       |  8    | Functional Unit (alu/mem/jump/mul/csr)
`trap`     |  1    | Raise a trap?
`size`     |  2    | Size of the instruction.

### Execute Memory Pipeline register.

- Signals from Execute stage into register are prefixed with `c3_`.
- Signals from register into Memory are prefixed with `r4_`.

Signal     | Size  | Description
-----------|-------|-------------------------------------------------------
`rd`       |  5    | Destination register address
`opr_a`    |  32   | Operand A
`opr_b`    |  32   | Operand B
`uop`      |  5    | Micro-op code
`fu`       |  8    | Functional Unit (alu/mem/jump/mul/csr)
`trap`     |  1    | Raise a trap?
`size`     |  2    | Size of the instruction.

### Memory Writeback Pipeline register.

- Signals from Memory stage into register are prefixed with `c3_`.
- Signals from register into Writeback are prefixed with `r4_`.

Signal     | Size  | Description
-----------|-------|-------------------------------------------------------
`rd`       |  5    | Destination register address
`opr_a`    |  32   | Operand A
`opr_b`    |  32   | Operand B
`uop`      |  5    | Micro-op code
`fu`       |  8    | Functional Unit (alu/mem/jump/mul/csr)
`trap`     |  1    | Raise a trap?
`size`     |  2    | Size of the instruction.

---

## Exceptions


Where exceptions are raised, and how they are progressed from stage to
stage.

**Fetch:**
Raises:
- Fetch Bus error: propagated as a single bit into the fetch buffer.

**Decode:**
Raises:
- Decode Error: detected by decoder, propagated in pipeline trap bit.
    Cause code stored in `rd` pipeline field.
Propagates:
- Fetch bus error: detected in trap bit of fetch buffer.
    Cause code stored in `rd` pipeline field.

**Execute:**

Raises:
- Load/store address misaligned. Cause code stored in `rd`.
Propagates:
- Fetch bus error: detected in trap bit of fetch buffer.
    Cause code stored in `opr_b` pipeline field.
- Decode Error: detected by decoder, propagated in pipeline trap bit.
    Cause code stored in `opr_b` pipeline field.

**Memory:**
Propagates:
- Fetch bus error: detected in trap bit of fetch buffer.
    Cause code stored in `opr_b` pipeline field.
- Decode Error: detected by decoder, propagated in pipeline trap bit.
    Cause code stored in `opr_b` pipeline field.

**Writeback:**
Raises:
- Environment call. Cause communicated to CSRs directly.
- Breakpoint. Cause communicated to CSRs directly.
Propagates:
- Load/store address misaligned.
- Load/store bus error.
- Fetch bus error: detected in trap bit of fetch buffer.
- Decode Error: detected by decoder, propagated in pipeline trap bit.
