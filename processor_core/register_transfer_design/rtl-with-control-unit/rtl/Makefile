SHELL := /bin/bash
# Run from the repo root.
#   make test   run every component + control unit + whole-core test
#   make core   run only the whole-core test (runs prog_all.S on the CPU)
#   make clean  remove generated files
#   gtkwave core.vcd   view the core waveform

P = processor_core
C = $(P)/components

# name : directory : source file : testbench file
COMPONENT_TESTS = \
  alu:$(C)/alu:alu.v:alu-tb.v \
  comparator:$(C)/comparator:comparator.v:comparator-tb.v \
  program-counter:$(C)/program_counter:pc.v:program-counter-tb.v \
  register:$(C)/registers:register.v:register-tb.v \
  register-file:$(C)/register_files:register-file.v:register-file-tb.v \
  immediate-generator:$(C)/immediate_generators:immediate-generator.v:immediate-generator-tb.v \
  instruction-memory:$(C)/memory_devices:instruction-memory.v:instruction-memory-tb.v \
  data-memory:$(C)/memory_devices:data-memory.v:data-memory-tb.v \
  control-unit:$(P)/datapath:control-unit.v:control-unit-tb.v

CORE_SRC = $(P)/datapath/simple-datapath.v $(P)/datapath/control-unit.v \
  $(C)/alu/alu.v $(C)/comparator/comparator.v \
  $(C)/immediate_generators/immediate-generator.v \
  $(C)/program_counter/pc.v $(C)/register_files/register-file.v \
  $(C)/memory_devices/instruction-memory.v $(C)/memory_devices/data-memory.v

.PHONY: test core hex clean

test: hex
	@fail=0; \
	for t in $(COMPONENT_TESTS); do \
	  IFS=: read name dir src tb <<< "$$t"; \
	  echo "== $$name"; \
	  ( cd $$dir && iverilog -g2005 -o $$name.out $$src $$tb && vvp $$name.out > $$name.log ) || fail=1; \
	  if grep -q PASSED $$dir/$$name.log && ! grep -q FAIL $$dir/$$name.log; then grep PASSED $$dir/$$name.log; \
	  else echo "  *** FAILED or did not run (see $$dir/$$name.log)"; fail=1; fi; \
	done; \
	echo "== core"; \
	iverilog -g2005 -o core.out core-testbench.v $(CORE_SRC) && vvp core.out > core.log || fail=1; \
	if grep -q PASSED core.log && ! grep -q FAIL core.log; then grep PASSED core.log; \
	else echo "  *** FAILED or did not run (see core.log)"; fail=1; fi; \
	if [ $$fail -eq 1 ]; then echo "SOME TESTS FAILED"; exit 1; else echo "ALL TESTS PASSED"; fi

core: hex
	iverilog -g2005 -o core.out core-testbench.v $(CORE_SRC)
	vvp core.out

hex:
	python3 $(P)/tests/asm.py $(P)/tests/prog_all.S $(P)/tests/prog_all.hex $(P)/tests/expected_all.hex 400

clean:
	find . \( -name "*.out" -o -name "*.vcd" -o -name "*.log" \) -delete
