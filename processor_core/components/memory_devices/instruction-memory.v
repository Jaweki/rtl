// ============================================================
// instruction-memory.v : read-only instruction memory (ROM)
// Purpose : stores the program. The CPU gives it the PC and gets
//           back the 32-bit instruction in the same cycle.
//           Program is loaded from a hex file (one 32-bit word
//           per line) with $readmemh.
// ============================================================
`timescale 1ns/1ps
module instruction_memory #(
    parameter DEPTH_WORDS = 1024,          // 4 KiB by default
    parameter INIT_FILE   = ""             // e.g. "program.hex"
)(
    input  wire [31:0] addr,               // byte address (PC)
    output wire [31:0] instr
);
    reg [31:0] mem [0:DEPTH_WORDS-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH_WORDS; i = i + 1) mem[i] = 32'h0000_0013; // NOP (addi x0,x0,0)
        if (INIT_FILE != "") $readmemh(INIT_FILE, mem);
    end

    // word aligned read: drop the two low address bits
    assign instr = mem[addr[31:2] % DEPTH_WORDS];
endmodule
