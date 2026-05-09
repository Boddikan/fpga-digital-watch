// Cascade Counter module that contains three mod n counters.
// First counter increments by 1 and wraps when N0-1 is reached.
// This triggers increments for next counter that wraps when N1-1 is reached.
// This triggers increments for next counter that wraps when N2-1 is reached.
//
// Ports:
//      clk            - Clock signal.
//      rst            - Resets counter to 0.
//      enable         - Assign next value to flip-flop on positive clock edge when high.
//                     - Hold current value next postive clock edge when low.
//      count2         - Outputs count for counter 2
//      count1         - Outputs count for counter 1
//      count0         - Outputs count for counter 0

`timescale 1ns / 1ps

module cascade_counter #(
    parameter int N2 = 3,
    parameter int N1 = 4,
    parameter int N0 = 5,

    parameter int W2 = 2,
    parameter int W1 = 2,
    parameter int W0 = 3
) (
    input logic clk,
    input logic rst,
    input logic enable,

    output logic [W2-1:0] count2,
    output logic [W1-1:0] count1,
    output logic [W0-1:0] count0
);

  logic enable1;
  logic enable2;

  assign enable1 = enable && (count0 == W0'(N0 - 1));
  assign enable2 = enable1 && (count1 == W1'(N1 - 1));

  mod_n_counter #(
      .N(N0),
      .WIDTH(W0)
  ) u_count0 (
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .count(count0)
  );

  mod_n_counter #(
      .N(N1),
      .WIDTH(W1)
  ) u_count1 (
      .clk(clk),
      .rst(rst),
      .enable(enable1),
      .count(count1)
  );

  mod_n_counter #(
      .N(N2),
      .WIDTH(W2)
  ) u_count2 (
      .clk(clk),
      .rst(rst),
      .enable(enable2),
      .count(count2)
  );

endmodule
