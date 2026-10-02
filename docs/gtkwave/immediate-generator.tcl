# GTKWave script for the immediate-generator testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {immediate_generator_tb.instr[31:0]} {immediate_generator_tb.imm[31:0]}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
