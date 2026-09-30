`timescale 1ns/1ps
module register_file_tb;
    reg         clk = 0, we = 0;
    reg  [4:0]  rs1_addr = 0, rs2_addr = 0, rd_addr = 0;
    reg  [31:0] rd_data = 0;
    wire [31:0] rs1_data, rs2_data;
    integer errors = 0, i;

    register_file dut (.clk(clk), .we(we), .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
                       .rd_addr(rd_addr), .rd_data(rd_data),
                       .rs1_data(rs1_data), .rs2_data(rs2_data));
    always #5 clk = ~clk;

    task write_reg(input [4:0] r, input [31:0] v);
        begin
            we = 1; rd_addr = r; rd_data = v;
            @(posedge clk); #1;
            we = 0;
        end
    endtask

    task check_read(input [4:0] r1, r2, input [31:0] e1, e2, input [127:0] name);
        begin
            rs1_addr = r1; rs2_addr = r2; #1;
            if (rs1_data !== e1 || rs2_data !== e2) begin
                $display("FAIL %0s: got %h,%h expected %h,%h", name, rs1_data, rs2_data, e1, e2);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);

        write_reg(5'd1, 32'hAAAA_0001);
        write_reg(5'd2, 32'hBBBB_0002);
        check_read(5'd1, 5'd2, 32'hAAAA_0001, 32'hBBBB_0002, "two read ports");

        write_reg(5'd0, 32'hFFFF_FFFF);
        check_read(5'd0, 5'd0, 32'h0, 32'h0, "x0 stays zero");

        // write disabled: value must not change
        we = 0; rd_addr = 5'd1; rd_data = 32'h1111_1111;
        @(posedge clk); #1;
        check_read(5'd1, 5'd2, 32'hAAAA_0001, 32'hBBBB_0002, "no write when we=0");

        // fill all registers and read back
        for (i = 1; i < 32; i = i + 1) write_reg(i[4:0], 32'h1000 + i);
        for (i = 1; i < 32; i = i + 1) begin
            rs1_addr = i[4:0]; #1;
            if (rs1_data !== 32'h1000 + i) begin
                $display("FAIL x%0d = %h", i, rs1_data); errors = errors + 1;
            end
        end
        $display("Checked x1..x31 read-back");

        if (errors == 0) $display("REGISTER FILE: ALL TESTS PASSED");
        else             $display("REGISTER FILE: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule