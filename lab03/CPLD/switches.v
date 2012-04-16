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
	input wire ce, // chip enable active high
	inout wire [7:0] data,
	input wire rw, // read = 1, write = 0  (control)
	input wire [7:0] in_sw);

	// If enabled (ce == 1) and the control signal is read (rw = 1)
	// assign the switch data, otherwise set to high z.
	assign data = ((ce & rw) == 1'b1) ? (~in_sw) : 8'bz;
    // The input switch values are inverted to compensate for
    // hardware (pull up/down) which is inverted.
endmodule
