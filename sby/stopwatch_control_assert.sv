`timescale 1ns / 1ps

module stopwatch_control_assert (
    input  logic clk,
    input  logic rise_start_stop,
    input  logic rise_lap,
    output logic counter_rst,
    output logic counter_enable,
    output logic lap_hold
);

  stopwatch_control u_dut (
      .clk(clk),
      .rise_start_stop(rise_start_stop),
      .rise_lap(rise_lap),
      .counter_rst(counter_rst),
      .counter_enable(counter_enable),
      .lap_hold(lap_hold)
  );

  // verilog_lint: waive-start always-comb

  /* verilator lint_off WIDTHEXPAND */
  /* verilator lint_off BLKSEQ */

  // Hide $initstate from verilator
`ifdef VERILATOR
  wire start = 0;
`else
  wire start = $initstate;
`endif

  // Rising edge detector output cannot be high for two consecutive cycles
  always @(posedge clk) begin
    assume (!($past(rise_start_stop) && rise_start_stop));
    assume (!($past(rise_lap) && rise_lap));
  end

  // Initial state assertions
  initial begin
    assert (counter_rst == 1'b0);
    assert (counter_enable == 1'b0);
    assert (lap_hold == 1'b0);
  end

  // Check simultaneous button presses are ignored
  always @(posedge clk)
    if (!start && $past(rise_start_stop && rise_lap))
      a_ignore : assert ({counter_enable, lap_hold} == $past({counter_enable, lap_hold}));

  // Check reset is an isolated pulse
  always @(posedge clk) if (!start && $past(counter_rst)) a_reset_isolated : assert (!counter_rst);

  wire ss_only = rise_start_stop && !rise_lap;
  wire lap_only = !rise_start_stop && rise_lap;

  // Check enable is toggled by start-stop button
  always @(posedge clk)
    if (!start)
      if ($past(ss_only)) a_enable_toggle : assert (counter_enable != $past(counter_enable));

  // Check enable is otherwise unchanged
  always @(posedge clk)
    if (!start)
      if (!($past(ss_only))) a_enable_hold : assert (counter_enable == $past(counter_enable));

  // Check start-stop does not influence anything else
  always @(posedge clk)
    if (!start) begin
      if ($past(ss_only)) a_ss_hold : assert (lap_hold == $past(lap_hold) && !counter_rst);
    end

  // Check lap button does not influence enable
  always @(posedge clk)
    if (!start) begin
      if ($past(lap_only)) a_lap_hold : assert (counter_enable == $past(counter_enable));
    end

  // Check lap button toggles lap when stopwatch is running
  always @(posedge clk)
    if (!start) begin
      if ($past(lap_only && counter_enable)) a_lap : assert (lap_hold != $past(lap_hold));
    end

  // Check lap button causes a reset
  always @(posedge clk)
    if (!start) begin
      if ($past(lap_only && !(counter_enable || lap_hold))) a_lap_reset : assert (counter_rst);
    end

  // Check only one way to cause reset
  always @(posedge clk)
    if (!start && counter_rst)
      a_reset : assert ($past(lap_only && !counter_enable && !lap_hold));

  // Check invariant
  always @(*) if (counter_rst) a_rst_only : assert (!counter_enable && !lap_hold);

endmodule
