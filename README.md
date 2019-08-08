
# [SCARV](https://github.com/scarv): CPU

*Acting as a component part of the
[SCARV](https://www.scarv.org)
project,
SCARV-CPU is 5-stage micro-controller CPU core,
augmented with the
[XCrypto](https://github.com/scarv/xcrypto)
instruction set extensions.*

---

- [Overview](#Overview)
- [Documentation](#Documentation)
- [Getting Started](#Getting-Started)
- [Design & Verification Flows](#Flows)
  - [RISC-V Compliance](#RISC-V-Compliance-Flow)
  - [Unit Tests](#Unit-Tests-Flow)
  - [RISC-V Formal](#RISC-V-Formal-Verfication-Flow)
- [Notes & Queries](#Notes-and-Queries)

## Overview

This is a 5-stage single issue in order CPU core, implementing the
RISC-V 32-bit integer base architecture, along with the **C**ompressed
and **M**ultiply extensions.
It's a micro-controller, with no cache, branch prediction or
virtual memory.

## Documentation

See the `docs/` folder for information on the design requirements and
the pipeline structure.

## Getting Started

You will need the following tools installed to use all parts of the
design flow:
- [Verilator](https://www.veripool.org/projects/verilator/)
- [Yosys](http://www.clifford.at/yosys/)
- [SymbiYosys](https://symbiyosys.readthedocs.io/en/latest/index.html)
- [A RISC-V Toolchain](https://github.com/riscv/riscv-gnu-toolchain)

These commands will checkout the repository and it's submodules, and
setup the project environment:

```sh
git clone git@github.com:scarv-cpu/scarv-cpu.git
cd mediocre-riscv/
git submodule update --init --remote
source bin/conf.sh
```

## Flows

There are several simulation and verification flows within the repository.

### RISC-V Compliance Flow

Runs the relevent 
[RISC-V compliance suite](https://github.com/riscv/riscv-compliance)
tests for the core.

**Building the tests:**

```sh
make riscv-compliance-build
```

This will compile all of the relevent `RV32IMC` tests for the core, create
simulation memory images (srec format) for them, and collect things
like objdump and signature files for debugging.

**Running the tests:**

```sh
make riscv-compliance-run
```

This will run all of the compliance tests for the core.
Results from the run, including waveforms and output signatures are
placed in `work/riscv-compliance/*`.

Currently, all tests pass except for the misaligned load/store test and
the misaligned jump test.
- Misaligned load/store fails because the core itself does not support
  this feature. This is valid behaviour for a RISC-V core, but the
  compliance suite test (at the time of writing) does not support it.
- The misaligned jump test fails because of how it depends on the `C`
  extension, which cannot be turned off in this core.

### Unit Tests Flow

These are simple directed tests which provide basic checks for
functionality not otherwise hit by the compliance suite.

Sources for the tests are found in `verif/unit/`

**Building:**
```sh
make unit-tests-build
```

**Running:**
```sh
make unit-tests-run
```

Results from the tests are placed in `work/unit/<test name>`.

### RISC-V Formal Verification Flow

The [riscv-formal](https://github.com/SymbioticEDA/riscv-formal/) framework
is used as the primary means of verifying correct instruction behaviour.

**Building:**
```sh
make riscv-formal-clean riscv-formal-prepare
```

**Running:**
```sh
make riscv-formal-run
```

This will run all checks against the core, running `NJOBS` in parallel.
One can control which checks are run, and how wide using the `NJOBS` and
`CHECKS` variables:

```sh
make riscv-formal-run NJOBS=2 CHECKS=insn_add_ch0\ insn_sw_ch0
```

Results are put in `work/riscv-formal/<check name>`

---

## Acknowledgements

This work has been supported in part by EPSRC via grant 
[EP/R012288/1](https://gow.epsrc.ukri.org/NGBOViewGrant.aspx?GrantRef=EP/R012288/1),
under the [RISE](http://www.ukrise.org) programme.
