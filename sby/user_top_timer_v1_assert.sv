// -------------------
// Formal Verification
// -------------------
`timescale 1ns / 1ps

module user_top_timer_v1_assert #(
    parameter int CYCLES_PER_SECOND = 10
) (
    input logic clk,
    input logic [3:0] button,
    input logic [9:0] sw,
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds,

    output logic probe_running,
    output logic [2:0] probe_mode_enable
);

  user_top_timer_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_dut (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(led),
      .hours_disp(hours_disp),
      .minutes_disp(minutes_disp),
      .seconds_disp(seconds_disp),
      .blank_hours(blank_hours),
      .blank_minutes(blank_minutes),
      .blank_seconds(blank_seconds),
      .probe_running(probe_running),
      .probe_mode_enable(probe_mode_enable)
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
  initial assert (CYCLES_PER_SECOND >= 10);

  // Initial
  wire [20:0] out = {hours_disp, minutes_disp, seconds_disp};
  wire all_zeros = (out == 0);
  initial a_init : assert (all_zeros);
  initial a_init_no_blank : assert (!blank_hours && !blank_minutes && !blank_seconds);

  // Max counts
  always @(*) a_max_counts : assert (hours_disp < 24 && minutes_disp < 60 && seconds_disp < 60);

  // Running and edit mode are mutually exclusive, but permit one cycle's grace
  wire run_and_edit = probe_running && (probe_mode_enable != 0);
  always @(posedge clk) a_no_run_and_edit : assert (!($past(run_and_edit) && run_and_edit));
  // Edit takes priority
  always @(posedge clk)
    if (!start && $past(run_and_edit))
      a_edit_over_run : assert (probe_mode_enable != 0);

  // Edit mode is sequential
  always @(posedge clk) begin
    if (!start && $past(probe_mode_enable[0]))
      a_edit_s : assert (probe_mode_enable == 3'b001 || probe_mode_enable == 3'b010);
  end

  // Cannot run when zero
  always @(posedge clk) if ($past(all_zeros)) a_no_run_when_zero : assert (!probe_running);

  // Cannot change when zero except individual units in edit mode
  logic hour_c, min_c, sec_c;
  always @(posedge clk) begin
    hour_c = $past(hours_disp) != hours_disp;
    min_c  = $past(minutes_disp) != minutes_disp;
    sec_c  = $past(seconds_disp) != seconds_disp;
    if (!start && $past(all_zeros)) begin
      if (hour_c) a_min_sec_hold : assert (!min_c && !sec_c);
      if (min_c) a_hour_sec_hold : assert (!hour_c && !sec_c);
      if (sec_c) a_hour_min_hold : assert (!hour_c && !min_c);
      // Check in edit mode
      if (hour_c) a_hour_edit : assert ($past(probe_mode_enable == 3'b100));
      if (min_c) a_min_edit : assert ($past(probe_mode_enable == 3'b010));
      if (sec_c) a_sec_edit : assert ($past(probe_mode_enable == 3'b001));
    end
  end

  // When not editing, can only decrement or hold
  integer t = ((hours_disp * 60) + minutes_disp) * 60 + seconds_disp;
  always @(posedge clk)
    if (!start && $past(probe_mode_enable == 0))
      a_time_change : assert ($past(t) == t || $past(t) == t + 1);

  // When not editing or running, can only hold
  always @(posedge clk)
    if (!start && $past(t) != t)
      a_cause_of_change : assert ($past(probe_running || (probe_mode_enable != 0)));

endmodule
