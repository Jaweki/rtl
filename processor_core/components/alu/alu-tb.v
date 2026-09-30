`timescale 1ns/1ps
module alu_tb;
    reg  [31:0] a, b;
    reg  [3:0]  alu_op;
    wire [31:0] result;
    wire        zero;
    integer errors = 0;

    alu dut (.a(a), .b(b), .alu_op(alu_op), .result(result), .zero(zero));

    task check(input [3:0] op, input [31:0] x, y, input [31:0] expected, input [127:0] name);
        begin
            alu_op = op; a = x; b = y; #10;
            if (result !== expected) begin
                $display("FAIL %0s: a=%h b=%h got=%h expected=%h", name, x, y, result, expected);
                errors = errors + 1;
            end else
                $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);

        check(4'b0000, 32'd10,        32'd20,        32'd30,        "ADD");
        check(4'b0000, 32'hFFFFFFFF,  32'd1,         32'd0,         "ADD wrap");
        check(4'b0001, 32'd20,        32'd5,         32'd15,        "SUB");
        check(4'b0001, 32'd5,         32'd20,        32'hFFFFFFF1,  "SUB negative");
        check(4'b0010, 32'd1,         32'd4,         32'd16,        "SLL");
        check(4'b0011, 32'hFFFFFFFF,  32'd1,         32'd1,         "SLT (-1<1)");
        check(4'b0011, 32'd1,         32'hFFFFFFFF,  32'd0,         "SLT (1<-1)");
        check(4'b0100, 32'hFFFFFFFF,  32'd1,         32'd0,         "SLTU");
        check(4'b0100, 32'd1,         32'hFFFFFFFF,  32'd1,         "SLTU 2");
        check(4'b0101, 32'hF0F0F0F0,  32'hFFFF0000,  32'h0F0FF0F0,  "XOR");
        check(4'b0110, 32'h80000000,  32'd4,         32'h08000000,  "SRL");
        check(4'b0111, 32'h80000000,  32'd4,         32'hF8000000,  "SRA");
        check(4'b0110, 32'h00000010,  32'd36,        32'h00000001,  "SRL uses low 5 bits");
        check(4'b1000, 32'hF0F0F0F0,  32'h0F0F0F0F,  32'hFFFFFFFF,  "OR");
        check(4'b1001, 32'hF0F0F0F0,  32'hFFFF0000,  32'hF0F00000,  "AND");

        // zero flag
        alu_op = 4'b0001; a = 32'd7; b = 32'd7; #10;
        if (zero !== 1'b1) begin $display("FAIL zero flag"); errors = errors + 1; end
        else $display("PASS zero flag");

        if (errors == 0) $display("ALU: ALL TESTS PASSED");
        else             $display("ALU: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule