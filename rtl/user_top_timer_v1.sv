// ------------------------------------------------------------------
// WARNING: This file is used by the automated test suite. Do not
// modify it.
//
// This file also serves as a template for your own designs. To use
// it:
//   1. Copy the entire contents into a new file with a descriptive
//      name.
//   2. Delete the test logic below and replace it with your own
//      code.
//   3. In top_de1_soc, change the module name from user_top to your
//      new module name.
//
//   The board wrapper sets CYCLES_PER_SECOND; use this parameter in
//   your design wherever timing is needed.
// ------------------------------------------------------------------

`timescale 1ns / 1ps

module user_top_timer_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
`ifdef FORMAL
    output logic probe_running,
    output logic [2:0] probe_mode_enable,
`endif
    input logic clk,
    input logic [3:0] button,
    /* verilator lint_off UNUSED */
    input logic [9:0] sw,
    /* verilator lint_on UNUSED */
    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic blank_hours,
    output logic blank_minutes,
    output logic blank_seconds

);
  logic running = 1'b0;
  logic next_running;
  logic edit_active;
  logic start_stop_pulse;

  assign edit_active = (mode_enable != 3'b000);

  always_ff @(posedge clk) begin
    running <= next_running;
  end

  always_comb begin
    next_running = running;
    if (edit_active || !count_above_zero) next_running = 1'b0;
    else if (start_stop_pulse) next_running = !running;
  end

  rising_edge_detector u_start_stop_edge (
      .clk(clk),
      .sig_in(button[0] && !edit_active),
      .rise(start_stop_pulse)
  );

  //-------------
  // Stopped Mode
  //-------------

  logic clock_divider_run;
  logic seconds_tick;
  logic count_above_zero;
  assign count_above_zero = (seconds != '0) || (minutes != '0) || (hours != '0);

  // Derive 1Hz tick from system clock
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_divider_1_Hz (
      .clk (clk),
      .run (clock_divider_run),
      .tick(seconds_tick)
  );

  assign clock_divider_run = running && count_above_zero;

  logic [5:0] seconds;
  logic seconds_edit;
  logic seconds_inc;
  logic seconds_dec;
  logic seconds_borrow;

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds_countdown (
      .clk(clk),
      .clr(1'b0),
      .tick(seconds_tick),
      .edit_mode(seconds_edit),
      .inc(seconds_inc),
      .dec(seconds_dec),
      .count(seconds),
      .borrow_out(seconds_borrow)
  );

  logic [5:0] minutes;
  logic minutes_edit;
  logic minutes_inc;
  logic minutes_dec;
  logic minutes_borrow;

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_minutes_countdown (
      .clk(clk),
      .clr(1'b0),
      .tick(seconds_borrow),
      .edit_mode(minutes_edit),
      .inc(minutes_inc),
      .dec(minutes_dec),
      .count(minutes),
      .borrow_out(minutes_borrow)
  );

  logic [4:0] hours;
  logic hours_edit;
  logic hours_inc;
  logic hours_dec;

  /* verilator lint_off UNUSEDSIGNAL */
  logic hours_burrow;
  /* verilator lint_on UNUSEDSIGNAL */

  editable_countdown #(
      .MAX  (23),
      .WIDTH(5)
  ) u_hours_countdown (
      .clk(clk),
      .clr(1'b0),
      .tick(minutes_borrow),
      .edit_mode(hours_edit),
      .inc(hours_inc),
      .dec(hours_dec),
      .count(hours),
      .borrow_out(hours_burrow)
  );

  logic [2:0] mode_enable;

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_edit_mode_selector (
      .clk(clk),
      .button(button[3]),
      .mode_enable(mode_enable)
  );

  //---------
  // Set Mode
  //---------

  logic pwm_out;

  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  (CYCLES_PER_SECOND / 10)
  ) u_pwm_generator (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  logic inc_pulse;
  logic dec_pulse;

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_button_auto_repeat_inc (
      .clk(clk),
      .button(button[1]),
      .pulse(inc_pulse)
  );

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_button_auto_repeat_dec (
      .clk(clk),
      .button(button[0]),
      .pulse(dec_pulse)
  );

  assign seconds_edit = mode_enable[0];
  assign minutes_edit = mode_enable[1];
  assign hours_edit = mode_enable[2];

  assign seconds_inc = (seconds_edit && inc_pulse);
  assign minutes_inc = (minutes_edit && inc_pulse);
  assign hours_inc = (hours_edit && inc_pulse);

  assign seconds_dec = (seconds_edit && dec_pulse);
  assign minutes_dec = (minutes_edit && dec_pulse);
  assign hours_dec = (hours_edit && dec_pulse);

  // Zero-extend counter values to display outputs
  assign hours_disp = {2'b0, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  assign led = 10'b0;
  assign blank_seconds = (pwm_out && seconds_edit);
  assign blank_minutes = (pwm_out && minutes_edit);
  assign blank_hours = (pwm_out && hours_edit);

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif
endmodule

