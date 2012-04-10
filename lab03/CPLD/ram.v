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
	// reset are external chip pins
	output wire [16:0] ram_address_ext, // external ram address pins
	input wire [7:0] ram_data_ext, 		// external data pins
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

	//reg [7:0] sample_ram_data;

	assign ram_data = (ram_ce == 1'b1 && ram_rw == READ) ? ram_data_ext : 8'bz;

	//assign ce_l = ~ram_ce;
	assign ce_l = 1'b0;

	//assign ce2 = ram_ce;
	assign ce2 = 1'b1;

	//assign oe_l = (ram_ce == 1'b1 && ram_rw == READ) ? 1'b0 : 1'b1;
	assign oe_l = 1'b0;

	//assign we_l = (ram_ce == 1'b1 && ram_rw == WRITE) ? 1'b0 : 1'b1;
	assign we_l = 1'b1;

	// always @(disabled -> enabled)
//	always @(posedge ram_ce) begin
//		if (ram_rw == READ) begin
//			sample_ram_data <= ram_data_ext;
//		end
//	end
endmodule

