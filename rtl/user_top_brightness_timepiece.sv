// User Top Brightness Timepiece — adds PWM-based display dimming around
// user_top_timepiece_v1, while passing audio through unchanged.
//
// SW[9:8] controls brightness, but only in modes where the inner app
// asserts brightness_enable (clock mode 00 and stopwatch mode 01).
// In sequencer mode (10) and timer mode (11), SW[9:8] are used for other
// purposes and brightness defaults to full.
//
//   00 = 12.5% duty (dimmest)
//   01 = 25%
//   10 = full brightness
//   11 = 50% duty
//
// Audio is passed straight through (brightness is purely visual).

`timescale 1ns / 1ps

module user_top_brightness_timepiece #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic       clk,
    input logic [3:0] button,
    input logic [9:0] sw,

    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic       blank_hours,
    output logic       blank_minutes,
    output logic       blank_seconds,

    // Audio sink interface (passthrough)
    input  logic        left_ready,
    input  logic        right_ready,
    output logic [31:0] left_data,
    output logic [31:0] right_data,
    output logic        left_valid,
    output logic        right_valid
);

  localparam int Cycle1Ms = CYCLES_PER_SECOND / 1000;
  localparam int Width = $clog2(Cycle1Ms);

  logic [Width-1:0] count;
  logic [Width-1:0] duty_cycle;
  logic [      1:0] brightness_select;
  logic             brightness_enable;
  logic             raw_pwm_blank;
  logic             pwm_blank;
  logic             user_blank_seconds;
  logic             user_blank_minutes;
  logic             user_blank_hours;

  // -------------------------------------------------------------------------
  // Inner app — timepiece (includes watch, timer, stopwatch, sequencer)
  // -------------------------------------------------------------------------
  user_top_timepiece_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top (
      .clk              (clk),
      .button           (button),
      .sw               (sw),
      .led              (led),
      .hours_disp       (hours_disp),
      .minutes_disp     (minutes_disp),
      .seconds_disp     (seconds_disp),
      .blank_hours      (user_blank_hours),
      .blank_minutes    (user_blank_minutes),
      .blank_seconds    (user_blank_seconds),
      .brightness_enable(brightness_enable),
      .left_ready       (left_ready),
      .right_ready      (right_ready),
      .left_data        (left_data),
      .right_data       (right_data),
      .left_valid       (left_valid),
      .right_valid      (right_valid)
  );

  // -------------------------------------------------------------------------
  // PWM dimming
  // -------------------------------------------------------------------------
  mod_n_counter #(
      .N    (Cycle1Ms),
      .WIDTH(Width)
  ) u_counter (
      .clk   (clk),
      .rst   (1'b0),
      .enable(1'b1),
      .count (count)
  );

  assign brightness_select = sw[9:8];

  always_comb begin
    case (brightness_select)
      2'b00:   duty_cycle = Width'(Cycle1Ms / 8);  // 12.5%
      2'b01:   duty_cycle = Width'(Cycle1Ms / 4);  // 25%
      2'b11:   duty_cycle = Width'(Cycle1Ms / 2);  // 50%
      default: duty_cycle = Width'(Cycle1Ms);  // full (2'b10)
    endcase
  end

  assign raw_pwm_blank = (brightness_select == 2'b10) ? 1'b0 : !(count < duty_cycle);
  assign pwm_blank     = brightness_enable & raw_pwm_blank;

  assign blank_seconds = pwm_blank | user_blank_seconds;
  assign blank_minutes = pwm_blank | user_blank_minutes;
  assign blank_hours   = pwm_blank | user_blank_hours;

endmodule
