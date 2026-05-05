// Button Auto Repeat module produces one cycle pulse when button is pressed
// and produces a pulse train after button has been held after a set amount of time.
//
// Ports:
//      clk            - Clock signal.
//      button         - Input for button press.
//      pulse          - Outputs high after initial button press.
//                     - Produces pulse train after held for HOLD_CYCLES - REPEAT_CYCLES + 1.

`timescale 1ns / 1ps

module button_auto_repeat #(
    parameter int HOLD_CYCLES   = 50_000_000,
    // REPEAT_CYCLES must be smaller than HOLD_CYCLES
    parameter int REPEAT_CYCLES = 5_000_000
) (
    input  logic clk,
    input  logic button,
    output logic pulse
);

  logic rise;
  logic held;
  logic pulse_train;

  assign pulse = rise | (button & pulse_train);

  rising_edge_detector u_detector (
      .clk(clk),
      .sig_in(button),
      .rise(rise)
  );

  button_hold_detect #(
      .HOLD_CYCLES(HOLD_CYCLES - REPEAT_CYCLES + 1)
  ) u_detect (
      .clk(clk),
      .button(button),
      .held(held)
  );

  restartable_rate_generator #(
      .CYCLE_COUNT(REPEAT_CYCLES)
  ) u_restartable_rate_generator (
      .clk (clk),
      .run (held),
      .tick(pulse_train)
  );

endmodule
