// User Top Sequencer V1 — step sequencer + tone gen, integrated into the
// user_top interface with audio output.
//
// This wrapper preserves the proven button-handling and state machine logic
// from the standalone sequencer test, adapted to:
//   - The user_top interface (active-high synced buttons, decimal display)
//   - 8 steps mapped to SW[9:2] (SW[1:0] reserved for top-level mode select)
//   - LEDs mapped to LED[9:2] (matching the switch alignment)
//
// Display layout:
//   value2 (HEX5/4): 01 (Seq mode) or 02 (Gen mode)
//   value1 (HEX3/2): tempo 1-9 (Seq) or scale 1-4 (Gen)
//   value0 (HEX1/0): direction+running (Seq) or pulse_width+octave (Gen)
//
// Controls in SEQUENCER mode:
//   button[0]: start/stop
//   button[1]: reverse direction
//   button[2]: tempo +100 BPM (200, 300, ..., 1000, wraps)
//   button[3]: hold ~0.5s to enter tone gen mode
//
// Controls in TONE GEN mode:
//   button[0]: octave down
//   button[1]: octave up
//   button[2]: cycle pulse width
//   button[3]: short press = next scale, hold ~0.5s = back to sequencer

`timescale 1ns / 1ps

module user_top_sequencer_v1 #(
    /* verilator lint_off UNUSEDPARAM */
    parameter int CYCLES_PER_SECOND = 50_000_000
    /* verilator lint_on UNUSEDPARAM */
) (
    input logic       clk,
    input logic [3:0] button,  // active-high, synced
    input logic [9:0] sw,

    output logic [9:0] led,
    output logic [6:0] hours_disp,
    output logic [6:0] minutes_disp,
    output logic [6:0] seconds_disp,
    output logic       blank_hours,
    output logic       blank_minutes,
    output logic       blank_seconds,

    // Audio sink interface (to audio_core)
    input  logic        left_ready,
    input  logic        right_ready,
    output logic [31:0] left_data,
    output logic [31:0] right_data,
    output logic        left_valid,
    output logic        right_valid
);

  // Invert active-high button to active-low (KEY) for internal logic
  logic [3:0] key;
  assign key = ~button;

  localparam int SampleRateDiv = 1041;
  localparam logic [31:0] High = 32'h7FFFFF00;
  localparam logic [31:0] Low = 32'h80000100;
  localparam logic [25:0] HoldThreshold = 26'd25_000_000;  // ~0.5s

  // -------------------------------------------------------------------------
  // 4 scales × 5 octaves × 10 notes = 200 entries (padded to 256)
  // Index: scale * 50 + octave_offset * 10 + step
  // All scales rooted at C. We only use steps 0-7 of each row for 8 steps.
  // -------------------------------------------------------------------------
  logic [15:0] note_lut[256];
  initial begin
    // ===== SCALE 0: DARK TECHNO (root C) =====
    note_lut[0]   = 16'd734;
    note_lut[1]   = 16'd617;
    note_lut[2]   = 16'd550;
    note_lut[3]   = 16'd519;
    note_lut[4]   = 16'd490;
    note_lut[5]   = 16'd412;
    note_lut[6]   = 16'd367;
    note_lut[7]   = 16'd309;
    note_lut[8]   = 16'd259;
    note_lut[9]   = 16'd245;
    note_lut[10]  = 16'd367;
    note_lut[11]  = 16'd309;
    note_lut[12]  = 16'd275;
    note_lut[13]  = 16'd259;
    note_lut[14]  = 16'd245;
    note_lut[15]  = 16'd206;
    note_lut[16]  = 16'd183;
    note_lut[17]  = 16'd154;
    note_lut[18]  = 16'd130;
    note_lut[19]  = 16'd122;
    note_lut[20]  = 16'd183;
    note_lut[21]  = 16'd154;
    note_lut[22]  = 16'd137;
    note_lut[23]  = 16'd130;
    note_lut[24]  = 16'd122;
    note_lut[25]  = 16'd103;
    note_lut[26]  = 16'd92;
    note_lut[27]  = 16'd77;
    note_lut[28]  = 16'd65;
    note_lut[29]  = 16'd61;
    note_lut[30]  = 16'd92;
    note_lut[31]  = 16'd77;
    note_lut[32]  = 16'd69;
    note_lut[33]  = 16'd65;
    note_lut[34]  = 16'd61;
    note_lut[35]  = 16'd51;
    note_lut[36]  = 16'd46;
    note_lut[37]  = 16'd39;
    note_lut[38]  = 16'd32;
    note_lut[39]  = 16'd31;
    note_lut[40]  = 16'd46;
    note_lut[41]  = 16'd39;
    note_lut[42]  = 16'd34;
    note_lut[43]  = 16'd32;
    note_lut[44]  = 16'd31;
    note_lut[45]  = 16'd26;
    note_lut[46]  = 16'd23;
    note_lut[47]  = 16'd19;
    note_lut[48]  = 16'd16;
    note_lut[49]  = 16'd15;

    // ===== SCALE 1: HARMONIC MINOR (root C) =====
    note_lut[50]  = 16'd734;
    note_lut[51]  = 16'd654;
    note_lut[52]  = 16'd617;
    note_lut[53]  = 16'd550;
    note_lut[54]  = 16'd490;
    note_lut[55]  = 16'd462;
    note_lut[56]  = 16'd389;
    note_lut[57]  = 16'd367;
    note_lut[58]  = 16'd309;
    note_lut[59]  = 16'd245;
    note_lut[60]  = 16'd367;
    note_lut[61]  = 16'd327;
    note_lut[62]  = 16'd309;
    note_lut[63]  = 16'd275;
    note_lut[64]  = 16'd245;
    note_lut[65]  = 16'd231;
    note_lut[66]  = 16'd194;
    note_lut[67]  = 16'd183;
    note_lut[68]  = 16'd154;
    note_lut[69]  = 16'd122;
    note_lut[70]  = 16'd183;
    note_lut[71]  = 16'd163;
    note_lut[72]  = 16'd154;
    note_lut[73]  = 16'd137;
    note_lut[74]  = 16'd122;
    note_lut[75]  = 16'd116;
    note_lut[76]  = 16'd97;
    note_lut[77]  = 16'd92;
    note_lut[78]  = 16'd77;
    note_lut[79]  = 16'd61;
    note_lut[80]  = 16'd92;
    note_lut[81]  = 16'd82;
    note_lut[82]  = 16'd77;
    note_lut[83]  = 16'd69;
    note_lut[84]  = 16'd61;
    note_lut[85]  = 16'd58;
    note_lut[86]  = 16'd49;
    note_lut[87]  = 16'd46;
    note_lut[88]  = 16'd39;
    note_lut[89]  = 16'd31;
    note_lut[90]  = 16'd46;
    note_lut[91]  = 16'd41;
    note_lut[92]  = 16'd39;
    note_lut[93]  = 16'd34;
    note_lut[94]  = 16'd31;
    note_lut[95]  = 16'd29;
    note_lut[96]  = 16'd24;
    note_lut[97]  = 16'd23;
    note_lut[98]  = 16'd19;
    note_lut[99]  = 16'd15;

    // ===== SCALE 2: PHRYGIAN (root C) =====
    note_lut[100] = 16'd734;
    note_lut[101] = 16'd693;
    note_lut[102] = 16'd617;
    note_lut[103] = 16'd550;
    note_lut[104] = 16'd490;
    note_lut[105] = 16'd462;
    note_lut[106] = 16'd412;
    note_lut[107] = 16'd367;
    note_lut[108] = 16'd346;
    note_lut[109] = 16'd309;
    note_lut[110] = 16'd367;
    note_lut[111] = 16'd346;
    note_lut[112] = 16'd309;
    note_lut[113] = 16'd275;
    note_lut[114] = 16'd245;
    note_lut[115] = 16'd231;
    note_lut[116] = 16'd206;
    note_lut[117] = 16'd183;
    note_lut[118] = 16'd173;
    note_lut[119] = 16'd154;
    note_lut[120] = 16'd183;
    note_lut[121] = 16'd173;
    note_lut[122] = 16'd154;
    note_lut[123] = 16'd137;
    note_lut[124] = 16'd122;
    note_lut[125] = 16'd116;
    note_lut[126] = 16'd103;
    note_lut[127] = 16'd92;
    note_lut[128] = 16'd87;
    note_lut[129] = 16'd77;
    note_lut[130] = 16'd92;
    note_lut[131] = 16'd87;
    note_lut[132] = 16'd77;
    note_lut[133] = 16'd69;
    note_lut[134] = 16'd61;
    note_lut[135] = 16'd58;
    note_lut[136] = 16'd51;
    note_lut[137] = 16'd46;
    note_lut[138] = 16'd43;
    note_lut[139] = 16'd39;
    note_lut[140] = 16'd46;
    note_lut[141] = 16'd43;
    note_lut[142] = 16'd39;
    note_lut[143] = 16'd34;
    note_lut[144] = 16'd31;
    note_lut[145] = 16'd29;
    note_lut[146] = 16'd26;
    note_lut[147] = 16'd23;
    note_lut[148] = 16'd22;
    note_lut[149] = 16'd19;

    // ===== SCALE 3: 10-TET (root C, 120 cents per step) =====
    note_lut[150] = 16'd734;
    note_lut[151] = 16'd685;
    note_lut[152] = 16'd639;
    note_lut[153] = 16'd596;
    note_lut[154] = 16'd556;
    note_lut[155] = 16'd519;
    note_lut[156] = 16'd484;
    note_lut[157] = 16'd452;
    note_lut[158] = 16'd422;
    note_lut[159] = 16'd393;
    note_lut[160] = 16'd367;
    note_lut[161] = 16'd342;
    note_lut[162] = 16'd319;
    note_lut[163] = 16'd298;
    note_lut[164] = 16'd278;
    note_lut[165] = 16'd259;
    note_lut[166] = 16'd242;
    note_lut[167] = 16'd226;
    note_lut[168] = 16'd211;
    note_lut[169] = 16'd197;
    note_lut[170] = 16'd183;
    note_lut[171] = 16'd171;
    note_lut[172] = 16'd160;
    note_lut[173] = 16'd149;
    note_lut[174] = 16'd139;
    note_lut[175] = 16'd130;
    note_lut[176] = 16'd121;
    note_lut[177] = 16'd113;
    note_lut[178] = 16'd105;
    note_lut[179] = 16'd98;
    note_lut[180] = 16'd92;
    note_lut[181] = 16'd86;
    note_lut[182] = 16'd80;
    note_lut[183] = 16'd75;
    note_lut[184] = 16'd70;
    note_lut[185] = 16'd65;
    note_lut[186] = 16'd61;
    note_lut[187] = 16'd56;
    note_lut[188] = 16'd53;
    note_lut[189] = 16'd49;
    note_lut[190] = 16'd46;
    note_lut[191] = 16'd43;
    note_lut[192] = 16'd40;
    note_lut[193] = 16'd37;
    note_lut[194] = 16'd35;
    note_lut[195] = 16'd32;
    note_lut[196] = 16'd30;
    note_lut[197] = 16'd28;
    note_lut[198] = 16'd26;
    note_lut[199] = 16'd25;

    // Padding for power-of-2 memory depth (suppresses Quartus init warning)
    for (int i = 200; i < 256; i++) note_lut[i] = 16'd25;
  end

  // BPM lookup — 200, 300, ..., 1000 BPM (9 entries, padded to 16)
  logic [25:0] bpm_lut[16];
  initial begin
    bpm_lut[0] = 26'd15000000;  //  200 BPM
    bpm_lut[1] = 26'd10000000;  //  300 BPM
    bpm_lut[2] = 26'd7500000;  //  400 BPM
    bpm_lut[3] = 26'd6000000;  //  500 BPM
    bpm_lut[4] = 26'd5000000;  //  600 BPM
    bpm_lut[5] = 26'd4285714;  //  700 BPM
    bpm_lut[6] = 26'd3750000;  //  800 BPM
    bpm_lut[7] = 26'd3333333;  //  900 BPM
    bpm_lut[8] = 26'd3000000;  // 1000 BPM
    for (int i = 9; i < 16; i++) bpm_lut[i] = 26'd3000000;
  end

  // -------------------------------------------------------------------------
  // Button edge detection + KEY[3] hold detection (proven logic from
  // standalone sequencer test)
  // -------------------------------------------------------------------------
  logic [ 3:0] key_prev;
  logic [ 3:0] key_pressed;
  logic [25:0] key3_hold_counter;
  logic        key3_long_press_fired;

  // -------------------------------------------------------------------------
  // State registers
  // -------------------------------------------------------------------------
  logic        running;
  logic        direction;
  logic [ 3:0] step;  // 4-bit but limited to 0-7
  logic [ 3:0] bpm_index;
  logic [25:0] step_counter;
  logic        mode;  // 0=sequencer, 1=tone gen
  logic [ 2:0] octave_offset;  // 0-4
  logic [ 1:0] pulse_width;
  logic [ 1:0] scale;

  initial begin
    running               = 1'b0;
    direction             = 1'b0;
    step                  = 4'd0;
    bpm_index             = 4'd0;
    step_counter          = 26'd0;
    mode                  = 1'b0;
    octave_offset         = 3'd1;
    pulse_width           = 2'd0;
    scale                 = 2'd0;
    key_prev              = 4'hF;
    key3_hold_counter     = 26'd0;
    key3_long_press_fired = 1'b0;
  end

  assign key_pressed = key_prev & ~key;  // falling edge of key (= button press)

  always_ff @(posedge clk) begin
    key_prev <= key;

    // KEY[3] hold detection
    if (!key[3]) begin
      // currently held
      if (key3_hold_counter < HoldThreshold) begin
        key3_hold_counter <= key3_hold_counter + 1'b1;
      end else if (!key3_long_press_fired) begin
        mode                  <= ~mode;
        key3_long_press_fired <= 1'b1;
      end
    end else begin
      // released - detect short press
      if (!key_prev[3] && !key3_long_press_fired) begin
        if (mode) begin
          // In tone gen mode, cycle scale
          if (scale == 2'd3) scale <= 2'd0;
          else scale <= scale + 1'b1;
        end
      end
      key3_hold_counter     <= 26'd0;
      key3_long_press_fired <= 1'b0;
    end

    if (!mode) begin
      // -------- Sequencer mode --------
      if (key_pressed[0]) running <= ~running;
      if (key_pressed[1]) direction <= ~direction;
      if (key_pressed[2]) begin
        if (bpm_index == 4'd8) bpm_index <= 4'd0;
        else bpm_index <= bpm_index + 1'b1;
      end
    end else begin
      // -------- Tone gen mode --------
      if (key_pressed[0]) begin
        if (octave_offset != 3'd0) octave_offset <= octave_offset - 1'b1;
      end
      if (key_pressed[1]) begin
        if (octave_offset != 3'd4) octave_offset <= octave_offset + 1'b1;
      end
      if (key_pressed[2]) pulse_width <= pulse_width + 1'b1;
    end

    // Sequencer step advance (runs in both modes)
    if (running) begin
      if (step_counter >= bpm_lut[bpm_index] - 1) begin
        step_counter <= 26'd0;
        if (!direction) begin
          if (step == 4'd7) step <= 4'd0;
          else step <= step + 1'b1;
        end else begin
          if (step == 4'd0) step <= 4'd7;
          else step <= step - 1'b1;
        end
      end else begin
        step_counter <= step_counter + 1'b1;
      end
    end else begin
      step_counter <= 26'd0;
    end
  end

  // -------------------------------------------------------------------------
  // LED — light step's position (step 0 → LED[2], step 7 → LED[9])
  // -------------------------------------------------------------------------
  logic [3:0] led_index;
  assign led_index = step + 4'd2;
  always_comb begin
    led = 10'b0;
    led[led_index[3:0]] = 1'b1;
  end

  // -------------------------------------------------------------------------
  // Display values
  //   Sequencer mode:
  //     value2 = 1                  → HEX5=0, HEX4=1
  //     value1 = bpm_index + 1      → HEX3=0, HEX2=tempo (1-9)
  //     value0 = direction*10 + run → HEX1=direction, HEX0=running
  //   Tone gen mode:
  //     value2 = 2                  → HEX5=0, HEX4=2
  //     value1 = scale + 1          → HEX3=0, HEX2=scale (1-4)
  //     value0 = (pw+1)*10 + (oct+1) → HEX1=pulse_width, HEX0=octave
  // -------------------------------------------------------------------------
  logic [6:0] value2_calc;
  logic [6:0] value1_calc;
  logic [6:0] value0_calc;

  always_comb begin
    if (!mode) begin
      value2_calc = 7'd1;
      value1_calc = {3'b0, bpm_index} + 7'd1;
      value0_calc = ({6'b0, direction}) * 7'd10 + {6'b0, running};
    end else begin
      value2_calc = 7'd2;
      value1_calc = {5'b0, scale} + 7'd1;
      value0_calc = ({5'b0, pulse_width} + 7'd1) * 7'd10 + {4'b0, octave_offset} + 7'd1;
    end
  end

  assign hours_disp    = value2_calc;
  assign minutes_disp  = value1_calc;
  assign seconds_disp  = value0_calc;
  assign blank_hours   = 1'b0;
  assign blank_minutes = 1'b0;
  assign blank_seconds = 1'b0;

  // -------------------------------------------------------------------------
  // Note lookup
  // -------------------------------------------------------------------------
  logic [ 7:0] note_index;
  logic [15:0] half_period;
  logic        step_active;
  logic [ 3:0] sw_index;

  assign note_index  = {6'b0, scale} * 8'd50
                     + {5'b0, octave_offset} * 8'd10
                     + {4'b0, step};
  assign half_period = note_lut[note_index];

  // SW indexing: step 0 → SW[2], step 7 → SW[9]
  assign sw_index    = step + 4'd2;
  assign step_active = running & sw[sw_index[3:0]];

  // -------------------------------------------------------------------------
  // Pulse width
  // -------------------------------------------------------------------------
  logic [15:0] high_count;
  logic [15:0] low_count;
  always_comb begin
    case (pulse_width)
      2'b00: begin
        high_count = half_period;
        low_count  = half_period;
      end
      2'b01: begin
        high_count = (half_period >> 1) + (half_period >> 2);
        low_count  = half_period + (half_period >> 2);
      end
      2'b10: begin
        high_count = half_period >> 1;
        low_count  = half_period + (half_period >> 1);
      end
      2'b11: begin
        high_count = half_period >> 2;
        low_count  = half_period + (half_period >> 1) + (half_period >> 2);
      end
      default: begin
        high_count = half_period;
        low_count  = half_period;
      end
    endcase
  end

  // -------------------------------------------------------------------------
  // Square wave oscillator
  // -------------------------------------------------------------------------
  logic [10:0] clk_div;
  logic [15:0] sample_count;
  logic        square;

  initial begin
    clk_div      = '0;
    sample_count = '0;
    square       = 1'b1;
  end

  always_ff @(posedge clk) begin
    if (clk_div == SampleRateDiv - 1) begin
      clk_div <= '0;
      if (square) begin
        if (sample_count >= high_count - 1) begin
          sample_count <= '0;
          square       <= 1'b0;
        end else sample_count <= sample_count + 1'b1;
      end else begin
        if (sample_count >= low_count - 1) begin
          sample_count <= '0;
          square       <= 1'b1;
        end else sample_count <= sample_count + 1'b1;
      end
    end else clk_div <= clk_div + 1'b1;
  end

  logic [31:0] sample;
  assign sample      = step_active ? (square ? High : Low) : 32'h00000000;
  assign left_data   = sample;
  assign right_data  = sample;
  assign left_valid  = left_ready;
  assign right_valid = right_ready;

endmodule
