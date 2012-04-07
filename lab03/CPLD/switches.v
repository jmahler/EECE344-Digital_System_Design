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
 * care of with the chip enable (ce_l).
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module switches(
	input wire ce_l, // chip enable (active low)
	output wire [8:1] data,
	input wire rw, // read = 1, write = 0  (control)
	input wire [8:1] switches);

	// If enabled (ce_l == 0) and the control signal is read (rw = 1)
	// assign the switch data, otherwise set to high z.
	assign data = (~ce_l && rw) ? (~switches) : 8'bz;
	// switches are inverted here to agree with the actual switch input values
	// (the input circuit cause them to be inverted)
endmodule
