// Testbench written for Report 6 that tests CYCLE_COUNT = 1
`timescale 1ns / 1ps
module wave_restartable_rate_generator_r6;
  reg  clk = 0;
  reg  run = 0;
  wire tick;

  restartable_rate_generator #(
      .CYCLE_COUNT(1)
  ) dut (
      .clk (clk),
      .run (run),
      .tick(tick)
  );

  always #5 clk = ~clk;

  initial begin
    $dumpfile("wave_restartable_rate_generator_r6.vcd");
    $dumpvars(0, wave_restartable_rate_generator_r6);

    // Run: tick fires every CYCLE_COUNT clocks
    #30;
    run = 1;
    #130;

    // Disable mid-cycle: counter resets, no stray tick on re-enable
    run = 0;
    #30;
    run = 1;
    #90;

    run = 0;
    #20 $finish;
  end
endmodule
