// Button Hold Detect module which that detects a button
// has been held after a set amount of time.
//
// Ports:
//      clk            - Clock signal.
//      button         - Input for button press.
//      held           - Outputs high for whilst button is held.

`timescale 1ns / 1ps

module button_hold_detect #(
    parameter int HOLD_CYCLES = 50_000_000
) (
    input  logic clk,
    input  logic button,
    output logic held
);

  localparam int CountMax = HOLD_CYCLES;
  localparam int CountWidth = $clog2(CountMax + 1);

  logic count_rst;
  logic count_enable;
  logic [CountWidth-1:0] count;

  mod_n_counter #(
      .N(CountMax + 1),
      .WIDTH(CountWidth)
  ) u_counter (
      .clk(clk),
      .rst(count_rst),
      .enable(count_enable),
      .count(count)
  );

  logic next_held;

  always_ff @(posedge clk) held <= next_held;

  initial held = 1'b0;

  always_comb begin
    next_held = held;
    count_rst = 1'b0;
    count_enable = button;
    if (button == 1'b0) begin
      next_held = 1'b0;
      count_rst = 1'b1;
    end else if (held == 1'b1) begin
      next_held = 1'b1;
      count_enable = 1'b0;
    end else if (count == CountWidth'(CountMax - 1)) begin
      next_held = 1'b1;
      count_enable = 1'b1;
    end else begin
      next_held = 1'b0;
    end
  end

endmodule
