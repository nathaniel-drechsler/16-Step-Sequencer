/*********************************************************************
File:   sequencer.sv
Module: sequencer
Function: This is the overarching module that will contain everything
required to create one, 16 step sequencer.  Could be instantiated to
create multiple channels of 16 steps each.
Creaeted by: Alex Magee and Nathaniel Drechsler, with portions
approriated from Pong Chu and Professor Pritchards labs.
*********************************************************************/

//////////////////////////////
// PARAMS/MACROS
//////////////////////////////

localparam TRUE = 1, FALSE = 0;

//////////////////////////////
// Main module
//////////////////////////////

module sequencer(
    // Master Clock
    	input logic CLK100MHZ,

    	// Hardware Buttons
    	input logic BTNU, BTND, BTNL, BTNR, BTNC, CPU_RESETN, // 4 directional buttons for menu navigation and center for play/stop, reset for reset.

    	// Hardware Switches
    	input logic SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0, // 16 switches for individual step ON/OFF

    	// 16 LEDs Output
	    output logic [15:0] LED, // Output which step is playing and blink when it is being edited
	    output logic LED16_R = 1'b1,    // Output for PLAY/STOP
	    output logic LED17_R, LED17_G, LED17_B, // Light show!
	    output logic [7:0] AN,               // anodes of the 7-segment displays
        output logic DP,CG,CF,CE,CD,CC,CB,CA, // cathodes of the 7-segment displays

	    // Audio Output
	    output logic AUD_PWM,   // audio signal
	    output logic AUD_SD = 1 // audio enable
);

////////////////////////////////////////////////////////////
// Variables and Things
////////////////////////////////////////////////////////////

// Metastablity stuff.
logic meta = 1;
logic reset = 1;

// Logic values for internal clocks.
logic tempoTick;
logic blinkTick;

// Menu state manchine temp indexes
int newIndex, newIndexHori;

// Button Output logic
logic UP, DOWN, LEFT, RIGHT, CENTER, RESET;


// Audio logic values
logic [31:0] dcy_step  = 32'h0000_0000; // decay time
logic [31:0] atk_step  = 32'hFFFF_FFFF; // attack time
logic [31:0] sus_level = 32'h0000_0000; // sustain level
logic [31:0] sus_time  = 32'h0000_0000; // sustain time
logic [31:0] rel_step  = 32'h0000_0000; // release time

logic [15:0] env;

logic [29:0] fccw;
logic [29:0] noteArray[0:15] = {5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618};
logic [29:0] noteFccwValues [0:11] = {4724, 5005, 5303, 5618,5952, 6306, 6681, 7079, 7500, 7946, 8418, 8919};
logic [4:0]  noteIndex [0:15] = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3};  // Initilize to all threes
logic [1:0]  signalArray [0:15] = {0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1};
logic [15:0] pcm_out;
logic [3:0]  volume = 15;
integer i;
logic soundOn;
logic [3:0] volumeEnabled;
logic [7:0] volumeSquared;
logic signed [24:0] pcm;
logic keyPushed;

logic [15:0] switch;

//////////////////////////////
// Menu State Machine Enums
//////////////////////////////

typedef enum {
              STEP_1,  STEP_2,  STEP_3,  STEP_4,
              STEP_5,  STEP_6,  STEP_7,  STEP_8,
              STEP_9,  STEP_10, STEP_11, STEP_12,
              STEP_13, STEP_14, STEP_15, STEP_16
} step_state;

step_state menuStepState  = STEP_1;
step_state audioStepState = STEP_1;

typedef enum {
              VOLUME,
              ATTACK,
              DECAY,
              SUSTAIN,
              RELEASENOTE,
              SIGNAL,
              NOTE
} menu_horizontal_state;

menu_horizontal_state menuHorizontalState = NOTE;

typedef enum {
              STEP,
              SETTING_NAME,
              SETTING_VALUE
} menu_vertical_state;

menu_vertical_state menuVerticalState = STEP;

typedef enum {
            sine,
            square
} waveform;

typedef enum {
              PLAY, STOP
} on_off_state;

on_off_state playState, playStateNext = STOP;

