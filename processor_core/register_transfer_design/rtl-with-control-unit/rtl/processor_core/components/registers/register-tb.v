`timescale 1ns/1ps
module register_tb;
    reg         clk = 0, rst = 1, en = 0;
    reg  [31:0] d = 0;
    wire [31:0] q;
    integer errors = 0;

    register dut (.clk(clk), .rst(rst), .en(en), .d(d), .q(q));
    always #5 clk = ~clk;

    task expect_q(input [31:0] expected, input [127:0] name);
        begin
            if (q !== expected) begin
                $display("FAIL %0s: q=%h expected=%h", name, q, expected);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("register.vcd");
        $dumpvars(0, register_tb);

        @(posedge clk); #1; expect_q(32'h0, "reset clears");
        rst = 0; d = 32'hDEADBEEF; en = 0;
        @(posedge clk); #1; expect_q(32'h0, "ignores d when en=0");
        en = 1;
        @(posedge clk); #1; expect_q(32'hDEADBEEF, "loads d when en=1");
        d = 32'h12345678; en = 0;
        @(posedge clk); #1; expect_q(32'hDEADBEEF, "holds value");
        rst = 1;
        @(posedge clk); #1; expect_q(32'h0, "reset again");

        if (errors == 0) $display("REGISTER: ALL TESTS PASSED");
        else             $display("REGISTER: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule