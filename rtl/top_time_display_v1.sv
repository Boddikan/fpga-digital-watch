// Top level module to display time on FPGA for our stop watch and connects all modules currently in project.
//
// Parameters:
//     CYCLES_PER_SECOND - Parameter set to clock cycle on FPGA.
//
// Ports:
//      CLOCK_50       - Clock input from FGPA.
//      SW       [1:0] - Switch on FPGA that determines tick rate.
//      HEX5     [6:0] - Segment display to FPGA for hours tens.
//      HEX4     [6:0] - Segment display to FPGA for hours ones.
//      HEX3     [6:0] - Segment display to FPGA for minutes tens.
//      HEX2     [6:0] - Segment display to FPGA for minutes ones.
//      HEX1     [6:0] - Segment display to FPGA for seconds tens.
//      HEX0     [6:0] - Segment display to FPGA for minutes tens.

`timescale 1ns / 1ps

module top_time_display_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic CLOCK_50,
    input logic [1:0] SW,
    output logic [6:0] HEX5,
    output logic [6:0] HEX4,
    output logic [6:0] HEX3,
    output logic [6:0] HEX2,
    output logic [6:0] HEX1,
    output logic [6:0] HEX0
);
  localparam logic [1:0] Hz1 = 2'b00, Hz25 = 2'b01, KHz1 = 2'b10, MHz50 = 2'b11;

  logic enable;
  logic run;
  logic blank;
  logic tick_1hz, tick_25hz, tick_1khz, tick_50mhz;

  logic [4:0] hours;
  logic [5:0] minutes;
  logic [5:0] seconds;

  logic [3:0] hours_tens, hours_ones;
  logic [3:0] minutes_tens, minutes_ones;
  logic [3:0] seconds_tens, seconds_ones;

  // 1Hz
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND)
  ) u1_restartable_rate_generator (
      .clk (CLOCK_50),
      .run (run),
      .tick(tick_1hz)
  );

  // 25Hz
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 25)
  ) u2_restartable_rate_generator (
      .clk (CLOCK_50),
      .run (run),
      .tick(tick_25hz)
  );

  // 1Khz
  restartable_rate_generator #(
      .CYCLE_COUNT(CYCLES_PER_SECOND / 1000)
  ) u3_restartable_rate_generator (
      .clk (CLOCK_50),
      .run (run),
      .tick(tick_1khz)
  );

  assign tick_50mhz = 1'b1;

  always_comb begin
    case (SW)
      Hz1: enable = tick_1hz;
      Hz25: enable = tick_25hz;
      KHz1: enable = tick_1khz;
      MHz50: enable = tick_50mhz;
      default: enable = tick_1hz;
    endcase
  end

  hms_counter u_counter (
      .clk(CLOCK_50),
      .enable(enable),
      .hours(hours),
      .minutes(minutes),
      .seconds(seconds)
  );

  binary_to_bcd u_hours_bcd (
      .bin ({2'b0, hours}),
      .tens(hours_tens),
      .ones(hours_ones)
  );

  binary_to_bcd u_minutes_bcd (
      .bin ({1'b0, minutes}),
      .tens(minutes_tens),
      .ones(minutes_ones)
  );

  binary_to_bcd u_seconds_bcd (
      .bin ({1'b0, seconds}),
      .tens(seconds_tens),
      .ones(seconds_ones)
  );

  seven_segment u_hex5 (
      .digit(hours_tens),
      .blank(blank),
      .segments(HEX5)
  );

  seven_segment u_hex4 (
      .digit(hours_ones),
      .blank(blank),
      .segments(HEX4)
  );

  seven_segment u_hex3 (
      .digit(minutes_tens),
      .blank(blank),
      .segments(HEX3)
  );

  seven_segment u_hex2 (
      .digit(minutes_ones),
      .blank(blank),
      .segments(HEX2)
  );

  seven_segment u_hex1 (
      .digit(seconds_tens),
      .blank(blank),
      .segments(HEX1)
  );

  seven_segment u_hex0 (
      .digit(seconds_ones),
      .blank(blank),
      .segments(HEX0)
  );

  assign run   = 1'd1;
  assign blank = 1'd0;

endmodule
