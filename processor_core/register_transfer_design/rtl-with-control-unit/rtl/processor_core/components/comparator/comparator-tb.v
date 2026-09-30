`timescale 1ns/1ps
module comparator_tb;
    reg  [31:0] a, b;
    reg  [2:0]  funct3;
    wire eq, lt, ltu, taken;
    integer errors = 0;

    comparator dut (.a(a), .b(b), .funct3(funct3), .eq(eq), .lt(lt), .ltu(ltu), .taken(taken));

    task check(input [2:0] f, input [31:0] x, y, input expected, input [63:0] name);
        begin
            funct3 = f; a = x; b = y; #10;
            if (taken !== expected) begin
                $display("FAIL %0s: a=%h b=%h taken=%b expected=%b", name, x, y, taken, expected);
                errors = errors + 1;
            end else $display("PASS %0s", name);
        end
    endtask

    initial begin
        $dumpfile("comparator.vcd");
        $dumpvars(0, comparator_tb);

        check(3'b000, 32'd5,        32'd5,       1, "BEQ eq");
        check(3'b000, 32'd5,        32'd6,       0, "BEQ ne");
        check(3'b001, 32'd5,        32'd6,       1, "BNE");
        check(3'b100, 32'hFFFFFFFF, 32'd1,       1, "BLT -1<1");
        check(3'b100, 32'd1,        32'hFFFFFFFF,0, "BLT 1<-1");
        check(3'b101, 32'd1,        32'hFFFFFFFF,1, "BGE 1>=-1");
        check(3'b110, 32'hFFFFFFFF, 32'd1,       0, "BLTU big<1");
        check(3'b110, 32'd1,        32'hFFFFFFFF,1, "BLTU 1<big");
        check(3'b111, 32'hFFFFFFFF, 32'd1,       1, "BGEU");
        check(3'b010, 32'd1,        32'd1,       0, "invalid funct3");

        if (errors == 0) $display("COMPARATOR: ALL TESTS PASSED");
        else             $display("COMPARATOR: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule