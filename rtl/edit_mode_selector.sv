// Edit Mode Selector enters mode select after button is held for long_press.
// Then allows as to toggle between modes with press.
// Once last mode is passed must be held for long_press to eneter mode select again.
//
// Ports:
//      clk            - Clock signal.
//      button         - Input for button press.
//      mode_enable    - Outputs mode for Digital Watch

`timescale 1ns / 1ps

module edit_mode_selector #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input logic clk,
    input logic button,
    output logic [2:0] mode_enable
);

  logic long_press;

  button_hold_pulse #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_hold_pulse (
      .clk(clk),
      .button(button),
      .pulse(long_press)
  );

  logic press;

  rising_edge_detector u_detect (
      .clk(clk),
      .sig_in(button),
      .rise(press)
  );

  logic armed;
  logic disarm;

  arming_latch u_latch (
      .clk(clk),
      .arm(long_press),
      .disarm(disarm),
      .armed(armed)
  );

  logic reset_counter;
  logic enable_counter;
  logic [1:0] count;

  mod_n_counter #(
      .N(3),
      .WIDTH(2)
  ) u_mod_3_counter (
      .clk(clk),
      .rst(reset_counter),
      .enable(enable_counter),
      .count(count)
  );

  // Counter runs only when armed
  // Resets when disarmed
  assign enable_counter = press && armed;
  assign reset_counter = disarm;

  // Disarm on the press that steps past the last mode
  assign disarm = press && armed && (count == 2);

  // Output logic
  assign mode_enable = armed ? (3'b001 << count) : 3'b000;


endmodule
