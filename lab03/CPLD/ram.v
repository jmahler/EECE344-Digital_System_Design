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
	input wire ram_ce, 		// chip enable
	input wire [6:0] ram_address,
	inout wire [7:0] ram_data,
	input wire ram_rw, 		// read = 1, write = 0  (control)
	// rest are external pins
	output wire [16:0] ram_address_ext, // external ram address pins
	inout wire [7:0] ram_data_ext, 		// external data pins
	output wire ce_l,  		// chip enable, active low
	output wire ce2,  		// chip enable
	output wire we_l, 		// write enable, active low
	output wire oe_l 		// output (read) enable, active low
	);

	// meaning for values of rw
	parameter READ  = 1'b1;
	parameter WRITE = 1'b0;

	assign ram_address_ext[16:7] = 0;
	assign ram_address_ext[6:0] = ram_address;

	reg [7:0] ram_data_sample;

	// tri-state data to/from the bus
	assign ram_data = (ram_ce == 1'b1 && ram_rw == READ) ? ram_data_ext : 8'bz;

	assign ram_data_ext = ram_data_sample;

	// chip enable
	assign ce_l = ~ram_ce;
	assign ce2 = ram_ce;
	// read enable
	assign oe_l = (ram_ce == 1'b1 && ram_rw == READ) ? 1'b0 : 1'b1;
	// write enable
	assign we_l = (ram_ce == 1'b1 && ram_rw == WRITE) ? 1'b0 : 1'b1;

	always @(posedge ram_rw) begin
		ram_data_sample <= ram_data;
	end
endmodule

