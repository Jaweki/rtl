`timescale 1ns/1ps
module control_unit_tb;
    reg  [6:0] opcode = 0;
    reg  [2:0] funct3 = 0;
    reg  [6:0] funct7 = 0;
    wire reg_write, alu_src_a, alu_src_b, mem_read, mem_write, branch, jal, jalr, illegal;
    wire [3:0] alu_op;
    wire [1:0] wb_sel;
    integer errors = 0;

    control_unit dut (.opcode(opcode), .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .alu_op(alu_op), .mem_read(mem_read), .mem_write(mem_write),
        .wb_sel(wb_sel), .branch(branch), .jal(jal), .jalr(jalr), .illegal(illegal));

    // expected: {reg_write, alu_src_a, alu_src_b, mem_read, mem_write, branch, jal, jalr, illegal}, wb_sel, alu_op
    task check(input [6:0] op, input [2:0] f3, input [6:0] f7,
               input [8:0] flags, input [1:0] wb, input [3:0] aop, input [159:0] name);
        begin
            opcode = op; funct3 = f3; funct7 = f7; #1;
            if ({reg_write, alu_src_a, alu_src_b, mem_read, mem_write, branch, jal, jalr, illegal} !== flags ||
                wb_sel !== wb || alu_op !== aop) begin
                $display("FAIL %0s: flags=%b wb=%b alu=%b  expected flags=%b wb=%b alu=%b",
                         name, {reg_write, alu_src_a, alu_src_b, mem_read, mem_write, branch, jal, jalr, illegal},
                         wb_sel, alu_op, flags, wb, aop);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    //                      op         f3    f7       rw a b mr mw br j jr ill  wb    alu
    initial begin
        $dumpfile("control_unit.vcd");
        $dumpvars(0, control_unit_tb);
        check(7'b0110011, 3'b000, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0000, "ADD");
        check(7'b0110011, 3'b000, 7'b0100000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0001, "SUB");
        check(7'b0110011, 3'b001, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0010, "SLL");
        check(7'b0110011, 3'b010, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0011, "SLT");
        check(7'b0110011, 3'b011, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0100, "SLTU");
        check(7'b0110011, 3'b100, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0101, "XOR");
        check(7'b0110011, 3'b101, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0110, "SRL");
        check(7'b0110011, 3'b101, 7'b0100000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b0111, "SRA");
        check(7'b0110011, 3'b110, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b1000, "OR");
        check(7'b0110011, 3'b111, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b00, 4'b1001, "AND");
        check(7'b0010011, 3'b000, 7'b0100000, 9'b1_0_1_0_0_0_0_0_0, 2'b00, 4'b0000, "ADDI (bit30 is imm, not SUB)");
        check(7'b0010011, 3'b101, 7'b0100000, 9'b1_0_1_0_0_0_0_0_0, 2'b00, 4'b0111, "SRAI");
        check(7'b0010011, 3'b101, 7'b0000000, 9'b1_0_1_0_0_0_0_0_0, 2'b00, 4'b0110, "SRLI");
        check(7'b0000011, 3'b010, 7'b0000000, 9'b1_0_1_1_0_0_0_0_0, 2'b01, 4'b0000, "LW");
        check(7'b0100011, 3'b010, 7'b0000000, 9'b0_0_1_0_1_0_0_0_0, 2'b00, 4'b0000, "SW");
        check(7'b1100011, 3'b000, 7'b0000000, 9'b0_0_0_0_0_1_0_0_0, 2'b00, 4'b0000, "BEQ");
        check(7'b1101111, 3'b000, 7'b0000000, 9'b1_0_0_0_0_0_1_0_0, 2'b10, 4'b0000, "JAL");
        check(7'b1100111, 3'b000, 7'b0000000, 9'b1_0_1_0_0_0_0_1_0, 2'b10, 4'b0000, "JALR");
        check(7'b0110111, 3'b000, 7'b0000000, 9'b1_0_0_0_0_0_0_0_0, 2'b11, 4'b0000, "LUI");
        check(7'b0010111, 3'b000, 7'b0000000, 9'b1_1_1_0_0_0_0_0_0, 2'b00, 4'b0000, "AUIPC");
        check(7'b1111111, 3'b000, 7'b0000000, 9'b0_0_0_0_0_0_0_0_1, 2'b00, 4'b0000, "illegal opcode");

        if (errors == 0) $display("CONTROL UNIT: ALL TESTS PASSED");
        else             $display("CONTROL UNIT: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
