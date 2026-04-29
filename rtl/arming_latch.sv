// Arming Latch module sets armed low if disarm high and armed high if arm is high and disarm is low.
//
// Ports:
//      clk            - Clock signal.
//      arm            - Sets armed high if disarm low
//      pulse          - Outputs high after initial button press.
//                     - Produces pulse train after held for HOLD_CYCLES - REPEAT_CYCLES + 1.

`timescale 1ns / 1ps

module arming_latch (
    input  logic clk,
    input  logic arm,
    input  logic disarm,
    output logic armed = 1'b0
);

  always_ff @(posedge clk) begin
    if (disarm == 1'b1) armed <= 1'b0;
    if (arm == 1'd1 && disarm != 1'd1) armed <= 1'b1;
  end

endmodule
