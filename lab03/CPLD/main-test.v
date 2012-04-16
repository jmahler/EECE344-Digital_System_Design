
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

	wire [16:0] ram_address_ext;
	wire [7:0] ram_data_ext;

    // bitmask to set the READ bit (MSB)
    parameter READ = 8'h80;
    // for WRITE, just leave it clear

	main m1(rst_l, ss_l, sclk, mosi, miso, led_ext, in_sw, ram_address_ext, ram_data_ext, ce_l, ce2, we_l, oe_l);

	// data to be written to the slave
	reg [7:0] w_mosi;

	// The input switches define what the slave
	// will send to us, the master, on the miso line.
	// Due to board characteristics of the Lattice MachXO
	// the value is inverted.
	assign in_sw = ~(8'h55); // read 0x00

	reg [4:0] i;

	initial begin
		$dumpfile("output.vcd");
		$dumpvars(0,test);

		rst_l = 1; // not reset
		sclk = 0;  // CPOL = 0 -> start clock at 0
		mosi = 0;  // any default value
		ss_l = 1;  // disabled


		// How to sync up?
		// Two commands are used on the SPI,
		// COMMAND: <rw><address>
		// DATA: <data>
		// But it is necessary to know how the
		// next command will be interpreted.
		//
		// To do this, write to some invalid address,
		// then examine spi_tx for 8'hDD or 8'hCC.
		// For 8'hCC, the next transaction will be a COMMAND,
		// and similarly for DATA.

		// (it will take a few transactions to clear out the invalid data)

		w_mosi = 8'h7F;  // WRITE invalid address
		SPI_once();

		w_mosi = 8'h7F;
		SPI_once();
		// spi_tx == 8'hDD;  // next is DATA

		w_mosi = 8'h7F;
		SPI_once();

		// spi_tx == 8'hCC;  // next is COMMAND



		// read from switches
		// read address 0x74 (the switches)
		// COMMAND
		w_mosi = 8'h74 | READ;
		SPI_once();

        // form feed
		// DATA
		w_mosi = 8'hFF;
		SPI_once();

		/*
		w_mosi = 8'h74 | READ;
		SPI_once();

		w_mosi = 8'hFF;
		SPI_once();
		*/

        // It should take two cycles to clear out
        // the unknowns in the SPI shift registers.
		//w_mosi = 8'h74 | READ;
		//SPI_once();
		//w_mosi = 8'hFF;
		//SPI_once();
        // result should be on the data line

        // "form feed", uses an impossible address
		//w_mosi = 8'hFF;
		//SPI_once();

		//w_mosi = 8'h74 | READ;
		//SPI_once();


		// read address 0x74 (the switches)
		//w_mosi = 8'h74 | READ;
		//SPI_once();

        // form feed
		//w_mosi = 8'hFF;
		//SPI_once();


        // the bar LEDs start with an unknown value,
        // so they must be written first

        /*
        // write, address
		w_mosi = 8'h6C;
		SPI_once();

        // write, data
		//w_mosi = 8'h73;
		w_mosi = 8'h00;
		SPI_once();

        // form feed
		w_mosi = 8'hFF;
		SPI_once();
        // at this point 'data' and 'cur_leds' should have the data value
        */

        /*
        // read back the data
        w_mosi = 8'h6C | READ;
		SPI_once();

		w_mosi = 8'hFF;
		SPI_once();
        */

        // form feed
		//w_mosi = 8'hFF;
		//SPI_once();
		//w_mosi = 8'hFF;
		//SPI_once();

		//w_mosi = 8'hFF;
		//SPI_once();

        /*
		w_mosi = 8'h6C;
		SPI_once();
		w_mosi = 8'h6C;
		SPI_once();
		w_mosi = 8'h6C;
		SPI_once();
        */

//		w_mosi = 8'h6C;
//		SPI_once();

//		w_mosi = 8'hFF;
//		SPI_once();

		// read address 0x6C (bar leds)
//		w_mosi = 8'h6C | READ;
//		SPI_once();

       // form feed
//		w_mosi = 8'hFF;
//		SPI_once();

       // form feed
//		w_mosi = 8'hFF;
//		SPI_once();

		#1 $finish;
	end

    // {{{ SPI_once() 
	/*
     * SPI_once()
     *
     * This Verilog "task" is used to run a single SPI
     * transaction.
     *
     * It modifies the global variables: ss_l, mosi, sclk
     * And it writes to mosi whatever value is in w_mosi.
     */
	task SPI_once;
		begin
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
		#1 sclk = 0; // CPOL = 0

		#1 ss_l = 1; // disable
		end
	endtask
    // }}}

endmodule

// vim:foldmethod=marker
