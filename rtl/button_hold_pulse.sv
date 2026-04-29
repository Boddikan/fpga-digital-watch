// Button Hold Pulse outputs a one clock cycle pulse after button is held.
//
// Ports:
//      clk            - Clock signal.
//      button         - Input for button press.
//      Pulse          - Outputs one clock cycle pulse.

`timescale 1ns / 1ps

module button_hold_pulse #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input clk,
    input logic button,
    output logic pulse
);

  logic held;

  button_hold_detect #(
      .HOLD_CYCLES(HOLD_CYCLES)
  ) u_detect (
      .clk(clk),
      .button(button),
      .held(held)
  );

  rising_edge_detector u_detector (
      .clk(clk),
      .sig_in(held),
      .rise(pulse)
  );

endmodule
