# riscv-soc

This repository contains a simple RISC-V system-on-chip example. All Verilog
sources are located in `hardware/verilog`.  The hardware has been converted from
SystemVerilog to plain Verilog for wider tool compatibility.

The SoC now includes a simple memory-mapped UART accessible at
address `0x60000000`.

A small `hex2v.py` script in the `tools` directory converts Intel HEX files
into formats suitable for `$readmemh`. The software Makefile uses this
script automatically when building the program image.
