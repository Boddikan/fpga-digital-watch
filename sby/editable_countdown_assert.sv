// -------------------
// Formal Verification
// -------------------
`timescale 1ns / 1ps

module editable_countdown_assert #(
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

  editable_countdown #(
      .MAX  (MAX),
      .WIDTH(WIDTH)
  ) u_editable_countdown (
      .clk(clk),
      .clr(clr),
      .tick(tick),
      .edit_mode(edit_mode),
      .inc(inc),
      .dec(dec),
      .count(count),
      .borrow_out(borrow_out)
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

  // Initial value
  initial a_init : assert (count == 0);

  // Clear
  always @(posedge clk) if (!start && $past(clr)) a_clear : assert (count == 0);

  wire inc_event = edit_mode && inc && !dec && !clr;
  wire dec_event = edit_mode && dec && !inc && !clr;
  wire tick_event = !edit_mode && tick && !clr;

  // Hold
  always @(posedge clk)
    if (!start && $past(!inc_event && !dec_event && !tick_event && !clr))
      a_hold : assert (count == $past(count));

  // Increment, decrement and tick
  reg p1, m1, wrap_up, wrap_down;
  always @(posedge clk) begin
    p1 = (count == $past(count) + 1);
    m1 = (count == $past(count) - 1);
    wrap_up = ($past(count == MAX) && count == 0);
    wrap_down = ($past(count == 0) && count == MAX);

    if (!start) begin
      if ($past(inc_event)) a_inc : assert (p1 || wrap_up);
      if ($past(dec_event)) a_dec : assert (m1 || wrap_down);
      if ($past(tick_event)) a_tick : assert (m1 || wrap_down);
    end
  end

  // Borrow out
  always @(*) a_borrow : assert (borrow_out == (tick_event && (count == 0)));

endmodule

