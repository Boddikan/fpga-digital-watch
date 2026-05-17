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
    /* verilator lint_off UNUSED */
    input logic [3:0] button,
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

  logic start_stop;

  rising_edge_detector u_start_stop_red (
      .clk(clk),
      .sig_in(button[0]),
      .rise(start_stop)
  );

  wire  at_zero = (hours == 0) && (minutes == 0) && (seconds == 0);
  logic running = 1'b0;
  logic next_running;

  always_ff @(posedge clk) begin
    if (at_zero || mode_enable != 3'b000) running <= 1'b0;
    else running <= next_running;
  end

  logic [2:0] mode_enable;
  logic hours_edit;
  logic minutes_edit;
  logic seconds_edit;

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_mode_select (
      .clk(clk),
      .button(button[3] && !running),
      .mode_enable(mode_enable)
  );

  assign hours_edit   = mode_enable[2];
  assign minutes_edit = mode_enable[1];
  assign seconds_edit = mode_enable[0];

  assign next_running = start_stop ? !running : running;

  logic second_tick;

  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_seconds_tick (
      .clk (clk),
      .run (running),
      .tick(second_tick)
  );

  logic pwm_out;

  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  (CYCLES_PER_SECOND / 10)
  ) u_blanking_pwm (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  logic inc_pulse;

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_inc_button_repeat (
      .clk(clk),
      .button(button[1]),
      .pulse(inc_pulse)
  );

  logic dec_pulse;

  button_auto_repeat #(
      .HOLD_CYCLES  (CYCLES_PER_SECOND / 2),
      .REPEAT_CYCLES(CYCLES_PER_SECOND / 10)
  ) u_dec_button_repeat (
      .clk(clk),
      .button(button[0]),
      .pulse(dec_pulse)
  );


  logic [4:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;
  /* verilator lint_off UNUSEDSIGNAL */
  logic hours_borrow;
  /* verilator lint_off UNUSED */
  logic minutes_borrow;
  logic seconds_borrow;
  logic seconds_inc;
  logic minutes_inc;
  logic hours_inc;
  logic seconds_dec;
  logic minutes_dec;
  logic hours_dec;
  logic time_left;

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
      .borrow_out(hours_borrow)
  );

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

  editable_countdown #(
      .MAX  (59),
      .WIDTH(6)
  ) u_seconds_countdown (
      .clk(clk),
      .clr(1'b0),
      .tick(second_tick && running),
      .edit_mode(seconds_edit),
      .inc(seconds_inc),
      .dec(seconds_dec),
      .count(seconds),
      .borrow_out(seconds_borrow)
  );

  assign hours_inc = hours_edit && inc_pulse;
  assign minutes_inc = minutes_edit && inc_pulse;
  assign seconds_inc = seconds_edit && inc_pulse;

  assign hours_dec = hours_edit && dec_pulse;
  assign minutes_dec = minutes_edit && dec_pulse;
  assign seconds_dec = seconds_edit && dec_pulse;

  assign hours_disp = {2'b00, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  assign blank_hours = pwm_out && hours_edit;
  assign blank_minutes = pwm_out && minutes_edit;
  assign blank_seconds = pwm_out && seconds_edit;

  assign time_left = ((hours != '0) || (minutes != '0) || (seconds != '0));

  assign led = 10'b0;

`ifdef FORMAL
  assign probe_running = running;
  assign probe_mode_enable = mode_enable;
`endif
endmodule

