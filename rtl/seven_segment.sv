// Seven-segment display decoder for hexadecimal digits.
//
// Parameters:
//      ACTIVE_LOW     - 1 for active-low LEDs (for example, DE1-SoC),
//                       0 for active-high.
//
// Ports:
//      digit    [3:0] - Hexadecimal digit to display (0x0 to 0xF).
//      blank          - When high, all segments are turned off.
//      segments [6:0] - Segment outputs [g,f,e,d,c,b,a].

`timescale 1ns / 1ps

module seven_segment #(
    parameter int ACTIVE_LOW = 1
) (
    input  logic [3:0] digit,
    input  logic       blank,
    output logic [6:0] segments
);

  logic [6:0] segments_active_high;

  assign segments = ACTIVE_LOW != 0 ? ~segments_active_high : segments_active_high;

  always_comb
    if (blank == 1) begin
      segments_active_high = 7'b0000000;
    end else begin
      unique case (digit)
        4'h0: segments_active_high = 7'b0111111;  // a,b,c,d,e,f
        4'h1: segments_active_high = 7'b0000110;  // b,c
        4'h2: segments_active_high = 7'b1011011;  // a,b,d,e,g
        4'h3: segments_active_high = 7'b1001111;  // a,b,c,d,g
        4'h4: segments_active_high = 7'b1100110;  // b,c,f,g
        4'h5: segments_active_high = 7'b1101101;  // a,c,d,f,g
        4'h6: segments_active_high = 7'b1111101;  // a,c,d,e,f,g
        4'h7: segments_active_high = 7'b0000111;  // a,b,c
        4'h8: segments_active_high = 7'b1111111;  // a,b,c,d,e,f,g
        4'h9: segments_active_high = 7'b1101111;  // a,b,c,d,f,g
        4'ha: segments_active_high = 7'b1110111;  // a,b,c,e,f,g
        4'hb: segments_active_high = 7'b1111100;  // c,d,e,f,g
        4'hc: segments_active_high = 7'b0111001;  // a,d,e,f
        4'hd: segments_active_high = 7'b1011110;  // b,c,d,e,g
        4'he: segments_active_high = 7'b1111001;  // a,d,e,f,g
        4'hf: segments_active_high = 7'b1110001;  // a,e,f,g
      endcase
    end
endmodule
