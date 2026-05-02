// Key Synchroniser inverts active-low asynhronous FPGA buttons
//and synchronises them to out clock.
//
// Ports:
//      clk            - Clock signal.
//      key_n          - Asynchronous active-low key input.
//      key_sync       - Synchronised active-high key output.

`timescale 1ns / 1ps

module key_synchroniser (
    input logic clk,
    input logic [3:0] key_n,  // active-low, asynchronous
    output logic [3:0] key_sync = 4'b0000  // active-high, synchronised
);

  wire  [3:0] invert_key = ~key_n;
  logic [3:0] sync = 4'b0000;


  always_ff @(posedge clk) begin
    sync <= invert_key;
    key_sync <= sync;
  end

endmodule
