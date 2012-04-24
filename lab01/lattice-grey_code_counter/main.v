
/*
 * main - main loop for grey_counter
 *
 * This section includes the grey counter and
 * adds all necessary support for clocks and resets.
 * 
 * This code was derived from the Demo program provided
 * for the Lattice MachX) 2280 Breakout Board which
 * blinks the LED's.
 * [www.latticesemi.com/breakoutboards]
 *
 * Due to the hardware configuration the LEDs are
 * inverted from what is expected.  For example an
 * LED that is on actually indicates a 0 instead of a 1.
 * This is why the grey code, starting at all zeros,
 * has all the LED's on.
 *
 */

`include "grey_counter.v"

// 4 bit oscillating LED pattern
module main(rstn, osc_clk, led, clk );
	input 	rstn ;
	output	osc_clk ;
	output 	wire [7:0] led ;
	output 	clk ;

	reg		[22:0]c_delay ;

	// Reset occurs when argument is active low.
	GSR GSR_INST (.GSR(rstn));

	OSCC OSCC_1 (.OSC(osc_clk)) ;

	grey_counter gc1(clk, led);

	//  The c_delay counter is used to slow down the internal oscillator (OSC) output
	//  to a rate of approximately 0.5 Hz
	always @(posedge osc_clk or negedge rstn)
		 begin
			if (~rstn)
			   c_delay <= 32'h0000 ;
			  else
			   c_delay <= c_delay + 1 ;
		  end

	assign 	clk = c_delay[22] ;
endmodule

