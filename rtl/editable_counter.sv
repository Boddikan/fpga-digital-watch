// Editable Counter wraps an up/down counter with two mode of operation.
// Normal mode count increments on tick.
// In edit mode count increments up when inc is asserted and down when dec is asserted.
//
// Ports:
//      clk            - Clock signal.
//      tick           - Tick that increments when edit mode is low.
//      edit_mode      - Determines if we are in edit mode.
//      inc            - Determines if we inc during edit mode.
//      dec            - Determines if we dec during edit mode.
//      count          - Register that hold count.

`timescale 1ns / 1ps

module editable_counter #(
    parameter int N = 60,
    parameter int WIDTH = 6
) (
    input logic clk,
    input logic tick,  // Count increments tick when edit_mode is low
    input logic edit_mode,
    input logic inc,  // Count increments by one when edit_mode is high
    input logic dec,  // Count decrements by one when edit_mode is high
    output logic [WIDTH-1:0] count
);

  logic enable;
  logic up;

  up_down_counter #(
      .MAX  (N - 1),
      .WIDTH(WIDTH)
  ) u_counter (
      .clk(clk),
      .enable(enable),
      .up(up),
      .count(count)
  );

  wire inc_event = edit_mode && inc && !dec;
  wire dec_event = edit_mode && dec && !inc;
  wire tick_event = !edit_mode && tick;

  assign up = tick_event || inc_event;
  assign enable = tick_event || inc_event || dec_event;

endmodule

