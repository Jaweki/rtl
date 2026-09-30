// ============================================================
// register.v : generic parameterised register (default 32 bit)
// Purpose : basic storage element with synchronous reset and
//           write enable. Reused later for pipeline registers.
// ============================================================
`timescale 1ns/1ps
module register #(
    parameter WIDTH = 32,
    parameter RESET_VALUE = 0
)(
    input  wire             clk,
    input  wire             rst,     // synchronous, active high
    input  wire             en,      // load enable
    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);
    always @(posedge clk) begin
        if (rst)     q <= RESET_VALUE;
        else if (en) q <= d;
    end
endmodule