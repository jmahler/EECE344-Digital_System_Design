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
 *    address (hex) | output (binary)
 *  ---------------------------------
 *   0x74           |   00001
 *   0x6C           |   00010
 *   0x50 - 0x5F    |   00100
 *   0x2F           |   01000
 *   0x00 - 0x0F    |   10000
 *   (default)      |   00000
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module decoder(
	input wire [8:1] A, // address
	output wire [5:1] O); // output

	assign O =  (A == 8'h74) ? 5'b00001 :
                (A == 8'h6c) ? 5'b00010 :
                (A >= 8'h50 && A <= 8'h5F) ? 5'b00100 :
                (A == 8'h2f) ? 5'b01000 :
                (A >= 8'h00 && A <= 8'h0F) ? 5'b10000 :
                5'b00000;
endmodule
