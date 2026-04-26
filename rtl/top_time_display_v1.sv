module top_time_display_v1 #(
    parameter int CYCLES_PER_SECOND = 50_000_000
) (
    input logic CLOCK_50,
    input logic [1:0] SW,
    output logic [6:0] HEX5,
    output logic [6:0] HEX5,
    output logic [6:0] HEX3,
    output logic [6:0] HEX2,
    output logic [6:0] HEX1,
    output logic [6:0] HEX0
);

  hms_counter u_counter (
      .clk (CLOCK_50),
      .run (),
      .tick()
  );

  restartable_rate_generator #(
      .CYCLE_WIDTH()
  ) u1_restartable_rate_generatro (
      .clk (CLOCK_50),
      .run (),
      .tick()
  );

  restartable_rate_generator #(
      .CYCLE_WIDTH()
  ) u2_restartable_rate_generatro (
      .clk (CLOCK_50),
      .run (),
      .tick()
  );

  restartable_rate_generator #(
      .CYCLE_WIDTH()
  ) u3_restartable_rate_generatro (
      .clk (CLOCK_50),
      .run (),
      .tick()
  );

  binary_to_bcd u1_binary_to_bcd (
      .bin (),
      .tens(),
      .ones()
  );

  binary_to_bcd u2_binary_to_bcd (
      .bin (),
      .tens(),
      .ones()
  );

  binary_to_bcd u3_binary_to_bcd (
      .bin (),
      .tens(),
      .ones()
  );

endmodule
