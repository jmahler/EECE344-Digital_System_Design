/*
 * NAME
 * ----
 *
 *   ram
 *
 *
 * DESCRIPTION
 * -----------
 * 
 * Module for interfacing an Alliance AS6C1008 128x8 RAM chip.
 *
 * Only 7 address bits are made available.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */


module ram(
	input wire clk,
	input wire ce, 		// chip enable
	input wire [6:0] address,
	inout wire [7:0] data,
	input wire rw, 		// read = 1, write = 0  (control)
	// rest are external pins
	output wire [16:0] address_ext, // external ram address pins
	inout wire [7:0] data_ext, 		// external data pins
	output wire ce_l,  		// chip enable, active low
	output wire ce2,  		// chip enable
	output wire we_l, 		// write enable, active low
	output wire oe_l 		// output (read) enable, active low
	);

	// meaning for values of rw
	parameter READ  = 1'b1;
	parameter WRITE = 1'b0;

	// tie unused address bits low
	assign address_ext[16:7] = 0;

	assign address_ext[6:0] = address;

	reg [7:0] data_sample;

	// if read enabled, drive current data, otherwise go hi Z
	assign data = (ce == 1'b1 && rw == READ) ? data_ext : 8'bz;

	assign data_ext = data_sample;

	// Refer to the data sheet for the Alliance RAM for a description
	// of the timing requirements.

	// It is assumed that the data and address have already been
	// established.  The following just goes through the timing cycle.

	// ENABLED, perform a read or write
	always @(posedge ce) begin
		if (rw == WRITE) begin
			// WRITE CYCLE 1
			@(posedge clk)
				ce_l <= 1'b0;
				ce2  <= 1'b1;
			@(posedge clk)
				we_l <= 1'b0;
			repeat (4)
				@(posedge clk);
		end else begin
			// READ CYCLE 2
			@(posedge clk)
				ce_l <= 1'b0;
				ce2 <= 1'b1;
			@(posedge clk)
				oe_l <= 1'b0;
			repeat (2)
				@(posedge clk);
		end
	end

	always @(negedge ce) begin
		// DISABLE
		ce_l <= 1'b1;
		ce2  <= 1'b0;
		oe_l <= 1'b1;
	end

	/*
	// chip enable
	assign ce_l = ~ce;
	assign ce2 = ce;
	// read enable
	assign oe_l = (ce == 1'b1 && rw == READ) ? 1'b0 : 1'b1;
	// write enable
	assign we_l = (ce == 1'b1 && rw == WRITE) ? 1'b0 : 1'b1;
	*/

   /*
	always @(data) begin
		if (ce == 1'b1 && rw == WRITE)
			data_sample <= data;
	end
	*/
endmodule

