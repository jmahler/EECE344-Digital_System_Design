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
 * and then 'ce' set to high.
 * A similar sequence is performed for a read except that rw = 1.
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
	inout wire [7:0] data,
	input wire rw, // read = 1, write = 0  (control)
	output wire [7:0] leds);

	// meaning for values of rw
	parameter READ  = 1'b1;
	parameter WRITE = 1'b0;

	// current value of leds
	reg [7:0] cur_leds;

	assign leds = ~(cur_leds);
    // Actual LED values are inverted to compensate for
	// hardware pull up/down design so that a 1 is on and 0 is off.

	assign data = (ce == 1'b1 && rw == READ) ? cur_leds : 8'bz;

	// always @(disabled -> enabled)
	always @(data) begin
		if (rw == WRITE && ce == 1'b1) begin
			// write
			cur_leds <= data;
		end
	end
endmodule
