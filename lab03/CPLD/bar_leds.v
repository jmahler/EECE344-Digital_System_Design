/*
 * NAME
 * ----
 *
 *   bar_leds - bar of leds
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
 * and then when 'ce_l' goes low the value will be assigned.
 * A similar sequence is performed for a read except that rw = 1.
 *
 * The address is not used since there is only one address
 * and this is in effect accomplished with the chip enable.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module bar_leds(
	input wire ce_l, // chip enable (active low)
	inout wire [8:1] data,
	input wire rw, // read = 1, write = 0  (control)
	output wire [8:1] leds);

	// current value of leds
	reg [8:1] cur_leds;

	assign leds = cur_leds;

	assign data = (~ce_l) ? cur_leds : 8'bz;

	always @(negedge ce_l) begin
		if (rw == 1'b0) begin
			// write
			cur_leds <= data;
		end
	end
endmodule