////////////////////////////////////////////////////////////
// Seven Seg hardcoded binary values
////////////////////////////////////////////////////////////
//    ___
//   | 0 |
//  5|___|1
//   | 6 |
//  4|___|2.
//     3
logic[7:0] A_SSEG =     8'b01110111;    // 0x77
logic[7:0] B_SSEG =     8'b01111100;    // 0x7C
logic[7:0] C_SSEG =     8'b00111001;    // 0x39
logic[7:0] D_SSEG =     8'b01011110;    // 0x5E
logic[7:0] E_SSEG =     8'b01111001;    // 0x79
logic[7:0] F_SSEG =     8'b01110001;    // 0x71
logic[7:0] G_SSEG =     8'b00111101;    // 0x5D
logic[7:0] H_SSEG =     8'b01110110;    // 0x76
logic[7:0] I_SSEG =     8'b00110000;    // 0x18
logic[7:0] K_SSEG =     8'b01110101;    // 0x75
logic[7:0] N_SSEG =     8'b00110111;    // 0x3B
logic[7:0] L_SSEG =     8'b00111000;    // 0x38
logic[7:0] O_SSEG =     8'b00111111;    // 0x3F
logic[7:0] P_SSEG =     8'b01110011;    // 0x73
logic[7:0] Q_SSEG =     8'b01101111;    // 0x37
logic[7:0] R_SSEG =     8'b00110011;    // 0x33
logic[7:0] S_SSEG =     8'b01101101;    // 0x6D
logic[7:0] T_SSEG =     8'b01111000;    // 0x78
logic[7:0] U_SSEG =     8'b00111110;    // 0x3E
logic[7:0] V_SSEG =     8'b00111110;    // 0x3E
logic[7:0] Y_SSEG =     8'b01101110;    // 0x6E

logic[7:0] DP_SSEG =    8'b10000000;    // 0x80
logic[7:0] ZERO_SSEG =  8'b00111111;    // 0x3F
logic[7:0] ONE_SSEG =   8'b00000110;    // 0x06
logic[7:0] TWO_SSEG =   8'b01011011;    // 0x5B
logic[7:0] THREE_SSEG = 8'b01001111;    // 0x4F
logic[7:0] FOUR_SSEG =  8'b01100110;    // 0x66
logic[7:0] FIVE_SSEG =  8'b01101101;    // 0x6D
logic[7:0] SIX_SSEG =   8'b01111101;    // 0x7D
logic[7:0] SEVEN_SSEG = 8'b00000111;    // 0x07
logic[7:0] EIGHT_SSEG = 8'b01111111;    // 0x7F
logic[7:0] NINE_SSEG =  8'b01101111;    // 0x37


// INIT
logic[7:0] sseg7 =      8'b00000000;
logic[7:0] sseg6 =      8'b00000000;
logic[7:0] sseg5 =      8'b00000000;
logic[7:0] sseg4 =      8'b00000000;
logic[7:0] sseg3 =      8'b00000000;
logic[7:0] sseg2 =      8'b00000000;
logic[7:0] sseg1 =      8'b00000000;
logic[7:0] sseg0 =      8'b00000000;


// Debouncing instantiation.
db_box db_box0(
    .clk(CLK100MHZ),
    .BTNL,
    .BTNR,
    .BTNU,
    .BTND,
    .BTNC,
    .CPU_RESETN,
    .LEFT(LEFT),
    .RIGHT(RIGHT),
    .UP(UP),
    .DOWN(DOWN),
    .CENTER(CENTER),
    .RESET(RESET)
);

// Audio processing/ADSR instantiation.
adsr adsr0(
	// inputs
	.clk(CLK100MHZ),
	.reset(reset),
	.start(keyPushed), // adsr sequence starts when a keyboard key is pressed.
	.atk_step,   // attack steepness
	.dcy_step,   // decay steepness
	.sus_level,  // sustain volume level
	.sus_time,   // sustain length of time
	.rel_step,   // release steepness
	// outputs
	.env,        // envelope
	.adsr_idle() // between notes played, unused
);




//////////////////////////////
// Audio State Machine(s)
//////////////////////////////

