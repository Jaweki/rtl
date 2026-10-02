#!/bin/sh
# Compile + run one component's testbench, then open its waveform in GTKWave
# with the right signals already added and the view zoomed to the whole run.
#
#   ./docs/view_wave.sh alu
#   components: alu comparator program-counter register register-file
#               immediate-generator instruction-memory data-memory
set -e
here=$(cd "$(dirname "$0")" && pwd)
c=$1
case "$c" in
  alu)                  dir=alu;                 vcd=alu ;;
  comparator)           dir=comparator;          vcd=comparator ;;
  program-counter)      dir=program_counter;     vcd=program_counter ;;
  register)             dir=registers;           vcd=register ;;
  register-file)        dir=register_files;      vcd=register_file ;;
  immediate-generator)  dir=immediate_generator; vcd=immediate_generator ;;
  instruction-memory)   dir=memory_devices;      vcd=instruction_memory ;;
  data-memory)          dir=memory_devices;      vcd=data_memory ;;
  *) echo "usage: $0 <alu|comparator|program-counter|register|register-file|immediate-generator|instruction-memory|data-memory>"; exit 1 ;;
esac
cd "$here/../components/$dir"
iverilog -g2005 -o "$c.out" "$c.v" "$c-tb.v"
vvp "$c.out" | grep -E "FAIL|PASSED"            # console result first
gtkwave -S "$here/gtkwave/$c.tcl" "$vcd.vcd"
