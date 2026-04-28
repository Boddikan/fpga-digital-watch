// Pulse Width Modulation module generates a pulse wave
// in which we define the pulse width by defining the duty cycle.
//
// Ports:
//      clk            - Clock signal.
//      rst            - Resets counter to 0.
//      enable         - Assign next value to flip-flop on positive clock edge when high.
//                     - Hold current value next postive clock edge when low.
//      pwm_out        - Outputs pulse wave.

`timescale 1ns / 1ps

module pwm_generator #(
    // Number of clock cycles in one PWM period
    parameter int PERIOD_CYCLES = 50_000_000,

    // Number of clock cycles output is high.
    parameter int DUTY_CYCLES = 25_000_000
) (
    input  logic clk,
    input  logic rst,
    output logic pwm_out
);
  localparam int CountWidth = $clog2(PERIOD_CYCLES);
  logic enable;
  logic [CountWidth-1:0] count;

  mod_n_counter #(
      .N(PERIOD_CYCLES),
      .WIDTH(CountWidth)
  ) u_counter (
      .clk(clk),
      .rst(rst),
      .enable(enable),
      .count(count)
  );

  assign enable  = 1'd1;

  assign pwm_out = (32'(count) < DUTY_CYCLES);

endmodule