always_ff @(posedge CLK100MHZ) begin
  if(RESET) playState <= STOP;
  else playState <= playStateNext;
  case(playState)
        STOP: begin
            LED16_R <= 1'b1;
            if(CENTER) begin
            playStateNext <= PLAY;
            end
        end

        PLAY: begin
            LED16_R <= 1'b0;
            if(CENTER) begin
	        playStateNext <= STOP;
            end
        end
    endcase
end


// Audio state machine incrementing.  Takes tempo input (120BPM, 16th note)
// and increments to a new state every tick.
always_ff @(posedge tempoTick)
  begin
    if(playState == PLAY)
        audioStepState <= step_state'(((audioStepState + 1)%16));
    else
        begin
        //do nothing;
        end
  end

// Sound on if switch is on.
always_ff @(posedge tempoTick)
  begin
    if (switch[15-audioStepState])begin
        soundOn <=1;
         fccw <= noteArray[15-audioStepState];
    end

    else begin
        soundOn <=0;
         fccw <= 514724;
    end
  end

////////////////////////////////////////////////////////////
// Menu State Machine
////////////////////////////////////////////////////////////

task increaseMenuStepState();
  begin
      newIndex = menuStepState + 1;    // Increment the enum value of the stateMachine.
      if (newIndex > 15) begin
        newIndex = 0;
      end
      menuStepState <= step_state'(newIndex);
  end
endtask

task decreaseMenuStepState();
  begin
      newIndex = menuStepState;    // Increment the enum value of the stateMachine.
      newIndex = newIndex - 1;
      if (newIndex < 0) begin
        newIndex = 15;
      end
      menuStepState <= step_state'(newIndex);
  end
endtask

task increaseMenuVerticalState();
  begin
    case(menuVerticalState)
      STEP:         begin menuVerticalState <= SETTING_NAME; end
      SETTING_NAME: begin menuVerticalState <= SETTING_VALUE; end
      default:      begin menuVerticalState <= menuVerticalState; end
    endcase
  end
endtask

task decreaseMenuVerticalState();
  begin
    case(menuVerticalState)
      SETTING_NAME:  begin menuVerticalState <= STEP; end
      SETTING_VALUE: begin menuVerticalState <= SETTING_NAME; end
      default:       begin menuVerticalState <= menuVerticalState; end
    endcase
  end
endtask

task increaseMenuHorizontalState();
  begin
      newIndexHori = menuHorizontalState + 1;    // Increment the enum value of the stateMachine.
      if (newIndexHori > 6) begin
        newIndexHori = 0;
      end
      menuHorizontalState <= menu_horizontal_state'(newIndexHori);
  end
endtask

task decreaseMenuHorizontalState();
  begin
      newIndexHori = menuHorizontalState - 1;    // Increment the enum value of the stateMachine.
      if (newIndexHori < 0) begin
        newIndexHori = 6;
      end
      menuHorizontalState <= menu_horizontal_state'(newIndexHori);
  end
endtask

task increaseNote();
  begin
    noteIndex[menuStepState]++;
    noteArray[15-menuStepState] = noteFccwValues[noteIndex[menuStepState]];
  end
endtask

task decreaseNote();
  begin
    noteIndex[menuStepState]--;
    noteArray[15-menuStepState] = noteFccwValues[noteIndex[menuStepState]];
  end
endtask

task changeSignal();
  begin
    case (signalArray[15-menuStepState])
      0: begin
        signalArray[15-menuStepState] = 1;
      end
      1: begin
       signalArray[15-menuStepState] = 0;
      end
    endcase
  end
endtask

/////////////////
// Reset Button!
/////////////////

// DOESN'T CURRENTLY WORK.  We would like it to and some point.


/*always_ff @(posedge CLK100MHZ) begin
  if (RESET) begin
    initializeVariables();
  end
  else begin
  // do nothing
  end
end


task initializeVariables();
  begin
    playState <= STOP;
    menuStepState <= STEP_1;
    menuHorizontalState <= NOTE;
    menuVerticalState <= STEP;
    audioStepState <= STEP_1;
    noteArray <= {5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618, 5618};
    noteIndex <= {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3};
  end
endtask*/

