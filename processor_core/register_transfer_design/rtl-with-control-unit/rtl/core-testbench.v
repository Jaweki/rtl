// ============================================================
// core-testbench.v : self-checking testbench for the whole core
// Runs processor_core/tests/prog_all.hex, then compares all 32
// registers with expected_all.hex (produced by the independent
// Python reference model in tests/asm.py).
// Run from the repo root:  make core
// ============================================================
`timescale 1ns/1ps
module core_testbench;
    reg clk = 0;
    reg rst = 1;
    wire [31:0] pc;
    wire        illegal;
    integer errors = 0;
    integer i;
    reg [31:0] expected [0:31];

    riscv_core #(
        .INIT_FILE("processor_core/tests/prog_all.hex")
    ) dut (.clk(clk), .rst(rst), .pc_out(pc), .illegal(illegal));

    always #5 clk = ~clk;                       // 100 MHz

    // flag any unsupported opcode that reaches the decoder after reset
    always @(posedge clk)
        if (!rst && illegal) begin
            $display("FAIL illegal instruction at pc=%h", pc);
            errors = errors + 1;
        end

    initial begin
        $dumpfile("core.vcd");
        $dumpvars(0, core_testbench);
        $readmemh("processor_core/tests/expected_all.hex", expected);

        repeat (2) @(posedge clk);
        rst = 0;
        repeat (400) @(posedge clk);            // program ends in a spin loop
        #1;

        for (i = 0; i < 32; i = i + 1) begin
            if (dut.rf.regs[i] !== expected[i]) begin
                $display("FAIL x%0d = %h, expected %h", i, dut.rf.regs[i], expected[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("CORE: ALL TESTS PASSED (32/32 registers match reference model)");
        else             $display("CORE: %0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
