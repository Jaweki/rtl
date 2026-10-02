# GTKWave script for the program-counter testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {program_counter_tb.clk} {program_counter_tb.rst} {program_counter_tb.en} {program_counter_tb.next_pc[31:0]} {program_counter_tb.pc[31:0]} {program_counter_tb.pc_plus4[31:0]}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
