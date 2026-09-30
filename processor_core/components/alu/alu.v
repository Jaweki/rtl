// ============================================================
// alu.v : 32-bit Arithmetic Logic Unit for RV32I
// Purpose : performs every arithmetic / logic / shift / compare
//           operation the core needs. Purely combinational.
// ============================================================
`timescale 1ns/1ps
module alu #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a,        // operand A (rs1 or PC)
    input  wire [WIDTH-1:0] b,        // operand B (rs2 or immediate)
    input  wire [3:0]       alu_op,   // operation select (see below)
    output reg  [WIDTH-1:0] result,
    output wire             zero      // 1 when result == 0
);
    // ALU operation codes (shared with the control unit)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;   // signed   less-than
    localparam ALU_SLTU = 4'b0100;   // unsigned less-than
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;   // logical    shift right
    localparam ALU_SRA  = 4'b0111;   // arithmetic shift right
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    wire [4:0] shamt = b[4:0];       // RV32I shifts use only the low 5 bits

    always @(*) begin
        case (alu_op)
            ALU_ADD : result = a + b;
            ALU_SUB : result = a - b;
            ALU_SLL : result = a << shamt;
            ALU_SLT : result = ($signed(a) < $signed(b)) ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}};
            ALU_SLTU: result = (a < b)                   ? {{(WIDTH-1){1'b0}},1'b1} : {WIDTH{1'b0}};
            ALU_XOR : result = a ^ b;
            ALU_SRL : result = a >> shamt;
            ALU_SRA : result = $signed(a) >>> shamt;
            ALU_OR  : result = a | b;
            ALU_AND : result = a & b;
            default : result = {WIDTH{1'b0}};
        endcase
    end

    assign zero = (result == {WIDTH{1'b0}});
endmodule