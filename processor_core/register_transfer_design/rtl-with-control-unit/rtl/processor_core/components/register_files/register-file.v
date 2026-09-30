// ============================================================
// register-file.v : 32 x 32-bit RISC-V register file
// Purpose : the CPU's fast working storage (x0..x31).
//           Two asynchronous read ports (rs1, rs2),
//           one synchronous write port (rd).
//           x0 is hard-wired to zero: reads give 0, writes are ignored.
// ============================================================
`timescale 1ns/1ps
module register_file #(
    parameter WIDTH = 32
)(
    input  wire             clk,
    input  wire             we,          // write enable (RegWrite)
    input  wire [4:0]       rs1_addr,
    input  wire [4:0]       rs2_addr,
    input  wire [4:0]       rd_addr,
    input  wire [WIDTH-1:0] rd_data,
    output wire [WIDTH-1:0] rs1_data,
    output wire [WIDTH-1:0] rs2_data
);
    reg [WIDTH-1:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) regs[i] = {WIDTH{1'b0}};
    end

    always @(posedge clk) begin
        if (we && rd_addr != 5'd0)
            regs[rd_addr] <= rd_data;
    end

    assign rs1_data = (rs1_addr == 5'd0) ? {WIDTH{1'b0}} : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? {WIDTH{1'b0}} : regs[rs2_addr];
endmodule