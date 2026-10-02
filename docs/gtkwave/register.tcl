# GTKWave script for the register testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {register_tb.clk} {register_tb.rst} {register_tb.en} {register_tb.d[31:0]} {register_tb.q[31:0]}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
