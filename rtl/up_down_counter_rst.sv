// Counter module that increments up or down from 0 to MAX. Resets to 0 when rst is asserted.
//
// Parameters:
//      MAX              Maximum count value.
//      WIDTH            Number of bits required for output count.
//
// Ports:
//      clk            - Clock signal.
//      rst            - Reset signal which restarts count.
//      enable         - Assign next value to flip-flop on positive clock edge when high.
//                     - Hold current value next postive clock edge when low.
//      up             - Increment count when high.
//                     - Decrement count when low.
//      count          - Outputs value from 0 to MAX;

`timescale 1ns / 1ps

module up_down_counter_rst #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic rst,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count = '0
);

  localparam logic [WIDTH-1:0] Max = WIDTH'(MAX);

  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk) count <= next_count;

  always_comb begin
    next_count = count;
    if (rst) begin
      next_count = '0;
    end else if (enable) begin
      if (up) begin
        if (count == Max) next_count = '0;
        else next_count = count + 1'b1;
      end else begin
        if (count == '0) next_count = Max;
        else next_count = count - 1'b1;
      end
    end
  end

endmodule