//BUTTON LOGIC/Menu State Machine CODE
always_ff @(posedge CLK100MHZ)
begin
  if (menuVerticalState == STEP) begin
    if (RIGHT) increaseMenuStepState();
    if (LEFT)  decreaseMenuStepState();
    if (UP)    begin end//DO NOTHING
    if (DOWN)  increaseMenuVerticalState();
  end
//////////////////////////////////////////////
  if (menuVerticalState == SETTING_NAME) begin
    if (UP)    decreaseMenuVerticalState();
    if (DOWN)  increaseMenuVerticalState();
    if (LEFT)  decreaseMenuHorizontalState();
    if (RIGHT) increaseMenuHorizontalState();
  end
///////////////////////////////////////////////
  if (menuVerticalState == SETTING_VALUE) begin
    if (UP)  decreaseMenuVerticalState();
    if (DOWN) begin end //DO NOTHING

    case (menuHorizontalState)
      NOTE:
        begin
          if (RIGHT) increaseNote();
          if (LEFT)  decreaseNote();
        end

      SIGNAL:
        begin
          if (UP)   changeSignal();
          if (DOWN) changeSignal();
        end
    endcase
  end
end

// Main seven seg display code.

always_ff @(posedge CLK100MHZ) begin
  if(menuVerticalState == STEP)
    stepDisplay();
  if(menuVerticalState == SETTING_NAME)
    settingDisplay();
  if(menuVerticalState == SETTING_VALUE)
    valueDisplay();
end

// Task for display codes for "STEP" state machine.
task stepDisplay();
begin
  sseg7 = S_SSEG;
  sseg6 = T_SSEG;
  sseg5 = E_SSEG;
  sseg4 = P_SSEG;
  sseg3 = DP_SSEG;
  sseg2 = DP_SSEG;

  case(menuStepState)
  STEP_1: begin
    sseg1 = DP_SSEG;
    sseg0 = ONE_SSEG;
    end
  STEP_2: begin
    sseg1 = DP_SSEG;
    sseg0 = TWO_SSEG;
    end
  STEP_3: begin
    sseg1 = DP_SSEG;
    sseg0 = THREE_SSEG;
    end
  STEP_4: begin
    sseg1 = DP_SSEG;
    sseg0 = FOUR_SSEG;
    end
  STEP_5: begin
    sseg1 = DP_SSEG;
    sseg0 = FIVE_SSEG;
    end
  STEP_6: begin
    sseg1 = DP_SSEG;
    sseg0 = SIX_SSEG;
    end
  STEP_7: begin
    sseg1 = DP_SSEG;
    sseg0 = SEVEN_SSEG;
    end
  STEP_8: begin
    sseg1 = DP_SSEG;
    sseg0 = EIGHT_SSEG;
    end
  STEP_9: begin
    sseg1 = DP_SSEG;
    sseg0 = NINE_SSEG;
    end
  STEP_10: begin
    sseg1 = ONE_SSEG;
    sseg0 = ZERO_SSEG;
    end
  STEP_11: begin
    sseg1 = ONE_SSEG;
    sseg0 = ONE_SSEG;
    end
  STEP_12: begin
    sseg1 = ONE_SSEG;
    sseg0 = TWO_SSEG;
    end
  STEP_13: begin
    sseg1 = ONE_SSEG;
    sseg0 = THREE_SSEG;
    end
  STEP_14: begin
    sseg1 = ONE_SSEG;
    sseg0 = FOUR_SSEG;
    end
  STEP_15: begin
    sseg1 = ONE_SSEG;
    sseg0 = FIVE_SSEG;
    end
  STEP_16: begin
    sseg1 = ONE_SSEG;
    sseg0 = SIX_SSEG;
    end
  endcase
 end
endtask

