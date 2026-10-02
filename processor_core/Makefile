# Run every component testbench:   make test
# Remove generated files:          make clean
# View a waveform (example):       gtkwave components/alu/alu.vcd

TESTS = components/alu/alu \
        components/comparator/comparator \
        components/program_counter/program-counter \
        components/registers/register \
        components/register_files/register-file \
        components/immediate_generator/immediate-generator \
        components/memory_devices/instruction-memory \
        components/memory_devices/data-memory

.PHONY: test clean wave

test:
	@fail=0; \
	for t in $(TESTS); do \
	  dir=$$(dirname $$t); name=$$(basename $$t); \
	  echo "== $$name"; \
	  ( cd $$dir && iverilog -g2005 -o $$name.out $$name.v $$name-tb.v && vvp $$name.out > $$name.log ); \
	  grep -E "FAIL|PASSED" $$dir/$$name.log; \
	  if grep -q "FAIL" $$dir/$$name.log; then fail=1; fi; \
	done; \
	if [ $$fail -eq 1 ]; then echo "SOME TESTS FAILED"; exit 1; else echo "ALL COMPONENT TESTS PASSED"; fi

clean:
	find . -name "*.out" -o -name "*.vcd" -o -name "*.log" | xargs rm -f

# Open one component's waveform with the right signals and zoom:  make wave C=alu
wave:
	@./docs/view_wave.sh $(C)