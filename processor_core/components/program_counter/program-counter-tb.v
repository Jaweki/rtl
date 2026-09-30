`timescale 1ns/1ps
module program_counter_tb;
    reg         clk = 0, rst = 1, en = 1;
    reg  [31:0] next_pc = 0;
    wire [31:0] pc, pc_plus4;
    integer errors = 0;

    program_counter dut (.clk(clk), .rst(rst), .en(en), .next_pc(next_pc), .pc(pc), .pc_plus4(pc_plus4));

    always #5 clk = ~clk;

    task expect_pc(input [31:0] expected, input [127:0] name);
        begin
            if (pc !== expected) begin
                $display("FAIL %0s: pc=%h expected=%h", name, pc, expected);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("program_counter.vcd");
        $dumpvars(0, program_counter_tb);

        @(posedge clk); #1; expect_pc(32'h0, "reset value");
        rst = 0;

        // sequential fetch: next_pc follows pc_plus4
        repeat (3) begin
            next_pc = pc_plus4;
            @(posedge clk); #1;
        end
        expect_pc(32'h0000000C, "three sequential steps");

        // branch / jump
        next_pc = 32'h0000_0100;
        @(posedge clk); #1; expect_pc(32'h0000_0100, "jump to 0x100");

        // hold when en = 0
        en = 0; next_pc = 32'h0000_0200;
        @(posedge clk); #1; expect_pc(32'h0000_0100, "hold when disabled");

        // reset again
        en = 1; rst = 1;
        @(posedge clk); #1; expect_pc(32'h0, "reset again");

        if (errors == 0) $display("PROGRAM COUNTER: ALL TESTS PASSED");
        else             $display("PROGRAM COUNTER: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule