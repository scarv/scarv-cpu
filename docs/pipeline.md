
# Pipeline

*Description of the CPU pipeline stages and progression.*

- [Overview](#Overview)
- [Signal Naming](#Signal-Naming)
- [Pipeline Registers.](#Pipeline-Registers.)
- [Stalling, Forwarding and Bubbling.](#Stalling,-Forwarding-and-Bubbling.)
- [Control-flow changes](#Control-flow-changes)
- [Register Fields](#Register-Fields)

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
    encodings.
  - Dispatch : Gathers all operands needed to execute an instruction.
  - Execute: Performs compute on the instruction as needed and accesses
    data memory.
  - Writeback: Commits results to architectural state, sends control
    flow changes to the fetch stage, interracts with CSR registers.

## Signal Naming

Signals originating in a stage are prefixed depending on the stage,
and whether they are register or combinatorially driven.

Source Stage    | Combinatorial Prefix  | Registered Prefix
----------------|-----------------------|--------------------------
Fetch           | `c0_`                 | `r0_`
Decode          | `c1_`                 | `r1_`
Dispatch        | `c2_`                 | `r2_`
Execute         | `c3_`                 | `r3_`
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

There will be 4 pipeline registers:
- `p0` - Fetch -> Decode
- `p1` - Decode -> Dispatch
- `p2` - Dispatch -> Execute
- `p3` - Execute -> Writeback 

The pipeline will be organised into a module hierarchy:

```
    +------------------------#------------------------+
    |                        |                        |  
    |   frv_pipeline         | Memory I/F             |
    |                        |                        |
    |   +--------------------|-------------------+    |
    |   |              frv_fetch                 |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg_fd      p0    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_decode                |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg_dd      p1    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_dispatch              |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg_de      p2    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_execute               |----|---# Data Memory I/F
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |>             frv_pipereg_ew      p3    |    |
    |   +---^------------------------------------+    |
    |       |         |Valid   | Data                 |
    |       |Ready    |        |                      |
    |   +-------------*--------*-----------------+    |
    |   |              frv_writeback             |    |
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

Stages which forward values to dispatch and why:
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

The destination addresses for jump instructions are computed in
the execute stage.

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


### Decode Dispatch Pipeline Register

- Signals from decode stage into register are prefixed with `c1_`.
- Signals from register into dispatch are prefixed with `r2_`.

Signal     | Size  | Description
-----------|-------|-------------------------------------------------------
`rd`       |  5    | 
`rs1`      |  5    | 
`rs2`      |  5    | 
`imm`      |  32   | 


### Dispatch Execute Pipeline Register

- Signals from decode stage into register are prefixed with `c1_`.
- Signals from register into dispatch are prefixed with `r2_`.

Signal     | Size  | Description
-----------|-------|-------------------------------------------------------
`rd`       |  5    | 
`opr_a`    |  32   | 
`opr_b`    |  32   | 
`opr_c`    |  32   | 

