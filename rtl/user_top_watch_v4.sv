// User Top Watch V4 wrapper to allow accurate time editing.
//
// Parameters:
//      CYCLES_PER_SECOND      - Clock speed in Hz.
//
// Ports:
//      clk                    - Clock signal.
//      button                 - Buttons to interact with different display modes.
//      sw                     - Switches to change rate of clock.
//      led                    - LEDs on FPGA.
//      hours_disp             - SSEG for hours display.
//      minutes_disp           - SSEG for minutes display.
//      seconds_disp           - SSEG for seconds display.
//      blank_hours            - blanking for hours display.
//      blank_minutes          - blanking for hours display.
//      blank_seconds          - blanking for hours display.

`timescale 1ns / 1ps

module user_top_watch_v4 #(
    /* verilator lint_off UNUSEDPARAM */
    parameter int CYCLES_PER_SECOND = 50_000_000
    /* verilator lint_on UNUSEDPARAM */
) (
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

  //-------------------
  // Core Functionality
  //-------------------

  // Seconds
  logic seconds_tick;
  logic seconds_edit;
  logic seconds_inc;
  logic seconds_dec;
  logic [5:0] seconds;

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_seconds (
      .clk(clk),
      .tick(seconds_tick),
      .edit_mode(seconds_edit),
      .inc(seconds_inc),
      .dec(seconds_dec),
      .count(seconds)
  );

  // Minutes
  logic minutes_tick;
  logic minutes_edit;
  logic minutes_inc;
  logic minutes_dec;
  logic [5:0] minutes;

  editable_counter #(
      .N(60),
      .WIDTH(6)
  ) u_minutes (
      .clk(clk),
      .tick(minutes_tick),
      .edit_mode(minutes_edit),
      .inc(minutes_inc),
      .dec(minutes_dec),
      .count(minutes)
  );

  // Hours
  logic hours_tick;
  logic hours_edit;
  logic hours_inc;
  logic hours_dec;
  logic [4:0] hours;

  editable_counter #(
      .N(24),
      .WIDTH(5)
  ) u_hours (
      .clk(clk),
      .tick(hours_tick),
      .edit_mode(hours_edit),
      .inc(hours_inc),
      .dec(hours_dec),
      .count(hours)
  );

  logic clock_divider_run;

  // Derive 1Hz tick from system clock
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u_divider_1_Hz (
      .clk (clk),
      .run (clock_divider_run),
      .tick(seconds_tick)
  );

  assign clock_divider_run = !(button[3] & mode_enable[0]);

  assign seconds_edit = mode_enable[0];
  assign minutes_edit = mode_enable[1];
  assign hours_edit = mode_enable[2];

  assign seconds_inc = (mode_enable[0] && inc_pulse);
  assign minutes_inc = (mode_enable[1] && inc_pulse);
  assign hours_inc = (mode_enable[2] && inc_pulse);

  assign seconds_dec = (mode_enable[0] && dec_pulse);
  assign minutes_dec = (mode_enable[1] && dec_pulse);
  assign hours_dec = (mode_enable[2] && dec_pulse);

  // Zero-extend counter values to display outputs
  assign hours_disp = {2'b0, hours};
  assign minutes_disp = {1'b0, minutes};
  assign seconds_disp = {1'b0, seconds};

  assign minutes_tick = (seconds_disp == 7'd59 && seconds_tick);
  assign hours_tick = (minutes_disp == 7'd59 && seconds_disp == 7'd59 && seconds_tick);

  // Unused
  assign led = 10'b0;
  assign blank_seconds = (pwm_out && mode_enable[0]);
  assign blank_minutes = (pwm_out && mode_enable[1]);
  assign blank_hours = (pwm_out && mode_enable[2]);

  //---------------
  // Mode Selection
  //---------------

  logic [2:0] mode_enable;

  edit_mode_selector #(
      .HOLD_CYCLES(CYCLES_PER_SECOND)
  ) u_mode_selector (
      .clk(clk),
      .button(button[3]),
      .mode_enable(mode_enable)
  );

  logic pwm_out;

  pwm_generator #(
      .PERIOD_CYCLES(CYCLES_PER_SECOND / 2),
      .DUTY_CYCLES  (CYCLES_PER_SECOND / 10)
  ) u_pwm_generator (
      .clk(clk),
      .rst(1'b0),
      .pwm_out(pwm_out)
  );

  //---------------
  // Edit Logic
  //---------------

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

endmodule

