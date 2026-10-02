# GTKWave script for the instruction-memory testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {instruction_memory_tb.addr[31:0]} {instruction_memory_tb.instr[31:0]}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
