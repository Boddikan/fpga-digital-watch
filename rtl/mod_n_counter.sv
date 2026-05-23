// Modulo N counter module that increments by 1 and wraps when N - 1 is reached.
// Has a synchronous enable and reset pin.
//
// Ports:
//      clk            - Clock signal.
//      rst            - Resets counter to 0.
//      enable         - Assign next value to flip-flop on positive clock edge when high.
//                     - Hold current value next postive clock edge when low.
//      hours          - Outputs count up to N - 1 then wraps to 0.

`timescale 1ns / 1ps

module mod_n_counter #(
    parameter int N = 4,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [WIDTH-1:0] count = 0
);
  localparam logic [WIDTH-1:0] MaxCount = WIDTH'(N - 1);

  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk) begin
    if (rst) count <= '0;
    else if (enable) count <= next_count;
  end

  assign next_count = (count < MaxCount) ? count + 1'b1 : '0;

endmodule
