
/*
 * NAME
 * ----
 * 
 *  bar_leds-test.v - test module for 'bar_leds.v'
 *
 * INTRODUCTION
 * ------------
 *
 * TODO
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

`include "bar_leds.v"

module test;

	wire ce_l;
	wire [8:1] data;
	wire rw;
	wire [8:1] leds;

	bar_leds bar_leds1(ce_l, data, rw, leds);

	// registers for assigning to wires
	reg ce_lr;
	assign ce_l = ce_lr;

	reg rwr;
	assign rw = rwr;

	reg [8:1] datar;
	assign data = datar;

	reg read_data;

	initial begin
		$dumpfile("output.vcd");
		$dumpvars(0,test);

		#1;
		ce_lr = 1'b1;  // disable
		//datar = 8'h00;
		datar = 8'bz;
		rwr = 1;

		// write
		#1 datar = 8'h4f;
		#1 rwr = 0;
		#1 ce_lr = 1'b0;  // enable

		#1 ce_lr = 1'b1;  // disable

		// read
		#1 rwr = 1;
		#1 ce_lr = 1'b0;  // enable
		#1 ce_lr = 1'b1;  // disable

		#1 read_data = datar;

		#1 ce_lr = 1'b1;  // disable
		$finish;
	end
endmodule

