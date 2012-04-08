
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

	// 8-bit commands received from SPI on spi_rx
	// (refer to main.v for a description of this value)
	parameter CMD_EMPTY = 8'h00;
	parameter CMD_RESET = 8'h01;
	parameter CMD_LOAD  = 8'h02;

	reg sclk;

	reg rst_l;
	reg ss_l;
	reg mosi;
	wire miso;
	wire [7:0] led_ext;
	wire [8:1] in_sw;

	main m1(rst_l, ss_l, sclk, mosi, miso, led_ext, in_sw);

	// data to be written to the slave
	reg [7:0] w_mosi;

	// The input switches define what the slave
	// will send to us, the master, on the miso line.
	// Due to board characteristics of the Lattice MachXO
	// the value is inverted.
	assign in_sw = ~(8'h80); // read 0x00

	reg [4:0] i;

	initial begin
		$dumpfile("output.vcd");
		$dumpvars(0,test);

		rst_l = 1; // not reset
		sclk = 0;  // CPOL = 0 -> start clock at 0
		mosi = 0;  // any default value

		// manually reset the SPI
		#1 rst_l = 0; // reset
		#1;
		#1 rst_l = 1;

		// This is needed for the slave since it loads its
		// write register when the sclk goes low while it is
		// disabled.
		//ss_l = 1; // disabled;
		//#1 sclk = 1;
		//#1 sclk = 0;
		//#1 ss_l = 0; // enabled;
		#1 ss_l = 1; // disabled;

		// start by sending CMD_EMPTY

		// read address 0x74, the switches
		w_mosi = 8'hF4;

		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###

		// do it a second time since the result is delayed
		// read address 0x00, MSB is read/write flag
		w_mosi = 8'hF4;

		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###


		// do it a second time since the result is delayed
		// read address 0x00, MSB is read/write flag
		w_mosi = 8'hF3;

		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###


		// do it a second time since the result is delayed
		// read address 0x00, MSB is read/write flag
		w_mosi = 8'hF4;

		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###



		// everything should be cleared/reset at this point

		/*
		w_mosi = CMD_LOAD;

		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###

		w_mosi = CMD_LOAD;
		*/
		/*
		w_mosi = 8'hff;  // some erroneous command
		// This should result in STATE_ERROR and RETURN_ERROR_UNKNOWN_CMD
		*/

	   /*
		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###
		*/


		/*
		w_mosi = CMD_LOAD;

		// ### SPI START ###
		//
		// enable SPI and assign the first value
		#1 ss_l = 0;
		 mosi = w_mosi[7];

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
			mosi = w_mosi[i];
		end
		#1 sclk = 1;

		#1 ss_l = 1; // disable
		   sclk = 0; // CPOL = 0
		// ### SPI END ###
*/



		#1 $finish;
	end
endmodule

