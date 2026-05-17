`timescale 1ns / 1ps
module wave_user_top_brightness_wrapper;
  reg        clk = 0;
  reg  [3:0] button = 4'b0;
  reg  [9:0] sw = 10'b0;
  wire [9:0] led;
  wire [6:0] hours_disp;
  wire [6:0] minutes_disp;
  wire [6:0] seconds_disp;
  wire       blank_hours;
  wire       blank_minutes;
  wire       blank_seconds;

  user_top_brightness_wrapper #(
      .CYCLES_PER_SECOND(50_000_000)
  ) dut (
      .clk          (clk),
      .button       (button),
      .sw           (sw),
      .led          (led),
      .hours_disp   (hours_disp),
      .minutes_disp (minutes_disp),
      .seconds_disp (seconds_disp),
      .blank_hours  (blank_hours),
      .blank_minutes(blank_minutes),
      .blank_seconds(blank_seconds)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("wave_user_top_brightness_wrapper.vcd");
    $dumpvars(0, wave_user_top_brightness_wrapper);

    // Run freely for two full periods (2 * 10 cycles * 10 ns = 200 ns)
    #200;

    sw[9:8] = 2'b00;
    #100;
    sw[9:8] = 2'b01;
    #100;
    sw[9:8] = 2'b10;
    #100;
    sw[9:8] = 2'b11;

    #200 $finish;
  end
endmodule
