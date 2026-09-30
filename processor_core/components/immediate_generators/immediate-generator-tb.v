`timescale 1ns/1ps
module immediate_generator_tb;
    reg  [31:0] instr;
    wire [31:0] imm;
    integer errors = 0;

    immediate_generator dut (.instr(instr), .imm(imm));

    task check(input [31:0] i, input [31:0] expected, input [127:0] name);
        begin
            instr = i; #10;
            if (imm !== expected) begin
                $display("FAIL %0s: instr=%h imm=%h expected=%h", name, i, imm, expected);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("immediate_generator.vcd");
        $dumpvars(0, immediate_generator_tb);

        check(32'h00500093, 32'd5,          "addi x1,x0,5     (I)");
        check(32'hFFF00093, 32'hFFFFFFFF,   "addi x1,x0,-1    (I neg)");
        check(32'h0020A423, 32'd8,          "sw x2,8(x1)      (S)");
        check(32'hFE20AE23, 32'hFFFFFFFC,   "sw x2,-4(x1)     (S neg)");
        check(32'h00208663, 32'd12,         "beq x1,x2,+12    (B)");
        check(32'hFE208EE3, 32'hFFFFFFFC,   "beq x1,x2,-4     (B neg)");
        check(32'h123450B7, 32'h12345000,   "lui x1,0x12345   (U)");
        check(32'h010000EF, 32'd16,         "jal x1,+16       (J)");
        check(32'hFF1FF0EF, 32'hFFFFFFF0,   "jal x1,-16       (J neg)");

        if (errors == 0) $display("IMMEDIATE GENERATOR: ALL TESTS PASSED");
        else             $display("IMMEDIATE GENERATOR: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
