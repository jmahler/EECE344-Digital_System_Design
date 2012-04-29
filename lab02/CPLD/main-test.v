
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
module GSR(output wire GSR);
	assign GSR = 1;
	//GSR GSR_INST(.GSR(reset));
endmodule

module test;

	reg sclk;

	reg reset;
	reg SS_L;
	reg MOSI;
	wire MISO;
	wire [7:0] led_ext;
	wire [7:0] in_sw;

	main m1(reset, SS_L, sclk, MOSI, MISO, led_ext, in_sw);

	wire [7:0] mosi_val;
	assign mosi_val = 8'h4f;

	assign in_sw = 8'hb7;

	reg [4:0] i;

	initial begin
		$dumpfile("output.vcd");
		$dumpvars(0,test);

		/*
		 * This section generates a sequence of an SPI master.
		 * The value to be output is stored in 'mosi_val'.
		 *
		 * It outputs the MSB first and is defined with CPOL = 0 and CPHA = 0.
		 */

		reset = 0;  // not reset
		sclk = 0;  // CPOL = 0 -> start clock at 0
		MOSI = 0;

		// This is needed for the slave since it loads its
		// write register when the sclk goes low while it is
		// disabled.
		SS_L = 1; // disabled;
		#1 sclk = 1;
		#1 sclk = 0;
		#1 SS_L = 0; // enabled;

		MOSI = mosi_val[7];

		i = 7;
		repeat (7) begin
			i = i - 1;
			#1;
			// sample
			sclk = 1;
			#1;
			// propagate
			sclk = 0;
			MOSI = mosi_val[i];
		end

		#1 sclk = 1;

		#1;
		SS_L = 1; // disable
		sclk = 0;
		#1;

		$finish;
	end
endmodule

