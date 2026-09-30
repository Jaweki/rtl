`timescale 1ns/1ps
module instruction_memory_tb;
    reg  [31:0] addr = 0;
    wire [31:0] instr;
    integer errors = 0;

    instruction_memory #(.DEPTH_WORDS(16), .INIT_FILE("imem_test.hex")) dut (.addr(addr), .instr(instr));

    task check(input [31:0] a, input [31:0] expected, input [127:0] name);
        begin
            addr = a; #1;
            if (instr !== expected) begin
                $display("FAIL %0s: addr=%h instr=%h expected=%h", name, a, instr, expected);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("instruction_memory.vcd");
        $dumpvars(0, instruction_memory_tb);

        check(32'h0,  32'h00500093, "word 0");
        check(32'h4,  32'h00300113, "word 1");
        check(32'h8,  32'h002081B3, "word 2");
        check(32'h9,  32'h002081B3, "unaligned byte address maps to same word");
        check(32'h30, 32'h00000013, "unused word is NOP");

        if (errors == 0) $display("INSTRUCTION MEMORY: ALL TESTS PASSED");
        else             $display("INSTRUCTION MEMORY: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
