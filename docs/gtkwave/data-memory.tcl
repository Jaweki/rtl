# GTKWave script for the data-memory testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {data_memory_tb.clk} {data_memory_tb.mem_write} {data_memory_tb.mem_read} {data_memory_tb.funct3[2:0]} {data_memory_tb.addr[31:0]} {data_memory_tb.wdata[31:0]} {data_memory_tb.rdata[31:0]}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
gtkwave::highlightSignalsFromList {data_memory_tb.funct3[2:0]}
gtkwave::/Edit/Data_Format/Binary
gtkwave::unhighlightSignalsFromList {data_memory_tb.funct3[2:0]}
