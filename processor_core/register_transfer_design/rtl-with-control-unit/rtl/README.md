# RV32I components (32-bit)

Every module has a self-checking testbench (`*-tb.v`) that prints PASS/FAIL and writes a `.vcd` waveform.

| Folder | File | Type | Purpose |
|---|---|---|---|
| alu | alu.v | combinational | arithmetic, logic, shifts, compares |
| comparator | comparator.v | combinational | decides if a branch is taken |
| immediate_generator | immediate-generator.v | combinational | extracts and sign-extends I/S/B/U/J immediates |
| registers | register.v | sequential | generic register with enable and reset |
| program_counter | program-counter.v | sequential | current instruction address, PC+4 |
| register_files | register-file.v | sequential | x0..x31, 2 read ports, 1 write port |
| memory_devices | instruction-memory.v | ROM | program storage (loaded from hex) |
| memory_devices | data-memory.v | RAM | byte-addressable load/store memory |
| datapath | control-unit.v | combinational | decodes opcode/funct3/funct7 into control signals |
| datapath | simple-datapath.v | top level | `riscv_core`: single-cycle RV32I CPU wiring everything together |

## Run
    make test          # from the repo root: all component tests + control unit + whole core
    make core          # only the whole-core test (runs tests/prog_all.S on the CPU)
    gtkwave core.vcd   # view the core waveform

The whole-core test assembles `processor_core/tests/prog_all.S` with `tests/asm.py`,
runs it on the Verilog core, and compares all 32 registers against an independent
Python reference model.

## ALU operation codes (the control unit must use the same values)
| alu_op | operation | alu_op | operation |
|---|---|---|---|
| 0000 | ADD | 0101 | XOR |
| 0001 | SUB | 0110 | SRL |
| 0010 | SLL | 0111 | SRA |
| 0011 | SLT | 1000 | OR |
| 0100 | SLTU | 1001 | AND |
