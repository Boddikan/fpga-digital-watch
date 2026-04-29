// Rising Edge Detector modelled using a Mealy FSM.
// Outputs high for a single clock cycle when detects a rising edge from sig_in.
//
// Ports:
//      clk            - Clock signal.
//      sig_in         - Signal we wish to detect rising edge (e.g. button press).
//      rise           - Outputs high for single clock cycle once rising edge detected.

`timescale 1ns / 1ps

module rising_edge_detector (
    input  logic clk,
    input  logic sig_in,
    output logic rise
);

  logic state;
  initial state = 1'd0;

  always_ff @(posedge clk) begin
    state <= sig_in;
  end

  assign rise = (!state && sig_in);

endmodule