// Task for display codes for "SETTING_NAME" state machine.
task settingDisplay();
  begin
    sseg3 = 8'b0;
    sseg2 = 8'b0;
    sseg1 = 8'b0;
    sseg0 = 8'b0;
    case (menuHorizontalState)
      VOLUME: begin
        sseg7 = V_SSEG;
        sseg6 = O_SSEG;
        sseg5 = L_SSEG;
        sseg4 = DP_SSEG;
      end

      ATTACK: begin
        sseg7 = A_SSEG;
        sseg6 = T_SSEG;
        sseg5 = T_SSEG;
        sseg4 = K_SSEG;
      end

      DECAY: begin
        sseg7 = D_SSEG;
        sseg6 = E_SSEG;
        sseg5 = C_SSEG;
        sseg4 = Y_SSEG;
      end

      SUSTAIN: begin
        sseg7 = S_SSEG;
        sseg6 = U_SSEG;
        sseg5 = S_SSEG;
        sseg4 = DP_SSEG;
      end

      RELEASENOTE: begin
        sseg7 = R_SSEG;
        sseg6 = E_SSEG;
        sseg5 = L_SSEG;
        sseg4 = DP_SSEG;
      end

      SIGNAL: begin
        sseg7 = S_SSEG;
        sseg6 = I_SSEG;
        sseg5 = G_SSEG;
        sseg4 = DP_SSEG;
      end

      NOTE: begin
        sseg7 = N_SSEG;
        sseg6 = O_SSEG;
        sseg5 = T_SSEG;
        sseg4 = E_SSEG;
      end
    endcase
  end
endtask

// Task for display codes for "SETTING_VALUE" state machine.
task valueDisplay();
  begin
    case (menuHorizontalState)
      NOTE:         noteMenuValues();
      VOLUME:       begin end           //volumeMenuValues();
      ATTACK:       begin end           //attackMenuValues();
      DECAY:        begin end           //decayMenuValues();
      SUSTAIN:      begin end           //sustainMenuValues();
      RELEASENOTE:  begin end           //releasenoteMenuValues();
      SIGNAL:       signalMenuValues(); //signalMenuValues();
    endcase
  end
endtask

// Task for display codes for "Notes" state machine.
task noteMenuValues();
  begin
    case (noteArray[15-menuStepState])
      4724: begin //A4  = 440.000 Hz reference frequency
        sseg3 = A_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  5005: begin //A#4 = 466.164 Hz
        sseg3 = A_SSEG;
        sseg2 = S_SSEG;
        sseg1 = H_SSEG;
        sseg0 = P_SSEG;
      end
      5303: begin //B4  = 493.883 Hz
        sseg3 = B_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  5618: begin //C5  = 523.251 Hz
        sseg3 = C_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  5952: begin //C#5 = 554.365 Hz
        sseg3 = C_SSEG;
        sseg2 = S_SSEG;
        sseg1 = H_SSEG;
        sseg0 = P_SSEG;
      end
	  6306: begin //D5  = 587.330 Hz
        sseg3 = D_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  6681: begin //D#5 = 622.254 Hz
        sseg3 = D_SSEG;
        sseg2 = S_SSEG;
        sseg1 = H_SSEG;
        sseg0 = P_SSEG;
      end
	  7079: begin //E5  = 659.255 Hz
        sseg3 = E_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  7500: begin //F5  = 698.456 Hz
        sseg3 = F_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  7946: begin //F#5 = 739.989 Hz
        sseg3 = F_SSEG;
        sseg2 = S_SSEG;
        sseg1 = H_SSEG;
        sseg0 = P_SSEG;
      end
	  8418: begin //G5  = 783.991 Hz
        sseg3 = G_SSEG;
        sseg2 = 8'b0;
        sseg1 = 8'b0;
        sseg0 = 8'b0;
      end
	  8919: begin //G#5 = 830.609 Hz
        sseg3 = G_SSEG;
        sseg2 = S_SSEG;
        sseg1 = H_SSEG;
        sseg0 = P_SSEG;
      end
    endcase
  end
endtask


// Task for display codes for SIGNAL state machine.
task signalMenuValues();
  begin
    case (signalArray[menuStepState])
      0: begin
        sseg3 = S_SSEG;
        sseg2 = I_SSEG;
        sseg1 = N_SSEG;
        sseg0 = 8'b0;
      end
      1: begin
        sseg3 = S_SSEG;
        sseg2 = Q_SSEG;
        sseg1 = R_SSEG;
        sseg0 = 8'b0;
      end
    endcase
  end
endtask

