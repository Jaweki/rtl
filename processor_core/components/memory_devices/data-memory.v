// ============================================================
// data-memory.v : byte-addressable data RAM (little endian)
// Purpose : holds program data. Supports the RV32I load/store
//           widths, selected by funct3:
//             store: 000 SB, 001 SH, 010 SW
//             load : 000 LB, 001 LH, 010 LW, 100 LBU, 101 LHU
//           Write is synchronous; read is combinational.
//           Addresses are expected to be naturally aligned.
// ============================================================
`timescale 1ns/1ps
module data_memory #(
    parameter SIZE_BYTES = 4096
)(
    input  wire        clk,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);
    reg [7:0] mem [0:SIZE_BYTES-1];
    integer i;

    initial begin
        for (i = 0; i < SIZE_BYTES; i = i + 1) mem[i] = 8'h00;
    end

    wire [31:0] a = addr % SIZE_BYTES;

    // ---------- write ----------
    always @(posedge clk) begin
        if (mem_write) begin
            mem[a] <= wdata[7:0];
            if (funct3[1:0] != 2'b00) mem[a+1] <= wdata[15:8];   // SH, SW
            if (funct3[1:0] == 2'b10) begin                      // SW
                mem[a+2] <= wdata[23:16];
                mem[a+3] <= wdata[31:24];
            end
        end
    end

    // ---------- read ----------
    always @(*) begin
        rdata = 32'b0;
        if (mem_read) begin
            case (funct3)
                3'b000: rdata = {{24{mem[a][7]}}, mem[a]};                                  // LB
                3'b001: rdata = {{16{mem[a+1][7]}}, mem[a+1], mem[a]};                      // LH
                3'b010: rdata = {mem[a+3], mem[a+2], mem[a+1], mem[a]};                     // LW
                3'b100: rdata = {24'b0, mem[a]};                                            // LBU
                3'b101: rdata = {16'b0, mem[a+1], mem[a]};                                  // LHU
                default: rdata = 32'b0;
            endcase
        end
    end
endmodule