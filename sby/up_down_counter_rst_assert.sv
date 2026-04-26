// -------------------
// Formal Verification
// -------------------
`timescale 1ns / 1ps

module up_down_counter_rst_assert #(
    parameter int MAX   = 2,
    parameter int WIDTH = 2
) (
    input logic clk,
    input logic enable,
    input logic rst,     // Takes priority over enable
    input logic up,
    output logic [WIDTH-1:0] count
);

  up_down_counter_rst #(
      .MAX  (MAX),
      .WIDTH(WIDTH)
  ) u_counter (
      .clk(clk),
      .enable(enable),
      .rst(rst),
      .up(up),
      .count(count)
  );

  // verilog_lint: waive-start always-comb

  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off BLKSEQ */

  // Hide $initstate from verilator
`ifdef VERILATOR
  wire start = 0;
`else
  wire start = $initstate;
`endif

  // Ensure parameter values are sensible
  initial assert (MAX >= 0);
  initial assert ((1 << WIDTH) > MAX);

  // Ensure count remains within range at all times
  always @(*) assert (count <= MAX);

  // Check initial value
  initial a_init : assert (count == 0);

  // Check reset
  always @(posedge clk) if (!start && $past(rst)) a_reset : assert (count == 0);

  // Check hold
  always @(posedge clk)
    if (!start && $past(!enable && !rst))
      a_hold : assert (count == $past(count));

  // Check count up
  logic wrap_up;
  always @(posedge clk) begin
    wrap_up = ($past(count == MAX) && count == 0);
    if (!start && $past(up && enable && !rst))
      a_count_up : assert (count == $past(count) + 1 || wrap_up);
  end

  // Check count down
  logic wrap_down;
  always @(posedge clk) begin
    wrap_down = ($past(count == 0) && count == MAX);
    if (!start && $past(!up && enable && !rst))
      a_count_down : assert (count == $past(count) - 1 || wrap_down);
  end

endmodule

