/*
 * NAME
 * ----
 *
 *   decoder - specialized decoder
 *
 * DESCRIPTION
 * -----------
 *
 * This is a specialize 8 to 5 decoder designed
 * to map the following addresses.
 *
 *    address (hex) | output   |   device
 *  ----------------+----------+-------------------
 *   0x7F           |   00000  |  (reserved)
 *   0x74           |   00001  |  switches
 *   0x6C           |   00010  |  bar LEDs
 *   0x50 - 0x5F    |   00100  |  RAM 2
 *   0x2F           |   01000  |  CPLD LEDs
 *   0x00 - 0x0F    |   10000  |  RAM 1
 *   (default)      |   00000  |  (none)
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module decoder(
	input wire [6:0] addr, // address
	output wire [4:0] enable);

	assign enable = (addr == 8'h74) ? 5'b00001 :
                  (addr == 8'h6c) ? 5'b00010 :
                  (addr >= 8'h50 && addr <= 8'h5F) ? 5'b00100 :
                  (addr == 8'h2f) ? 5'b01000 :
                  (addr >= 8'h00 && addr <= 8'h0F) ? 5'b10000 :
                  5'b00000; // default
endmodule
