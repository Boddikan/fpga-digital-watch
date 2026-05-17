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

module user_top_brightness_timepiece #(
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

  localparam int Cycle1Ms = CYCLES_PER_SECOND / 1000;
  localparam int Width = $clog2(Cycle1Ms);

  logic [Width-1:0] count;
  logic [Width-1:0] duty_cycle;
  logic pwm_blank;

  logic [1:0] brightness_select;
  logic user_blank_seconds;
  logic user_blank_minutes;
  logic user_blank_hours;

  user_top_timepiece_v1 #(
      .CYCLES_PER_SECOND(CYCLES_PER_SECOND)
  ) u_user_top (
      .clk(clk),
      .button(button),
      .sw(sw),
      .led(led),
      .hours_disp(hours_disp),
      .minutes_disp(minutes_disp),
      .seconds_disp(seconds_disp),
      .blank_hours(user_blank_hours),
      .blank_minutes(user_blank_minutes),
      .blank_seconds(user_blank_seconds)
  );

  mod_n_counter #(
      .N(Cycle1Ms),
      .WIDTH(Width)
  ) u_counter (
      .clk(clk),
      .rst(1'b0),
      .enable(1'b1),
      .count(count)
  );

  always_comb begin
    duty_cycle = Width'(Cycle1Ms);
    if (brightness_select == 2'b00) duty_cycle = Width'(Cycle1Ms / 8);
    else if (brightness_select == 2'b01) duty_cycle = Width'(Cycle1Ms / 4);
    else if (brightness_select == 2'b11) duty_cycle = Width'(Cycle1Ms / 2);
    else duty_cycle = Width'(Cycle1Ms);
  end

  assign pwm_blank = (brightness_select == 2'b10) ? 1'b0 : !(count < duty_cycle);
  assign brightness_select = sw[9:8];
  assign blank_seconds = pwm_blank | user_blank_seconds;
  assign blank_minutes = pwm_blank | user_blank_minutes;
  assign blank_hours = pwm_blank | user_blank_hours;

endmodule
