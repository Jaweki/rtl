// ============================================================
// program-counter.v : 32-bit program counter
// Purpose : holds the address of the current instruction.
//           On each clock it loads next_pc (PC+4, branch or jump target).
//           Synchronous, active-high reset.
// ============================================================
`timescale 1ns/1ps
module program_counter #(
    parameter WIDTH      = 32,
    parameter RESET_ADDR = 32'h0000_0000
)(
    input  wire             clk,
    input  wire             rst,        // synchronous reset
    input  wire             en,         // 0 = hold (used for stalls later)
    input  wire [WIDTH-1:0] next_pc,
    output reg  [WIDTH-1:0] pc,
    output wire [WIDTH-1:0] pc_plus4
);
    assign pc_plus4 = pc + 32'd4;

    always @(posedge clk) begin
        if (rst)     pc <= RESET_ADDR;
        else if (en) pc <= next_pc;
    end
endmodule