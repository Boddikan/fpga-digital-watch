
## Formal Verification with SymbiYosys

This directory contains formal verification testbenches for your Verilog modules, using [SymbiYosys (sby)](https://symbiyosys.readthedocs.io/).

- Each `.sby` file describes formal property checks for the corresponding module.
- These tests use formal methods to exhaustively prove correctness, not just simulation.
- Assertion files are written in SystemVerilog and document the properties being checked.

### Running a Formal Test

To run a formal verification test, use the `sby -f` command with the `.sby` file. For example, to check the `up_down_counter_rst` module:

```sh
sby -f sby/up_down_counter_rst.sby
```

This creates one or more subdirectories, one for each set of parameter values, containing logs and results. The directories created for the `up_down_counter_rst` module are `sby/up_down_counter_rst_max_4`, `sby/up_down_counter_rst_max_15` and `sby/up_down_counter_rst_max_60`.

The test passes if all properties are proven to hold for all possible input sequences.

### Directory Structure

- `.sby` files: SymbiYosys test configurations
- `*_assert.sv`: SystemVerilog assertion modules used in the formal checks
- Subdirectories: Output from each test run

Refer to each `.sby` file and assertion module for details on the properties being checked.
