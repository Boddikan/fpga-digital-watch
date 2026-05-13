`timescale 1ns / 1ps
module wave_user_top_timer_v1;
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

  // CYCLES_PER_SECOND=50 keeps the simulation concise:
  //   1 simulated second       = 50 cycles = 500 ns
  //   Mode-selector hold (1 s) = 50 cycles = 500 ns
  user_top_timer_v1 #(
      .CYCLES_PER_SECOND(50)
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

  always #5 clk = ~clk;  // 100 MHz: 10 ns period

  initial begin
    $dumpfile("wave_user_top_timer_v1.vcd");
    $dumpvars(0, wave_user_top_timer_v1);

    // Normal operation: watch counts for ~1.5 simulated seconds.
    #750;

    // Long press KEY[3] to enter edit mode (seconds selected).
    button[3] = 1;
    #550;  // 55 cycles > HOLD_CYCLES=50
    button[3] = 0;
    #250;
    button[1] = 1;
    #50 button[1] = 0;

    // Short press: advance to minutes edit.
    // Precondition: mode_enable[0]=1 (seconds edit).  The moment button[3]
    // rises, clock_divider_run = !(button[3] & mode_enable[0]) drops to 0
    // (line 165), resetting the divider counter.  count advances to 1 on
    // the next posedge, setting mode_enable[1]=1 (minutes edit) and releasing
    // the divider.  The next seconds_tick therefore arrives a full simulated
    // second after this press, regardless of where the divider was before.
    button[3] = 1;
    #100;
    button[3] = 0;
    #250;

    // Short press: advance to hours edit.
    // mode_enable[0]=0 throughout this press — no divider reset.
    button[3] = 1;
    #100;
    button[3] = 0;
    #250;

    // Short press: exit hours edit (returns to normal mode).
    // mode_enable[0]=0 throughout this press — no divider reset.
    button[3] = 1;
    #100;
    button[3] = 0;

    // Normal operation resumes; observe seconds_tick after a full 500 ns.
    #750;

    $finish;
  end
endmodule
