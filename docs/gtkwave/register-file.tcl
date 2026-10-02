# GTKWave script for the register-file testbench. Loaded by docs/view_wave.sh (gtkwave -S).
set sigs [list {register_file_tb.clk} {register_file_tb.we} {register_file_tb.rd_addr[4:0]} {register_file_tb.rd_data[31:0]} {register_file_tb.rs1_addr[4:0]} {register_file_tb.rs2_addr[4:0]} {register_file_tb.rs1_data[31:0]} {register_file_tb.rs2_data[31:0]}]
gtkwave::addSignalsFromList $sigs
gtkwave::/Time/Zoom/Zoom_Full
