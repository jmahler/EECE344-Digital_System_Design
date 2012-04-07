
/*
 * NAME
 * ----
 * 
 *  main-test - test module for 'main'
 *
 * INTRODUCTION
 * ------------
 *
 * This module acts as an SPI master to test the main.v
 * module which behaves as an SPI slave.
 * 
 * Currently this module just sends data to the slave and
 * discards what is returned.  But this is still useful
 * for making sure that the slave is sending the bits on
 * the correct clock edge.
 *
 * This can be useful as a sanity check of the changes which
 * are made to main.v.  But running on a CPLD or FPGA has its
 * own set of problems which may not be shown by this test.
 *
 * It is configured to produce an output file suitable for Gtkwave.
 *
 * If things aren't working properly here are some things to look for.
 *
 *  - Make sure the signal is stable on sampling edges (posedge sclk)
 *
 *  - The first bit out should be MSB and it should end with the LSB
 *
 *  - Check the values at each sampling edge and make sure they
 *    agree with the expected value.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

`include "main.v"

// Reset used in Lattice MachXO CPLD
// Defined the module here to never reset.
module GSR(input wire GSR);
	//assign GSR = 1;
	//GSR GSR_INST(.GSR(reset));
endmodule

module test;

	reg sclk;

	reg rst_l;
	reg ss_l;
	reg mosi;
	wire miso;
	wire [7:0] led_ext;
	wire [7:0] in_sw;

	main m1(rst_l, ss_l, sclk, mosi, miso, led_ext, in_sw);

	// The mosi_val defines what is sent to the slave
	// on the mosi line.
	wire [7:0] mosi_val;
	assign mosi_val = 8'h4f;

	// The input switches define what the slave
	// will send to us, the master, on the miso line.
	// Due to board characteristics of the Lattice MachXO
	// the value is inverted.
	assign in_sw = ~(8'hb7);

	reg [4:0] i;

	initial begin
		$dumpfile("output.vcd");
		$dumpvars(0,test);

		/*
		 * This section generates a sequence as an SPI master.
		 * The value to be output is defined in 'mosi_val'.
		 *
		 * It outputs the MSB first and is defined with CPOL = 0 and CPHA = 0.
		 */

		rst_l = 1; // not reset
		sclk = 0;  // CPOL = 0 -> start clock at 0
		mosi = 0;  // any default value

		// This is needed for the slave since it loads its
		// write register when the sclk goes low while it is
		// disabled.
		ss_l = 1; // disabled;
		#1 sclk = 1;
		#1 sclk = 0;
		#1 ss_l = 0; // enabled;

		// We are ready to perform a full 8-bit cycle

		// assign the first value
		mosi = mosi_val[7];

		// and finish the remaining 7 bits
		i = 7;
		repeat (7) begin
			i = i - 1;
			#1;
			// sample
			sclk = 1;
			#1;
			// propagate
			sclk = 0;
			mosi = mosi_val[i];
		end
		#1 sclk = 1;

		// At this point, the master has sampled all its points.
		// The slave has sampled all as well, but another propagate
		// is needed to shift the register one more time.
		// This can be done while it is disabled (ss_l = 1).

		#1 ss_l = 1; // disable
		#1 sclk = 0; // CPOL = 0
		#1;

		$finish;
	end
endmodule

