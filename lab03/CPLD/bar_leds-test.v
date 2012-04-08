
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

		parameter READ = 1'b1;
		parameter WRITE = 1'b0;
		parameter ENABLE = 1'b1;
		parameter DISABLE = 1'b0;

		// initialize
		#1;
		ce = DISABLE;
		//datar = 8'h00;
		datar = 8'bz;
		rwr = 1;

		// ### WRITE ###
		// IMPORTANT - Nothing else should be driving the bus or else
		// bad things could happen.
		#1 datar = 8'h4f; // start driving the outputs
		#1 rwr = WRITE;
		#1 ce = ENABLE;   // enable, triggers a write
		// value should have been written
		#1 ce = DISABLE;
		  datar = 8'hz;  // stop driving the outputs

		// ### READ ###
		#1 rwr = READ;
		#1 ce = ENABLE;
		// data should be ready
		#1 read_data = datar;
		#1 ce = DISABLE;

		$finish;
	end
endmodule

