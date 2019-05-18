/////////////////////////////////////////////////////////////////////
// Beat Clock
// Generates a clock tic for every beat (quarter note) based on the
// passed in parameter of BPM.  This uses at it's core a Chu module,
// albeit highly modified.
/////////////////////////////////////////////////////////////////////

module beat_clock
	#(parameter BPM = 120)
	(
	input logic clk,
	input logic reset,
	output logic max_tick
    );
    
//TODO: q may be too big.
logic [30:0] q;
int divisionValue;

// Overflows at 6,250,000, which is exactly 31.25ms aka a quarter note at 120 bpm
always_ff @(posedge clk) begin
    divisionValue = int'(real'(6250000 * 120)/real'(BPM));
    if (q < divisionValue) begin
    q <= q + 1;
    end
    else q = 0;
end

assign max_tick = (q == divisionValue);

endmodule