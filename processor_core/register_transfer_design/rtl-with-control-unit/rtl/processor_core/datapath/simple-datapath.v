// ============================================================
// simple-datapath.v : RV32I single-cycle core (top level)
// Purpose : wires the datapath components together and lets the
//           control unit steer them. One instruction per clock.
//
//   PC -> instruction_memory -> instr
//   instr -> control_unit          (what to do)
//   instr -> register_file         (read rs1, rs2)
//   instr -> immediate_generator   (imm)
//   rs1/PC , rs2/imm -> alu        (compute / address)
//   rs1, rs2 -> comparator         (branch taken?)
//   alu result -> data_memory      (load / store)
//   alu / mem / PC+4 / imm -> write-back mux -> register_file
//   PC+4 / PC+imm / jalr target -> next_pc mux -> PC
//
// Compile order (see Makefile): all components, control-unit.v,
// then this file.
// ============================================================
`timescale 1ns/1ps
module riscv_core #(
    parameter IMEM_WORDS = 1024,
    parameter DMEM_BYTES = 4096,
    parameter INIT_FILE  = ""
)(
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc_out,      // for debug / waveform
    output wire        illegal      // high when an unsupported opcode is fetched
);

    // ---------------- fetch ----------------
    wire [31:0] pc, pc_plus4, next_pc, instr;

    program_counter pc_reg (
        .clk(clk), .rst(rst), .en(1'b1),
        .next_pc(next_pc), .pc(pc), .pc_plus4(pc_plus4)
    );

    instruction_memory #(.DEPTH_WORDS(IMEM_WORDS), .INIT_FILE(INIT_FILE)) imem (
        .addr(pc), .instr(instr)
    );

    assign pc_out = pc;

    // ---------------- decode ----------------
    wire [6:0] opcode = instr[6:0];
    wire [4:0] rd     = instr[11:7];
    wire [2:0] funct3 = instr[14:12];
    wire [4:0] rs1    = instr[19:15];
    wire [4:0] rs2    = instr[24:20];
    wire [6:0] funct7 = instr[31:25];

    wire        reg_write, alu_src_a, alu_src_b, mem_read, mem_write;
    wire        branch, jal, jalr;
    wire [3:0]  alu_op;
    wire [1:0]  wb_sel;

    control_unit cu (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .alu_op(alu_op), .mem_read(mem_read), .mem_write(mem_write),
        .wb_sel(wb_sel), .branch(branch), .jal(jal), .jalr(jalr),
        .illegal(illegal)
    );

    wire [31:0] imm;
    immediate_generator immgen (.instr(instr), .imm(imm));

    wire [31:0] rs1_data, rs2_data, wb_data;
    register_file rf (
        .clk(clk), .we(reg_write),
        .rs1_addr(rs1), .rs2_addr(rs2), .rd_addr(rd),
        .rd_data(wb_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    // ---------------- execute ----------------
    wire [31:0] alu_a = alu_src_a ? pc  : rs1_data;
    wire [31:0] alu_b = alu_src_b ? imm : rs2_data;
    wire [31:0] alu_result;
    wire        alu_zero;

    alu alu0 (.a(alu_a), .b(alu_b), .alu_op(alu_op),
              .result(alu_result), .zero(alu_zero));

    wire cmp_eq, cmp_lt, cmp_ltu, branch_cond;
    comparator cmp0 (.a(rs1_data), .b(rs2_data), .funct3(funct3),
                     .eq(cmp_eq), .lt(cmp_lt), .ltu(cmp_ltu),
                     .taken(branch_cond));

    // ---------------- memory ----------------
    wire [31:0] mem_rdata;
    data_memory #(.SIZE_BYTES(DMEM_BYTES)) dmem (
        .clk(clk), .mem_write(mem_write), .mem_read(mem_read),
        .funct3(funct3), .addr(alu_result), .wdata(rs2_data),
        .rdata(mem_rdata)
    );

    // ---------------- write-back ----------------
    assign wb_data = (wb_sel == 2'b00) ? alu_result :
                     (wb_sel == 2'b01) ? mem_rdata  :
                     (wb_sel == 2'b10) ? pc_plus4   :
                                         imm;

    // ---------------- next PC ----------------
    wire [31:0] pc_target   = pc + imm;                   // branch / JAL target
    wire [31:0] jalr_target = {alu_result[31:1], 1'b0};   // (rs1+imm) with bit0 cleared
    wire        take_pc_imm = jal | (branch & branch_cond);

    assign next_pc = jalr        ? jalr_target :
                     take_pc_imm ? pc_target   :
                                   pc_plus4;
endmodule
