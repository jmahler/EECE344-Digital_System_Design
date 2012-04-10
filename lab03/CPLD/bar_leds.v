/*
 * NAME
 * ----
 *
 *   bar_leds - bar of leds
 *
 *
 * DESCRIPTION
 * -----------
 * 
 * 8-bit bar led module suitable for use with a "bus"
 * consisting of address, data and control lines.
 *
 * Any time it is enabled data can be read from (rw = 1)
 * or written to (rw = 0).  At all other times the data
 * line is high z.
 *
 * To write, data must be assigned to 'data', 'rw' set to 0 (write),
 * and then when 'ce' goes high the value will be written.
 * A similar sequence is performed for a read except that rw = 1.
 *
 * The address is not used since it has only one and the equivalent
 * result is accomplished with the chip enable.
 *
 *
 * SYNOPSIS
 * --------
 *
 * This code was take from the test bench bar_leds-test.v.
 * Refer to that module for the most up to date code.
 *  
 *  parameter READ = 1'b1;
 *  parameter WRITE = 1'b0;
 *  parameter ENABLE = 1'b1;
 *  parameter DISABLE = 1'b0;
 *  
 *  // initialize
 *  #1;
 *  ce = DISABLE;
 *  //datar = 8'h00;
 *  datar = 8'bz;
 *  rwr = 1;
 *  
 *  // ### WRITE ###
 *  // IMPORTANT - Nothing else should be driving the bus or else
 *  // bad things could happen.
 *  #1 datar = 8'h4f; // start driving the outputs
 *  #1 rwr = WRITE;
 *  #1 ce = ENABLE;   // enable, triggers a write
 *  // value should have been written
 *  #1 ce = DISABLE;
 *    datar = 8'hz;  // stop driving the outputs
 *  
 *  // ### READ ###
 *  #1 rwr = READ;
 *  #1 ce = ENABLE;
 *  // data should be ready
 *  #1 read_data = datar;
 *  #1 ce = DISABLE;
 *
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */


module bar_leds(
	input wire ce, // chip enable
	inout wire [8:1] data,
	input wire rw, // read = 1, write = 0  (control)
	output wire [8:1] leds);

	// meaning for values of rw
	parameter READ  = 1'b1;
	parameter WRITE = 1'b0;

	// current value of leds
	reg [8:1] cur_leds;

	assign leds = ~(cur_leds);
    // Inverted to compensate for hardware pull up/down design
    // so that a 1 is on and 0 is off.

	assign data = (ce) ? cur_leds : 8'bz;

	// always @(disabled -> enabled)
	always @(posedge ce) begin
		if (rw == WRITE) begin
			// write
			cur_leds <= data;
		end
	end
endmodule
