// Editable Countdown wraps counter from 0 to MAX.
// In edit mode count increments up when inc is asserted and down when dec is asserted.
// Outputs pulse for borrow_out wrapping.
//
// Ports:
//      clk            - Clock signal.
//      tick           - Tick that increments when edit mode is low.
//      edit_mode      - Determines if we are in edit mode.
//      inc            - Determines if we inc during edit mode.
//      dec            - Determines if we dec during edit mode.
//      count          - Register that hold count.

`timescale 1ns / 1ps

module editable_countdown #(
    parameter int MAX   = 59,
    parameter int WIDTH = 6
) (
    input logic clk,
    input logic clr,
    input logic tick,
    input logic edit_mode,
    input logic inc,
    input logic dec,
    output logic [WIDTH-1:0] count,
    output logic borrow_out
);

  logic enable;
  logic up;

  up_down_counter_rst #(
      .MAX  (MAX),
      .WIDTH(WIDTH)
  ) u_counter (
      .clk(clk),
      .rst(clr),
      .enable(enable),
      .up(up),
      .count(count)
  );

  wire inc_event = edit_mode && inc && !dec;
  wire dec_event = edit_mode && dec && !inc;
  wire tick_event = !edit_mode && tick && !clr;

  assign up = inc_event;
  assign enable = tick_event || inc_event || dec_event;

  assign borrow_out = tick_event && (count == 0);

endmodule
