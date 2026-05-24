// ------------------------------------------------------------------
// Board wrapper for the DE1-SoC.
//
// This module handles all board-specific concerns:
//   - Synchronises the KEY inputs and converts them to active-high.
//   - Drives the HEX displays from decimal values.
//   - Connects the audio codec via audio_core (Platform Designer IP).
//   - Sets CYCLES_PER_SECOND to the DE1-SoC clock frequency (50 MHz).
//
// To load a different design, instantiate it in place of
// user_top_timepiece_v1 below.
// ------------------------------------------------------------------
`timescale 1ns / 1ps

module top_de1_soc (
    input  logic       CLOCK_50,
    input  logic [3:0] KEY,       // active-low, asynchronous
    input  logic [9:0] SW,
    output logic [9:0] LEDR,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5,

    // Audio codec pins
    input  logic AUD_ADCDAT,
    input  logic AUD_ADCLRCK,
    input  logic AUD_BCLK,
    output logic AUD_DACDAT,
    input  logic AUD_DACLRCK,
    output logic AUD_XCK,

    // I2C codec config pins
    inout  logic FPGA_I2C_SDAT,
    output logic FPGA_I2C_SCLK
);

  logic [3:0] button;

  key_synchroniser u_key_synchroniser (
      .clk     (CLOCK_50),
      .key_n   (KEY),
      .key_sync(button)
  );

  logic [6:0] hours, minutes, seconds;
  logic blank_hours, blank_minutes, blank_seconds;

  // Audio handshake wires between user_top and audio_core
  logic [31:0] left_data, right_data;
  logic left_valid, right_valid;
  logic left_ready, right_ready;

  user_top_brightness_timepiece #(
      .CYCLES_PER_SECOND(50_000_000)
  ) u_user_top (
      .clk          (CLOCK_50),
      .button       (button),
      .sw           (SW),
      .led          (LEDR),
      .hours_disp   (hours),
      .minutes_disp (minutes),
      .seconds_disp (seconds),
      .blank_hours  (blank_hours),
      .blank_minutes(blank_minutes),
      .blank_seconds(blank_seconds),
      .left_ready   (left_ready),
      .right_ready  (right_ready),
      .left_data    (left_data),
      .right_data   (right_data),
      .left_valid   (left_valid),
      .right_valid  (right_valid)
  );

  decimal_display_driver u_decimal_display_driver (
      .value0(seconds),
      .value1(minutes),
      .value2(hours),
      .blank0(blank_seconds),
      .blank1(blank_minutes),
      .blank2(blank_hours),
      .HEX0  (HEX0),
      .HEX1  (HEX1),
      .HEX2  (HEX2),
      .HEX3  (HEX3),
      .HEX4  (HEX4),
      .HEX5  (HEX5)
  );

  // -------------------------------------------------------------------------
  // Audio codec (Platform Designer system "audio_core")
  // -------------------------------------------------------------------------
  audio_core u_audio_core (
      .clk_clk                                         (CLOCK_50),
      .reset_reset_n                                   (1'b1),
      .audio_pll_0_audio_clk_clk                       (AUD_XCK),
      .audio_0_avalon_left_channel_sink_data           (left_data),
      .audio_0_avalon_left_channel_sink_valid          (left_valid),
      .audio_0_avalon_left_channel_sink_ready          (left_ready),
      .audio_0_avalon_right_channel_sink_data          (right_data),
      .audio_0_avalon_right_channel_sink_valid         (right_valid),
      .audio_0_avalon_right_channel_sink_ready         (right_ready),
      .audio_0_external_interface_ADCDAT               (AUD_ADCDAT),
      .audio_0_external_interface_ADCLRCK              (AUD_ADCLRCK),
      .audio_0_external_interface_BCLK                 (AUD_BCLK),
      .audio_0_external_interface_DACDAT               (AUD_DACDAT),
      .audio_0_external_interface_DACLRCK              (AUD_DACLRCK),
      .audio_and_video_config_0_external_interface_SDAT(FPGA_I2C_SDAT),
      .audio_and_video_config_0_external_interface_SCLK(FPGA_I2C_SCLK)
  );

endmodule
