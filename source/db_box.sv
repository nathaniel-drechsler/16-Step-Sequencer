/*******************************************************
File:   db_box.sv
Module: db_box
Function: This modules purpose is to debounce and detect
the rising edge of the five push buttons. Could be
instantiated to clean up the top module.
*******************************************************/

module db_box
   (
    input logic clk,                                        // 100 MHz clock input
    input logic BTNU, BTND, BTNL, BTNR, BTNC, CPU_RESETN,   // 4 directional push button, center button and CPU reset button inputs
    output logic UP, DOWN, LEFT, RIGHT, CENTER, RESET       // outputs driven by the above buttons
   );

   //signal declarations
   wire UPDBOUTPUT, DOWNDBOUTPUT, LEFTDBOUTPUT, RIGHTDBOUTPUT, CENTERDBOUTPUT, RESETDBOUTPUT; // Connect the db_fsm to the risingEdgeDetector
   wire UPOUTPUT, DOWNOUTPUT, LEFTOUTPUT, RIGHTOUTPUT, CENTEROUTPUT, RESETOUTPUT;             // Connect the risingEdgeDetector to the free_run_shift_reg

db_fsm debounce0(                       //Debounce the up button.
.clk,
.sw(BTNU),
.db(UPDBOUTPUT)
);

risingEdgeDetector rED0(                //Detect the rising edge of the debouncer.
.clk,
.signal(UPDBOUTPUT),
.risingEdge(UPOUTPUT)
);

free_run_shift_reg MetStaReg0(          //metastability register.
.clk,
.s_in(UPOUTPUT),
.s_out(UP)
);

db_fsm debounce1(                       //Debounce the down button.
.clk,
.sw(BTND),
.db(DOWNDBOUTPUT)
);

risingEdgeDetector rED1(                //Detect the rising edge of the debouncer.
.clk,
.signal(DOWNDBOUTPUT),
.risingEdge(DOWNOUTPUT)
);

free_run_shift_reg MetStaReg1(          //Metastability shift register.
.clk,
.s_in(DOWNOUTPUT),
.s_out(DOWN)
);

db_fsm debounce2(                       //Debounce the left button.
.clk,
.sw(BTNL),
.db(LEFTDBOUTPUT)
);

risingEdgeDetector rED2(                //Detect the rising edge of the debouncer.
.clk,
.signal(LEFTDBOUTPUT),
.risingEdge(LEFTOUTPUT)
);

free_run_shift_reg MetStaReg2(          //Metastability register.
.clk,
.s_in(LEFTOUTPUT),
.s_out(LEFT)
);

db_fsm debounce3(                       //Debounce the right button.
.clk,
.sw(BTNR),
.db(RIGHTDBOUTPUT)
);

risingEdgeDetector rED3(                //Detect the rising edge of the debouncer.
.clk,
.signal(RIGHTDBOUTPUT),
.risingEdge(RIGHTOUTPUT)
);

free_run_shift_reg MetStaReg3(          //Metastability register.
.clk,
.s_in(RIGHTOUTPUT),
.s_out(RIGHT)
);

db_fsm debounce4(                       //Debounce the center button.
.clk,
.sw(BTNC),
.db(CENTERDBOUTPUT)
);

risingEdgeDetector rED4(                //Detect the rising edge of the debouncer.
.clk,
.signal(CENTERDBOUTPUT),
.risingEdge(CENTEROUTPUT)
);

free_run_shift_reg MetStaReg4(          //Metastability register.
.clk,
.s_in(CENTEROUTPUT),
.s_out(CENTER)
);

db_fsm debounce5(                       //Debounce the reset button.
.clk,
.sw(CPU_RESETN),
.db(RESETDBOUTPUT)
);

risingEdgeDetector rED5(                //Detect the rising edge of the debouncer.
.clk,
.signal(RESETDBOUTPUT),
.risingEdge(RESETOUTPUT)
);

free_run_shift_reg MetStaReg5(         //Metastability register.
.clk,
.s_in(RESETOUTPUT),
.s_out(RESET)
);

endmodule
