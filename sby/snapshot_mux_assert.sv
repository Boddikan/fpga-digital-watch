`timescale 1ns / 1ps

module snapshot_mux_assert #(
    parameter int WIDTH = 1
) (
    input logic clk,
    input logic hold,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

  snapshot_mux #(
      .WIDTH(WIDTH)
  ) u_dut (
      .clk(clk),
      .hold(hold),
      .d(d),
      .q(q)
  );

  // verilog_lint: waive-start always-comb

  // Hide $initstate from verilator
`ifdef VERILATOR
  wire start = 0;
`else
  wire start = $initstate;
`endif

  // Ensure parameter values are sensible
  initial assert (WIDTH > 0);

  // Check transparency
  always @(*) if (!hold) a_transparency : assert (q == d);

  // Check initialisation
  initial if (hold) assert (q == 0);

  // Check hold
  always @(posedge clk) if (!start && hold) assert (q == $past(q));

endmodule
