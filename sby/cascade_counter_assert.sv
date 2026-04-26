`timescale 1ns / 1ps

module cascade_counter_assert #(
    parameter int N2 = 3,
    parameter int N1 = 4,
    parameter int N0 = 5,

    parameter int W2 = 2,
    parameter int W1 = 2,
    parameter int W0 = 3
) (
    input logic clk,
    input logic rst,  // Takes priority over enable
    input logic enable,
    output logic [W2-1:0] count2,
    output logic [W1-1:0] count1,
    output logic [W0-1:0] count0
);

  cascade_counter #(
      .N2(N2),
      .N1(N1),
      .N0(N0),
      .W2(W2),
      .W1(W1),
      .W0(W0)
  ) u_counter (
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .count2(count2),
      .count1(count1),
      .count0(count0)
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
  initial assert (N0 >= 1 && N1 >= 1 && N2 >= 1);
  initial assert ((1 << W0) > N0 - 1 && (1 << W1) > N1 - 1 && (1 << W2) > N2 - 1);

  // Ensure count remains within range at all times
  always @(*) assert (count0 < N0 && count1 < N1 && count2 < N2);

  // Check initial value and reset value
  wire [W2+W1+W0-1:0] out = {count2, count1, count0};
  wire all_zero = (out == 0);
  initial a_init : assert (all_zero);
  always @(posedge clk) if (!start && $past(rst)) a_reset : assert (all_zero);

  // Check hold
  always @(posedge clk) if (!start && $past(!enable && !rst)) a_hold : assert (out == $past(out));

  // Check counters count
  logic wrap0, wrap1, wrap2;
  always @(posedge clk) begin
    wrap0 = ($past(count0) == N0 - 1 && count0 == 0);
    wrap1 = ($past(count1) == N1 - 1 && count1 == 0);
    wrap2 = ($past(count2) == N2 - 1 && count2 == 0);

    if (!start && $past(enable && !rst)) begin
      a_count0 : assert (count0 == $past(count0) + 1 || wrap0);
      a_count1_hold : assert (wrap0 || count1 == $past(count1));
      if (wrap0) a_count1_inc : assert (count1 == $past(count1) + 1 || wrap1);
      a_count2_hold : assert (wrap1 || count2 == $past(count2));
      if (wrap1) a_count2_inc : assert (count2 == $past(count2) + 1 || wrap2);
    end
  end

endmodule
