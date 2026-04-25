// Module converts binary to a Binary Coded Decimal (BCD)
// which represents each digit separately.
//
// Ports:
//      bin            - 7-bit binary number.
//      tens           - 10s column of bin.
//      ones           - 1s column of bin.

`timescale 1ns / 1ps

module binary_to_bcd (
    input  logic [6:0] bin,   // binary input, 0-99
    output logic [3:0] tens,  // decimal tens digit (BCD)
    output logic [3:0] ones   // decimal ones digit (BCD)
);

  assign tens = 4'(bin / 7'd10);
  assign ones = 4'(bin % 7'd10);

endmodule
