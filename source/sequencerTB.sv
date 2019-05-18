`timescale 1 ns/10 ps

module SEQUENCER_TB();
    logic clk;
    localparam T = 20;
    localparam millisecond = 1000000;
    logic sw15,sw14,sw13,sw12,sw11,sw10,sw9,sw8,sw7,sw6,sw5,sw4,sw3,sw2,sw1,sw0;
    logic UP, DOWN, LEFT, RIGHT, CENTER, RESET;
    
    
    // UUT instantiation 
    sequencer UUT(
    .CLK100MHZ(clk),
    .SW0(sw0),
    .SW1(sw1),
    .SW2(sw2),
    .SW3(sw3),
    .SW4(sw4),
    .SW5(sw5),
    .SW6(sw6),
    .SW7(sw7),
    .SW8(sw8),
    .SW9(sw9),
    .SW10(sw10),
    .SW11(sw11),
    .SW12(sw12),
    .SW13(sw13),
    .SW14(sw14),
    .SW15(sw15),
    .BTNU(UP),
    .BTND(DOWN),
    .BTNL(LEFT),
    .BTNR(RIGHT),
    .BTNC(CENTER),
    .CPU_RESETN(RESET)
    );
    
    // Setting clock!
    // 20 ns clock, 10ns high (1'b1), 10ns low (1'b0);
    always
    begin
       clk = 1'b1;
       #(T/2);
       clk = 1'b0;
       #(T/2);
    end
    
    // Reset for half cycle (10ns) to clear any extraneous input
    initial
    begin
      #(20*millisecond);
      RESET = 1'b1;
      #(17*millisecond);
      RESET = 1'b0;
      #(60*millisecond);
      RESET = 1'b1;
      #(17*millisecond);
      RESET = 1'b0;
    end
    
    initial
      begin
        UP = 1;
        #(17*millisecond);
        UP = 0; 
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0; 
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0; 
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0; 
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0; 
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
        UP = 1;
        #(17*millisecond);
        UP = 0;
        #(17*millisecond);
      end
 endmodule   