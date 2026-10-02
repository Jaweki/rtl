# GTKWave script for the comparator testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {comparator_tb.a[31:0]} {comparator_tb.b[31:0]} {comparator_tb.funct3[2:0]} {comparator_tb.eq} {comparator_tb.lt} {comparator_tb.ltu} {comparator_tb.taken}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
gtkwave::highlightSignalsFromList {comparator_tb.funct3[2:0]}
gtkwave::/Edit/Data_Format/Binary
gtkwave::unhighlightSignalsFromList {comparator_tb.funct3[2:0]}
