// ============================================================
// control-unit.v : RV32I control unit (single-cycle)
// Purpose : looks at the instruction fields and produces every
//           control signal the datapath needs for that instruction.
//           Purely combinational: the same cycle the instruction is
//           fetched, the control signals are ready.
//
// Inputs  : opcode = instr[6:0]
//           funct3 = instr[14:12]
//           funct7 = instr[31:25]
//
// Think of it as a lookup table:  instruction type -> control word
//
//  instr   | reg_write | alu_src_a | alu_src_b | mem_r | mem_w | wb_sel | branch | jal | jalr
//  --------+-----------+-----------+-----------+-------+-------+--------+--------+-----+-----
//  R-type  |     1     |   rs1     |   rs2     |   0   |   0   |  ALU   |   0    |  0  |  0
//  OP-IMM  |     1     |   rs1     |   imm     |   0   |   0   |  ALU   |   0    |  0  |  0
//  LOAD    |     1     |   rs1     |   imm     |   1   |   0   |  MEM   |   0    |  0  |  0
//  STORE   |     0     |   rs1     |   imm     |   0   |   1   |   -    |   0    |  0  |  0
//  BRANCH  |     0     |    -      |    -      |   0   |   0   |   -    |   1    |  0  |  0
//  JAL     |     1     |    -      |    -      |   0   |   0   | PC+4   |   0    |  1  |  0
//  JALR    |     1     |   rs1     |   imm     |   0   |   0   | PC+4   |   0    |  0  |  1
//  LUI     |     1     |    -      |    -      |   0   |   0   |  IMM   |   0    |  0  |  0
//  AUIPC   |     1     |   PC      |   imm     |   0   |   0   |  ALU   |   0    |  0  |  0
// ============================================================
`timescale 1ns/1ps
module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        reg_write,   // write rd in the register file
    output reg        alu_src_a,   // 0 = rs1, 1 = PC (AUIPC)
    output reg        alu_src_b,   // 0 = rs2, 1 = immediate
    output reg  [3:0] alu_op,      // operation code for alu.v
    output reg        mem_read,    // data memory read  (loads)
    output reg        mem_write,   // data memory write (stores)
    output reg  [1:0] wb_sel,      // write-back source (see WB_* below)
    output reg        branch,      // instruction is a conditional branch
    output reg        jal,         // instruction is JAL
    output reg        jalr,        // instruction is JALR
    output reg        illegal      // opcode not part of RV32I
);

    // ---------- opcodes ----------
    localparam OP_R      = 7'b0110011;
    localparam OP_IMM    = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;

    // ---------- write-back select ----------
    localparam WB_ALU = 2'b00;
    localparam WB_MEM = 2'b01;
    localparam WB_PC4 = 2'b10;
    localparam WB_IMM = 2'b11;

    // ---------- ALU codes (must match alu.v) ----------
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_SLL  = 4'b0010;
    localparam ALU_SLT  = 4'b0011;
    localparam ALU_SLTU = 4'b0100;
    localparam ALU_XOR  = 4'b0101;
    localparam ALU_SRL  = 4'b0110;
    localparam ALU_SRA  = 4'b0111;
    localparam ALU_OR   = 4'b1000;
    localparam ALU_AND  = 4'b1001;

    // funct7[5] (instr bit 30) separates ADD/SUB and SRL/SRA
    wire f7_5     = funct7[5];
    // For funct3=000, bit 30 means SUB only in R-type
    // (in ADDI, bit 30 is just part of the immediate).
    wire is_rtype = (opcode == OP_R);

    // ---------- ALU decoder for R-type and OP-IMM ----------
    reg [3:0] alu_fn;
    always @(*) begin
        case (funct3)
            3'b000 : alu_fn = (is_rtype && f7_5) ? ALU_SUB : ALU_ADD;
            3'b001 : alu_fn = ALU_SLL;
            3'b010 : alu_fn = ALU_SLT;
            3'b011 : alu_fn = ALU_SLTU;
            3'b100 : alu_fn = ALU_XOR;
            3'b101 : alu_fn = f7_5 ? ALU_SRA : ALU_SRL;
            3'b110 : alu_fn = ALU_OR;
            3'b111 : alu_fn = ALU_AND;
            default: alu_fn = ALU_ADD;
        endcase
    end

    // ---------- main decoder ----------
    always @(*) begin
        // safe defaults: do nothing, write nothing
        reg_write = 1'b0;
        alu_src_a = 1'b0;
        alu_src_b = 1'b0;
        alu_op    = ALU_ADD;
        mem_read  = 1'b0;
        mem_write = 1'b0;
        wb_sel    = WB_ALU;
        branch    = 1'b0;
        jal       = 1'b0;
        jalr      = 1'b0;
        illegal   = 1'b0;

        case (opcode)
            OP_R: begin
                reg_write = 1'b1;
                alu_op    = alu_fn;
            end
            OP_IMM: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                alu_op    = alu_fn;
            end
            OP_LOAD: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;       // address = rs1 + imm
                mem_read  = 1'b1;
                wb_sel    = WB_MEM;
            end
            OP_STORE: begin
                alu_src_b = 1'b1;       // address = rs1 + imm
                mem_write = 1'b1;
            end
            OP_BRANCH: begin
                branch    = 1'b1;       // comparator decides, datapath adds PC+imm
            end
            OP_JAL: begin
                reg_write = 1'b1;
                jal       = 1'b1;
                wb_sel    = WB_PC4;     // rd = return address
            end
            OP_JALR: begin
                reg_write = 1'b1;
                jalr      = 1'b1;
                alu_src_b = 1'b1;       // target = rs1 + imm
                wb_sel    = WB_PC4;
            end
            OP_LUI: begin
                reg_write = 1'b1;
                wb_sel    = WB_IMM;     // rd = imm (already imm<<12)
            end
            OP_AUIPC: begin
                reg_write = 1'b1;
                alu_src_a = 1'b1;       // PC
                alu_src_b = 1'b1;       // + imm
            end
            default: illegal = 1'b1;
        endcase
    end
endmodule