//////////////////////////////////////////////////////////////
// Audio Generation
//////////////////////////////////////////////////////////////

// **********************************
// Custom clocks
// **********************************
// Puts out a tick every 62.5 seconds, aka a 16th note at 120 bpm.


beat_clock #(120) beat_clock(
    .clk(CLK100MHZ),
    .max_tick(tempoTick),
    .reset(reset)
    );

// Puts out a tick for generating a blinking LED.  67 is chosen for being prime, and
// never overlapping with the 120 beat_clock.  There was a reason for this, which we
// no longer recall.

beat_clock #(67) blink_clock(
    .clk(CLK100MHZ),
    .max_tick(blinkTick),
    .reset(reset)
    );

// **********************************
// Reset Generation
// **********************************


// The FPGA global reset (GSR) is not guaranteed to be synchronous to clk when being released after configuration.
// So the following logic synchronizes the trailing edge of reset to clk, and also mitigates metastability.
always_ff @(posedge CLK100MHZ) begin
	meta <= 0;
	reset <= meta;
end

// Links the switches being enabled to the matching LED being on.
always_ff @(posedge CLK100MHZ)
  begin
    switch[15:0] = {SW15,SW14,SW13,SW12,SW11,SW10,SW9,SW8,SW7,SW6,SW5,SW4,SW3,SW2,SW1,SW0};
    LED[15:0] = switch[15:0];  // LED's on when switch is on!
  end


// Turns the sound on if the switch is on for a step.  AKA enable note logic.
always_ff @(posedge tempoTick)
  begin
    // Sound on if switch is on.
    if (switch[15-audioStepState])begin
        soundOn <=1;
         fccw <= noteArray[15-audioStepState];
    end
    else begin
        soundOn <=0;
         fccw <= 514724;
    end
  end

// Instantiates the main audio generation logic.
ddfs ddfs0(
	// inputs
	.clk(CLK100MHZ),
	.reset(reset),
	.fccw,        // carrier frequency control word
	.focw(30'b0), // frequency offset not used
	.pha(30'b0),  // phase offset not used
	.env,         // envelope from adsr
	.signal(signalArray[audioStepState]),
	// outputs
	.pcm_out,     // pulse code modulated sine wave
	.pulse_out()  // square wave output unused
);


// **********************************
// Volume
// **********************************
always_ff @(posedge CLK100MHZ) begin
	// generate the volume amplitude
	// sound is on only when a key is being pressed

    if (soundOn && (playState == PLAY)) volumeEnabled[3:0] <= volume;
    else         volumeEnabled[3:0] <= 4'h0;

	volumeSquared[7:0] <= volumeEnabled **2; // compensate for human ear non-linearity of perceived volume
	pcm[24:0] <= $signed(pcm_out[15:0]) * $signed({1'b0,volumeSquared[7:0]}); // pcm is a 2's complement number, volumeSquared is a positive number
end


// **********************************
// Digital-To-Analog Converter
// **********************************
ds_1bit_dac ds_1bit_dac0(
	.clk(CLK100MHZ),
	.reset(reset),
	.pcm_in(pcm[23:8]), // pulse code modulated input (bit 24 not used since it's always the same sign bit value as bit 23)
	.pdm_out(AUD_PWM)   // pulse density modulated output to low pass filter and speaker
);

/////////////////////////////////////
// RGB Blink
/////////////////////////////////////

always_ff @(posedge blinkTick) begin
    if(playState == PLAY) begin
        LED17_R = ~LED17_G;
        LED17_G = ~LED17_B;
        LED17_B = ~LED17_R;
    end
    else begin
        LED17_R = 1'b0;
        LED17_G = 1'b0;
        LED17_B = 1'b0;
    end
end

/////////////////////////////////////
// Output to Seven Segment display
/////////////////////////////////////

led_mux8_p dm8_0(
    .clk(CLK100MHZ), .reset(1'b0),
    .in7(sseg7), .in6(sseg6), .in5(sseg5), .in4(sseg4), .in3(sseg3), .in2(sseg2), .in1(sseg1), .in0(sseg0),
    .an(AN[7:0]), .sseg({DP,CG,CF,CE,CD,CC,CB,CA})
);
endmodule
