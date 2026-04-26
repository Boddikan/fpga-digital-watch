`timescale 1ns / 1ps

module stopwatch_counter_assert #(
    parameter int CYCLES_PER_SECOND = 200
) (
    input logic clk,
    input logic rst,
    input logic enable,
    output logic [6:0] minutes,
    output logic [5:0] seconds,
    output logic [6:0] centiseconds
);

  stopwatch_counter #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_counter (
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .minutes(minutes),
      .seconds(seconds),
      .centiseconds(centiseconds)
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
  initial assert (CYCLES_PER_SECOND >= 200);

  localparam int Max = (CYCLES_PER_SECOND / 100) - 1;

  // Ensure values stay bounded
  always @(*) assert (minutes < 100 && seconds < 60 && centiseconds < 100);

  wire [19:0] out = {minutes, seconds, centiseconds};
  wire all_zero = out == 0;

  // Check initial counter values
  initial a_init_zero : assert (all_zero);

  // Check reset behaviour
  always @(posedge clk) if (!start && $past(rst)) a_reset : assert (all_zero);

  // Check hold
  always @(posedge clk) if (!start && $past(!enable && !rst)) a_hold : assert (out == $past(out));

  reg wrap_c, inc_c, hold_c;
  reg wrap_s, inc_s, hold_s;
  reg wrap_m, inc_m, hold_m;

  // Record duration between ticks
  integer unsigned duration = 0;
  always @(*) assert (duration <= Max + 1);

  // Sequential asserts
  always @(posedge clk) begin
    wrap_c = (centiseconds == 0 && $past(centiseconds == 99 && !rst));
    inc_c  = (centiseconds == $past(centiseconds) + 1);
    hold_c = (centiseconds == $past(centiseconds));

    wrap_s = (seconds == 0 && $past(seconds == 59 && !rst));
    inc_s  = (seconds == $past(seconds) + 1);
    hold_s = (seconds == $past(seconds));

    wrap_m = (minutes == 0 && $past(minutes == 99 && !rst));
    inc_m  = (minutes == $past(minutes) + 1);
    hold_m = (minutes == $past(minutes));


    if (!start) begin
      // Simple tests for monotonicity
      if (!$past(rst)) begin
        a_non_dec_c : assert (wrap_c || inc_c || hold_c);
        a_non_dec_s : assert (wrap_s || inc_s || hold_s);
        a_non_dec_m : assert (wrap_m || inc_m || hold_m);
      end

      // Check duration of ticks
      a_max_tick : assert (duration <= Max);
      if (inc_c || wrap_c) begin
        a_min_tick : assert (duration >= Max);
        duration <= 0;
      end else if ($past(enable && !rst)) duration <= (duration > Max) ? duration : duration + 1;
      else duration <= 0;
    end
  end
endmodule
