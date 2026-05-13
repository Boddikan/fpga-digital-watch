// Module snapshot_mux that assigns q when hold is low combinatorially.
// When hold is high q is assigned d from the value
// held on last rising clock edge before hold went high.
//
// Ports:
//      clk            - Clock signal.
//      hold           - Hold signal.
//      d              - Data input.
//      q              - MUX output

`timescale 1ns / 1ps

module snapshot_mux #(
    parameter int WIDTH = 1
) (
    input logic clk,
    input logic hold,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

  logic [WIDTH-1:0] d_freeze = '0;

  always_ff @(posedge clk) begin
    if (hold == 0) d_freeze <= d;
  end

  assign q = hold ? d_freeze : d;

endmodule
