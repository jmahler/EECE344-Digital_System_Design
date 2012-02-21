/*
 * NAME
 * ----
 * 
 * 8-bit grey code generator
 * 
 * DESIGN
 * ------
 * 
 * There are two main components to this counter.
 * 
 * The first is the special cases at the start of
 * each sequence.  The first bit changes at sequence 1,
 * second at 2, third at 4, etc.
 * 
 * The second is the repeating sequence after the
 * special cases.
 * The first bit changes every 2 bits, the second
 * every 4, the third every 8, fourth every 16, etc.
 * (Do you see a pattern yet?)
 * 
 * The modulo operator is used by subtracting the offset
 * and checking if the required number of numbers has
 * changed.
 * 
 * This design could be easily expanded to any number of bits.
 */

module grey_counter(input clk, output reg [7:0] count);
	integer n;

	always @(posedge clk) begin
		if (0 == n) begin
			count <= 8'b00000000;
			n = 0;
		end
		else if (1 == n)
			count[0] <= 1;
		else if (2 == n)
			count[1] <= 1;
		else if (4 == n)
			count[2] <= 1;
		else if (8 == n)
			count[3] <= 1;
		else if (16 == n)
			count[4] <= 1;
		else if (32 == n)
			count[5] <= 1;
		else if (64 == n)
			count[6] <= 1;
		else if (128 == n)
			count[7] <= 1;
		else if (0 == (n - 1) % 2)
			count[0] <= ~count[0];
		else if (0 == (n - 2) % 4)
			count[1] <= ~count[1];
		else if (0 == (n - 4) % 8)
			count[2] <= ~count[2];
		else if (0 == (n - 8) % 16)
			count[3] <= ~count[3];
		else if (0 == (n - 16) % 32)
			count[4] <= ~count[4];
		else if (0 == (n - 32) % 64)
			count[5] <= ~count[5];
		else if (0 == (n - 64) % 128)
			count[6] <= ~count[6];
		else if (0 == (n - 128) % 256)
			count[7] <= ~count[7];
		else begin
			count <= 8'b00000000;
			n = 0;
		end

		// next count or reset
		if (n >= 255)
			n <= 0;
		else
			n <= n + 1;
	end
endmodule
