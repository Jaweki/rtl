// ============================================================
// comparator.v : branch comparator for RV32I
// Purpose : compares rs1 and rs2 and decides whether a branch
//           instruction (beq/bne/blt/bge/bltu/bgeu) is taken.
// ============================================================
`timescale 1ns/1ps
module comparator #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [2:0]       funct3,     // branch type from the instruction
    output wire             eq,         // a == b
    output wire             lt,         // a <  b (signed)
    output wire             ltu,        // a <  b (unsigned)
    output reg              taken       // branch condition satisfied
);
    assign eq  = (a == b);
    assign lt  = ($signed(a) < $signed(b));
    assign ltu = (a < b);

    always @(*) begin
        case (funct3)
            3'b000 : taken = eq;        // BEQ
            3'b001 : taken = ~eq;       // BNE
            3'b100 : taken = lt;        // BLT
            3'b101 : taken = ~lt;       // BGE
            3'b110 : taken = ltu;       // BLTU
            3'b111 : taken = ~ltu;      // BGEU
            default: taken = 1'b0;
        endcase
    end
endmodule