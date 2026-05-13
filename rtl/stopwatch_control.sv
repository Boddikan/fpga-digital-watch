// Module stopwatch_control provide a start/stop and lap/rest function.
// Ignores both button presses if rise_start_stop and rise_lap are asserted
// at the same time on a rising clock edge.
//
// Ports:
//      clk                 - Clock signal.
//      rise_start_stop     - Start/Stop toggle.
//      rise_lap            - Toggle between lap states
//      counter_rst         - Resets counter when asserted
//      counter_enable      - Determines if count increments
//      lap_hold            - Display output for live vs frozen

`timescale 1ns / 1ps

module stopwatch_control (
    input  logic clk,
    input  logic rise_start_stop,
    input  logic rise_lap,
    output logic counter_rst = 0,
    output logic counter_enable = 0,
    output logic lap_hold = 0
);

  logic next_counter_rst;
  logic next_counter_enable;
  logic next_lap_hold;

  assign next_counter_enable = (rise_start_stop && !rise_lap) ? !counter_enable : counter_enable;
  assign next_counter_rst = (!counter_enable && !lap_hold && rise_lap && !rise_start_stop);

  always_ff @(posedge clk) begin
    counter_rst <= next_counter_rst;
    counter_enable <= next_counter_enable;
    lap_hold <= next_lap_hold;
  end

  always_comb begin
    next_lap_hold = lap_hold;
    if (rise_start_stop && rise_lap) begin
      // Ignore both presses
    end else begin
      if (counter_enable && !lap_hold && rise_lap) next_lap_hold = '1;
      else if (counter_enable && lap_hold && rise_lap) next_lap_hold = '0;
      else if (!counter_enable && lap_hold && rise_lap) next_lap_hold = '0;
    end
  end

endmodule
