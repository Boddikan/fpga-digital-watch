// Counter module that increments up or down from 0 to MAX.
//
// Parameters:
//      MAX              Maximum count value.
//      WIDTH            Number of bits required for output count.
//
// Ports:
//      clk            - Clock signal.
//      enable         - Assign next value to flip-flop on positive clock edge when high.
//                     - Hold current value next postive clock edge when low.
//      up             - Increment count when high.
//                     - Decrement count when low.
//      count          - Outputs value from 0 to MAX;

`timescale 1ns / 1ps

module up_down_counter #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic enable,
    input logic up,
    output logic [WIDTH-1:0] count = WIDTH'(0)
);

  localparam logic [WIDTH-1:0] Max = WIDTH'(MAX);

  logic [WIDTH-1:0] next_count;

  always_ff @(posedge clk) if (enable) count <= next_count;

  always_comb begin
    if (up) begin
      if (count == Max) begin
        next_count = '0;
      end else begin
        next_count = count + 1;
      end
    end else begin
      if (count == 0) begin
        next_count = Max;
      end else begin
        next_count = count - 1;
      end
    end
  end

endmodule

