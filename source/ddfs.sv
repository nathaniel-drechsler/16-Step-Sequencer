// Liberated from Lab 8, tweaked to have a input switching between sin and squarewave output.

module ddfs
   #(parameter PW = 30)       // width of phase accumulator
   (
    input  logic clk, reset,
    input  logic [PW-1:0] fccw, // carrier frequency control word
    input  logic [PW-1:0] focw, // frequency offset control word
    input  logic [PW-1:0] pha,  // phase offset
    input  logic [15:0] env,    // envelop 
    
    input  logic [1:0] signal,    // 1 is square, 0 is sin waveform
    
    output logic [15:0] pcm_out,
    output logic pulse_out
   );

   // signal declaration
   logic [PW-1:0] fcw, p_next, pcw;
   logic [PW-1:0] p_reg;
   logic [7:0] p2a_raddr;
   logic [15:0] amp_sin;
   logic [15:0] amp_square;
   logic signed [31:0] modu; 
   logic [15:0] pcm_reg;

   // body
   // instantiate sin ROM
   sin_rom sin_rom_unit
      (.clk(clk), .addr_r(p2a_raddr), .dout(amp_sin));
      
   square_rom square_rom_unit
      (.clk(clk), .addr_r(p2a_raddr), .dout(amp_square));
      
   // phase register and output buffer
   // output "pipeline" buffer to shorten critical path of *
   always_ff @(posedge clk, posedge reset) 
     begin
       if (reset) begin
          p_reg <= 0;
          pcm_reg <= 0;
       end   
       else begin
          p_reg <= p_next;
          pcm_reg <= modu[29:14];
       end
     end
     
   always_ff @(posedge clk)
     begin
       if (signal == 1) begin
         modu = $signed(env) * $signed(amp_square);  // modulated output 
       end
       else begin
         modu = $signed(env) * $signed(amp_sin);  // modulated output
       end 
     end  
   // frequency modulation
   assign fcw = fccw + focw;
   // phase accumulation 
   assign p_next = p_reg + fcw;
   // phase modulation
   assign pcw = p_reg + pha;   
   // phase to amplitude mapping address
   assign p2a_raddr = pcw[PW-1:PW-8];
   // amplitude modulation 
   //   envelop 
   //    * in Q2.14 
   //    * -1 < env < +1  (between 1100...00 and 0100...00) 
   //    * Q16.0 * Q2.14 => modu is Q18.14
   //    * convert modu back to Q16.0  
   assign pcm_out = pcm_reg;
   assign pulse_out = p_reg[PW-1];
endmodule   
   
   // use an output buffer (to shorten crtical path since the o/p feeds dac) 
   // always_ff @(posedge clk)
   //    pcm_reg <= modu[29:14];