`timescale 1ns/1ps
module data_memory_tb;
    reg         clk = 0, mem_write = 0, mem_read = 0;
    reg  [2:0]  funct3 = 0;
    reg  [31:0] addr = 0, wdata = 0;
    wire [31:0] rdata;
    integer errors = 0;

    data_memory #(.SIZE_BYTES(256)) dut (.clk(clk), .mem_write(mem_write), .mem_read(mem_read),
        .funct3(funct3), .addr(addr), .wdata(wdata), .rdata(rdata));
    always #5 clk = ~clk;

    task store(input [2:0] f, input [31:0] a, input [31:0] d);
        begin
            funct3 = f; addr = a; wdata = d; mem_write = 1; mem_read = 0;
            @(posedge clk); #1; mem_write = 0;
        end
    endtask

    task load_check(input [2:0] f, input [31:0] a, input [31:0] expected, input [127:0] name);
        begin
            funct3 = f; addr = a; mem_read = 1; #1;
            if (rdata !== expected) begin
                $display("FAIL %0s: got %h expected %h", name, rdata, expected);
                errors = errors + 1;
            end else $display("PASS %0s", name);
            mem_read = 0;
        end
    endtask

    initial begin
        $dumpfile("data_memory.vcd");
        $dumpvars(0, data_memory_tb);

        store(3'b010, 32'h10, 32'hA1B2C3D4);                 // SW
        load_check(3'b010, 32'h10, 32'hA1B2C3D4, "LW");
        load_check(3'b000, 32'h10, 32'hFFFFFFD4, "LB sign-extend (little endian)");
        load_check(3'b100, 32'h10, 32'h000000D4, "LBU zero-extend");
        load_check(3'b001, 32'h10, 32'hFFFFC3D4, "LH sign-extend");
        load_check(3'b101, 32'h10, 32'h0000C3D4, "LHU zero-extend");
        load_check(3'b000, 32'h13, 32'hFFFFFFA1, "LB top byte");

        store(3'b000, 32'h20, 32'h0000007F);                 // SB
        load_check(3'b010, 32'h20, 32'h0000007F, "SB writes one byte only");
        store(3'b001, 32'h24, 32'h0000BEEF);                 // SH
        load_check(3'b010, 32'h24, 32'h0000BEEF, "SH writes two bytes only");

        // read disabled gives zero
        mem_read = 0; addr = 32'h10; #1;
        if (rdata !== 32'b0) begin $display("FAIL read disabled"); errors = errors + 1; end
        else $display("PASS read disabled returns 0");

        if (errors == 0) $display("DATA MEMORY: ALL TESTS PASSED");
        else             $display("DATA MEMORY: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule