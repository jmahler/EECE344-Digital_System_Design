/*
 * NAME
 * ----
 *
 *   switches - bussed input switches
 *
 * DESCRIPTION
 * -----------
 * 
 * Switch input module suitable for use with a "bus"
 * consisting of address, data and control lines.
 *
 * Any time it is enabled and the control is for a read (rw = 1)
 * it assigns the switch values on to the bus ('data').
 * Othwise the data output is high z.
 *
 * The address is not used since this is in effect taken
 * care of with the chip enable (ce high).
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module switches(
	input wire switches_ce, // chip enable active high
	output wire [8:1] switches_data,
	input wire switches_rw, // read = 1, write = 0  (control)
	input wire [8:1] switches_input);

	// If enabled (ce == 1) and the control signal is read (rw = 1)
	// assign the switch data, otherwise set to high z.
	assign switches_data = ((switches_ce & switches_rw) == 1'b1) ? (~switches_input) : 8'bz;
    // The input switch values are inverted to compensate for
    // hardware (pull up/down) which is inverted.
endmodule
