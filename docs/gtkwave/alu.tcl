# GTKWave script for the alu testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {alu_tb.a[31:0]} {alu_tb.b[31:0]} {alu_tb.alu_op[3:0]} {alu_tb.result[31:0]} {alu_tb.zero}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
gtkwave::highlightSignalsFromList {alu_tb.alu_op[3:0]}
gtkwave::/Edit/Data_Format/Binary
gtkwave::unhighlightSignalsFromList {alu_tb.alu_op[3:0]}
