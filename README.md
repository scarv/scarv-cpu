
# Vanilla RISC-V

*A toy 5 stage RISC-V CPU, implementing the `rv32imc` ISA.
It's not clever or special, it just does the job.*

---

- [Overview](#Overview)
- [Documentation](#Documentation)
- [Getting Started](#Getting-Started)
- [Design & Verification Flows](#Flows)
  - [RISC-V Compliance](#RISC-V-Compliance-Flow)
  - [Unit Tests](#Unit-Tests-Flow)
  - [RISC-V Formal](#RISC-V-Formal-Verfication-Flow)
  - [General Formal](#General-Formal-Verification-Flow)
- [Notes & Queries](#Notes-and-Queries)

## Overview

This is a toy 5-stage single issue in order CPU core, implementing the
RISC-V 32-bit integer base architecture, along with the **C**ompressed
and **M**ultiply extensions.
It's a micro-controller, with no cache, branch prediction or
virtual memory.

A list of the design requirements for the core can be found in
[docs/requirements.md](docs/requirements.md). These are what I set out
to meet when first building the core. They have changed a bit over time,
but are all now met.

## Documentation

- TBD

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
git clone git@github.com:ben-marshall/mediocre-riscv.git
cd mediocre-riscv/
git submodule update --init --remote
source bin/source.me.sh
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

### General Formal Verification Flow

There is a general formal flow (also using yosys) which checks things
like interface protocols.

#### SRAM Interface Checker

Used to check signal stability and sensical behaviour of the `mrv_cpu`
top level module.
The checkers are found in `verif/formal/`.

**Building:**
```sh
make formal-sram-build
```

**Running:**
```sh
make formal-sram-trace  # Create a VCD trace which adheres to all assertions
make formal-sram-cover  # Check all assertions are reachable.
make formal-sram-bmc    # Run the BMC checker.
```

In the case of a failure, the failing trace is written too
`work/formal/sram_check/`.

## Notes and Queries

Why did you make this?
- I wanted some experience with RISC-V and longer pipelines than what I'd
  worked with before.  Also, I like making CPUs. I wanted to build a RISC-V
  core I could use as the basis of future projects. 
- I don't usually publish what I build either, but figured there are
  enough hobby RISC-V cores out there already such that one more wouldn't
  hurt.

Why 5 pipeline stages?
- No special reason. It could be 6 stages if you split the decode and
  operand gather stages, or 4 stages if you merged mem and exeute.

How confident are you that this implementation is correct?
- That depends on which aspect of the core you talk about.
- I'm very confident that each instruction is implemented correctly,
  thanks to the `riscv-formal` integration. I'm also happy that the
  trace interface I built to service `riscv-formal` is also simple
  enough to be correct.
- I'm very confident that the `mrv_cpu` module SRAM interfaces are
  correct thanks to the formal checking flow I built for them.
- I am less confident about interrupts, CSRs and the AXI bus interface
  wrapper. The CSR interface for `riscv-formal` is not implemented,
  and it doesn't check everything about interrupts either.
- There is no coverage model for the core! That means that although I
  have tried to write some tests, I have no idea how much of the feature
  space they actually cover.

Why didn't you do the additional verification work on the bits you mention?
- Verification is *alot* of work. I love the challenge of verification, but
  the aim of this project was to learn about *building* a RISC-V CPU. Not to
  verify one. Hardware verification is a sysiphean task, and eventually
  pushes back *hard* against attempts to make a project fun.
- That said, I have learned a lot about how I *would* go about verifying
  a RISC-V core in the future. Spoiler: there are *alot* of cross cutting
  concerns thanks to the PRA and the modularity of RISC-V itself.

Can I use this in my project?
- Feel free. It's all MIT licensed.

Should I use this in my project?
- I'd be very happy if you did! Just remember, this is a *toy* project. It is
  *not* a properly verified core, and no doubt has bugs in it. You have been
  warned.

