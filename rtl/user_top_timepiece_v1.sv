`timescale 1ns / 1ps

module user_top_timepiece_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
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
    output logic blank_seconds
);

  typedef struct packed {
    logic [3:0] button;
    logic [9:0] sw;
  } ui_in_t;

  typedef struct packed {
    logic [9:0] led;
    logic [6:0] hours_disp;
    logic [6:0] minutes_disp;
    logic [6:0] seconds_disp;
    logic blank_hours;
    logic blank_minutes;
    logic blank_seconds;
  } ui_out_t;

  ui_in_t watch_in, timer_in, sw_in;
  ui_out_t watch_out, timer_out, sw_out;

  user_top_watch_v4 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top_watch_v4 (
      .clk(clk),
      .button(watch_in.button),
      .sw(watch_in.sw),
      .led(watch_out.led),
      .hours_disp(watch_out.hours_disp),
      .minutes_disp(watch_out.minutes_disp),
      .seconds_disp(watch_out.seconds_disp),
      .blank_hours(watch_out.blank_hours),
      .blank_minutes(watch_out.blank_minutes),
      .blank_seconds(watch_out.blank_seconds)
  );

  user_top_timer_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top_timer_v1 (
      .clk(clk),
      .button(timer_in.button),
      .sw(timer_in.sw),
      .led(timer_out.led),
      .hours_disp(timer_out.hours_disp),
      .minutes_disp(timer_out.minutes_disp),
      .seconds_disp(timer_out.seconds_disp),
      .blank_hours(timer_out.blank_hours),
      .blank_minutes(timer_out.blank_minutes),
      .blank_seconds(timer_out.blank_seconds)
  );

  user_top_stopwatch_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top_stopwatch_v1 (
      .clk(clk),
      .button(sw_in.button),
      .sw(sw_in.sw),
      .led(sw_out.led),
      .hours_disp(sw_out.hours_disp),
      .minutes_disp(sw_out.minutes_disp),
      .seconds_disp(sw_out.seconds_disp),
      .blank_hours(sw_out.blank_hours),
      .blank_minutes(sw_out.blank_minutes),
      .blank_seconds(sw_out.blank_seconds)
  );

  // ------------
  // Multiplexers
  // ------------

  ui_in_t ui_top_in;
  assign ui_top_in.sw = sw;
  assign ui_top_in.button = button;

  ui_in_t ui_top_in_no_buttons;
  assign ui_top_in_no_buttons.sw = sw;
  assign ui_top_in_no_buttons.button = '0;

  ui_out_t ui_top_out;
  assign led           = ui_top_out.led;
  assign hours_disp    = ui_top_out.hours_disp;
  assign minutes_disp  = ui_top_out.minutes_disp;
  assign seconds_disp  = ui_top_out.seconds_disp;
  assign blank_hours   = ui_top_out.blank_hours;
  assign blank_minutes = ui_top_out.blank_minutes;
  assign blank_seconds = ui_top_out.blank_seconds;

  logic [1:0] mode_sel;
  assign mode_sel = sw[1:0];

  always_comb begin

    sw_in = ui_top_in_no_buttons;
    timer_in = ui_top_in_no_buttons;
    watch_in = ui_top_in_no_buttons;

    case (mode_sel)
      // Stopwatch
      2'b01: begin
        sw_in = ui_top_in;
        ui_top_out = sw_out;
      end
      // Timer
      2'b11: begin
        timer_in   = ui_top_in;
        ui_top_out = timer_out;
      end
      // Watch
      default begin
        watch_in   = ui_top_in;
        ui_top_out = watch_out;
      end
    endcase
  end

endmodule
