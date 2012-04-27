
`include "../spi_ctl.v"

module test;

	reg nss;
	reg mosi;
	reg sck;
	wire miso;
	reg reset_n;
    wire [6:0] address_bus;
    wire [7:0] data_bus;
    wire read_n;
    wire write_n;

    spi_ctl s1(nss, mosi, sck, miso, reset_n, address_bus, data_bus, read_n, write_n);

    // There are no devices connected to the bus for this test
    // bench so here we use write_data_bus to drive the bus
    // when read cycle is enabled.
    reg [7:0] write_data_bus;
    assign data_bus = (~read_n) ? write_data_bus : 8'bz;

	// data to be written to the slave
	reg [7:0] w_mosi;

	reg [4:0] i;

	initial begin
		$dumpfile("spi_ctl-test.vcd");
		$dumpvars(0,test);

		sck     = 0;
		reset_n = 1; // enabled
		mosi    = 0;
		nss     = 1;  // disabled

        // This value will be read during a read from the bus.
        // Used along with the assign = data_bus above.
        write_data_bus = 8'hAA;
        //write_data_bus = 8'h53;  // 0 1 0 1  0 0 1 1

        #2;

        #1 reset_n = 0;
        #1 reset_n = 1;

        /*
         * Given below are examples of a read cylcle and a write cycle.
         * Either or both can be uncommented to test their functionality.
         * Each section contains comments that describe what
         * values to look for (in Gtkwave) if it is operating properly.
         */

        // *** EXAMPLE #1: WRITE CYCLE ***

		#1 nss = 0; // enabled

        //
        // At the START of the FIRST byte you should see the following:
        //
        // both 'read_n' and 'write_n' high.
        //
        // At the END of the FIRST byte you should see the following:
        //
        // both 'read_n' and 'write_n' high.
        //
        // At the END of the SECOND byte you should see the following:
        //
        // 'read_n' high, 'write_n' LOW
        //
        // The value to be written (0xF3 in this example) driven
        // to the data bus.
        //
        // And finally when NSS goes high (disabled) both 'read_n'
        // and 'write_n' should go high (disabled).
        // And the data bus should go high z.
        //
		w_mosi = 8'h01; // WRITE address 0x01
		SPI_once();

		w_mosi = 8'hF3;  // value to be written
		SPI_once();

		#1 nss = 1; // disabled

        // *** END EXAMPLE #1 ***

        // *** EXAMPLE #2: READ CYCLE ***

		#1 nss = 0; // enabled

        // What to look for?
        //
        // Refer to the figure in the documentation (doc/)
        // title "Timing diagram of SPI read cycle".
        // This should approximately match that diagram.
        //
        // At the START of the first byte you should see the following:
        //
        // 'count' set to 1 at the first SAMPLE edge of sck
        //
        // At the END of the first byte should see the following:
        //
        // The address should be on the 'address_bus'.
        // In this case 0x85 (read 0x05) would result in 0x05
        // If 0x84 was sent 0x04 would result.
        //
        // The value to read (in this case 0xAA in write_data_bus) should
        // be on the 'data_bus'.
        //
        // 'rw' should be 1 for a read
        //
        // 'read_n' should go low (enabled) during the sample when
        // count changes from 7 to 8.
        //
        // 'write_n' should remain high (disabled.
        //
		//w_mosi = 8'hD5;  // READ address 0x55
		w_mosi = 8'h85;    // READ address 0x05
		//w_mosi = 8'h84;
		SPI_once();

        //
        // During the second cycle the MISO should reflect
        // the value transferred to the master.
        // (this value is not stored in this test bench so
        // it is not easy to view).
        // For example, if r_reg is loaded with 0xAA (change this
        // value using 'write_bus_data'), the follwing values
        // should be seen on the MISO pin during each SPI sample
        // (remember that 0xA == 1010_b).
        //
        //       t=n     t=(n+A)  (n+A > n)
        // ---------------------
        // MISO  1 0 1 0 1 0 1 0
        //

		w_mosi = 8'h33;  // form feed, value is ignored
		SPI_once();

		#1 nss = 1; // disabled

        // *** END EXAMPLE #2 ***

		#3 $finish;
	end

    // {{{ SPI_once() 
	/*
     * SPI_once()
     *
     * Perform a single 8-bit SPI cycle.
     *
     * It mutates the global variables: mosi, sck
     * And it writes to mosi whatever value is in w_mosi.
     *
     * It does not mutate nss, this is left to the controlling
     * block.
     */
	task SPI_once;
		begin
		// enable SPI and assign the first value
		 mosi = w_mosi[7];

		// and finish the remaining 7 bits
		i = 7;
		repeat (7) begin
			i = i - 1;
			#1;
			// sample
			sck = 1;
			#1;
			// propagate
			sck = 0;
			mosi = w_mosi[i];
		end
		#1 sck = 1;
		#1 sck = 0; // CPOL = 0

		end
	endtask
    // }}}

endmodule

// vim:foldmethod=marker
