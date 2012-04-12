
/*
 * NAME
 * ----
 * 
 *  main-test - test module for 'main'
 *
 * INTRODUCTION
 * ------------
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

`include "ram.v"

module test;

	reg ram_ce;
	reg [6:0] ram_address;
	wire [7:0] ram_data;
	reg ram_rw;
	wire [16:0] ram_address_ext;
	wire [7:0] ram_data_ext;
	wire ce_l;
	wire ce2;
	wire we_l;
	wire oe_l;

	ram ram1(ram_ce, ram_address, ram_data, ram_rw, ram_address_ext, ram_data_ext, ce_l, ce2, we_l, oe_l);

	parameter READ  = 1'b1;
	parameter WRITE = 1'b0;

	//reg [7:0] w_ram_data_ext;
	//assign ram_data_ext = w_ram_data_ext;

	reg [7:0] w_ram_data;
	assign ram_data = (~ce_l && ~we_l) ? w_ram_data : 8'bz;

	initial begin
		$dumpfile("output.vcd");
		$dumpvars(0,test);

		#1 ram_ce = 1;  // enable

		// WRITE
		#1 w_ram_data = 8'h73;
		#1 ram_rw = WRITE;

		// READ
		#1 ram_rw = READ;
		#1 ram_ce = 1;  // enable

		#1 ram_ce = 0;  // disable
		#1 ram_ce = 1;  // enable

		// WRITE
		#1 w_ram_data = 8'hbf;
		#1 ram_rw = WRITE;
		//#1 ram_rw = READ;

		#1 ram_ce = 0;  // disable

		#1 $finish;
	end

endmodule

// vim:foldmethod=marker
