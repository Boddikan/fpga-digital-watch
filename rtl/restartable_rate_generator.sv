// Module that generates one clock cycle ticks after
// run has been high for CYCLE_COUNT - 1 rising edges.
//
// Ports:
//      clk            - Clock signal.
//      run            - Drives tick output.
//      tick           - Outputs one cycle pulse or follows run if CYCLE_COUNT = 1.

`timescale 1ns / 1ps

module restartable_rate_generator #(
    parameter int CYCLE_COUNT = 2
) (
    input  logic clk,
    input  logic run,
    output logic tick
);

  logic tick_qualifier;

  generate
    if (CYCLE_COUNT > 1) begin : g_general
      localparam int CountWidth = $clog2(CYCLE_COUNT);

      logic rst_count;
      logic enable_count;
      logic [CountWidth-1:0] count;

      mod_n_counter #(
          .N(CYCLE_COUNT),
          .WIDTH(CountWidth)
      ) u_count (
          .clk(clk),
          .rst(rst_count),
          .enable(enable_count),
          .count(count)
      );

      assign rst_count = !running;
      assign enable_count = running;

      assign tick_qualifier = (count == CountWidth'(CYCLE_COUNT - 2));

    end else begin : g_special
      assign tick_qualifier = 1'b1;
    end
  endgenerate

  logic running = 1'b0;

  always_ff @(posedge clk) running <= run;

  assign tick = running && tick_qualifier;

endmodule
