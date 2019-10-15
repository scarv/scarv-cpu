
# Verification

*Notes on how the core has been verified for functional
correctness.*

---

## Overview

There are 4 components to the scarv-cpu verification:

- [RISC-V Compliance Tests](#RISC-V-Compliance-Tests)
- [Unit tests](#Unit-tests)
- [RISC-V Formal](#RISC-V-Formal)
- [XCFI Formal](#XCFI-Formal)

Ideally, design and verification of a CPU is done by different
people to minimise the chance of miss-interpreting the specifications.
[We have no such luxury](https://github.com/scarv/scarv-cpu/graphs/contributors).
While we have put considerable effort into building confidence in
the scarv-cpu as an *experimental platform*, it should not be
considered production ready.

### Getting Started

The following steps must be run before the verification flows can
be used:

- Make sure the `riscv-formal` and `riscv-compliance` submodules are
  checked out.

    ```sh
    $> git submodule update --init --recursive
    ```

- Make sure that the `RISCV` environment variable points to a toolchain
  installation.

    ```sh
    $> export RISCV=<path to RISC-V + XCrypto toolchain>
    ```

- Make sure the `YOSYS_ROOT` environmnet variable points to a
  yosys installation.

    ```sh
    $> export YOSYS_ROOT=<path to yosys installation>
    ```

- Finally, run the project environment configuration script. 
  It's output should look something like this:

    ```sh
    $> source bin/conf.sh
    ------------------------[CPU Project Setup]--------------------------
    $FRV_HOME       = /home/ben/scarv/repos/scarv-cpu
    $FRV_WORK       = /home/ben/scarv/repos/scarv-cpu/work
    $RISCV          = /home/ben/tools/xcrypto/v1.0.0
    $VERILATOR_ROOT = /home/ben/tools/verilator
    $YOSYS_ROOT     = /home/ben/tools/yosys
    $PATH           = /home/ben/tools/xcrypto/v1.0.0:/opt/riscv32:/home/ben/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
    ---------------------------------------------------------------------
    $>
    ```


## RISC-V Compliance Tests

- These are the official 
  [RISC-V compliance tests](https://github.com/riscv/riscv-compliance).

- They are used *only* as smoke tests to check that nothing major is
  broken.

- There is no coverage reporting from these tests.

- The core should *always* pass the relevent tests:

  - RV32I

  - RV32M

  - RV32C

### Running:

- First, make sure that the compliance suite is built:

    ```sh
    $> make riscv-compliance-build
    ```

  Note: the `RISCV` environment variable must be set for this to work.

  This will compile the relevent tests for the core, and put the
  build artifacts in `work/riscv-compliance`.

- Next, run the tests:

    ```sh
    $> make riscv-compliance-run
    ```

  This will print a brief report of all passing/failing tests.

- Results for the tests are found under `work/riscv-compliance/`.

  - These include VCD waveform files, verification signatures,
    simulation logs and GTKWave view annotations.


## Unit tests

These are very basic unit tests used to stress more complex parts
of the core, which are not touched by the compliance tests or the
formal frameworks.

Tested functionality includes:

- Performance Counters.

- Memory mapped timers.

- Interrupts.

- Smoke tests for developing new instructions.

### Running:

The following commands can be used to run the unit tests:

- Build the unit tests:

    ```sh
    $> make unit-tests-build
    ```


- Run all of the unit tests:

    ```sh
    $> make unit-tests-run
    ```

  Results will be put into `work/unit/<test name>/`.


- Clean up all build artifacts from the unit test.s

    ```sh
    $> make unit-tests-clean
    ```

## RISC-V Formal

This is 
[the framework](https://github.com/SymbioticEDA/riscv-formal)
developed by Clifford Wolf, and is used to
prove using Bounded Model Checking (BMC) that various pieces of
functionality about the core are correct.

- Every instruction produces the correct post-state for a given pre-state.

- The Program Counter updates consistently.

- Registers are read and written correctly wrt. program order.

### Running:

Note that the `YOSYS_ROOT` environment variable must point to a valid
yosys installation for this to work.

- Prepare the tests:

    ```sh
    $> make riscv-formal-prepare
    ```

- Run the tests:

    ```sh
    $> make riscv-formal-run
    ```

    It is recommended to actually invoke make with the `-j` flag, to
    allow multiple jobs to run in parallel.
    Our best results were obtained when running with the number of
    dedicated CPU cores, rather than the number of hardware threads
    (usually half whatever `$(nproc)` reports).

    Results for successful or failing proofs are found in
    `work/riscv-formal/<proof name>/`

- Alternativley, individual tests can be run using:

    ```sh
    $> sby -f $FRV_WORK/riscv-formal/<proof name>.sby
    ```

  Once the preparation step has been completed.

- Clean up:

    ```sh
    $> make riscv-formal-clean
    ```

## XCFI Formal

This is a copy of the RISC-V Formal framework, but adapted and
extended to support the XCrypto instructions.
XCFI extends RISC-V Formal by:

- Supporting upto 3 source registers per instruction.

- Supporting upto 2 destination registers per instruction.

- Supporting the XCrypto randomness interface.

All XCrypto instructions are verified using the XCFI Formal framework.

### Running:

Note that the `YOSYS_ROOT` environment variable must point to a valid
yosys installation for this to work.

- Prepare the tests:

    ```sh
    $> make xcfi-prepare
    ```

- Run the tests:

    ```sh
    $> make xcfi-run
    ```

    It is recommended to actually invoke make with the `-j` flag, to
    allow multiple jobs to run in parallel.
    Our best results were obtained when running with the number of
    dedicated CPU cores, rather than the number of hardware threads
    (usually half whatever `$(nproc)` reports).

    Results for successful or failing proofs are found in
    `work/xcfi/<proof name>/`

- Alternativley, individual tests can be run using:

    ```sh
    $> sby -f $FRV_WORK/xcfi/<proof name>.sby
    ```

  Once the preparation step has been completed.

- Clean up:

    ```sh
    $> make xcfi-clean
    ```
