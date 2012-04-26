
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

    // For a read, drive something on to the device so something
    // is actually read (since there are no devices on the bus).
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

        #2;

        #1 reset_n = 0;
        #1 reset_n = 1;

        // *** EXAMPLE #2: WRITE CYCLE ***

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
		w_mosi = 8'h01; // WRITE address 0x01
		SPI_once();

		w_mosi = 8'hF3;  // value to be written
		SPI_once();

		#1 nss = 1; // disabled

        // *** END EXAMPLE #2 ***

        // *** EXAMPLE #1: READ CYCLE ***

		#1 nss = 0; // enabled

        // What to loof for?
        //
        // Refer to the figure in the documentation (doc/)
        // title "Timing diagram of SPI".
        // This should approximately match that diagram.
        //
        //
        // At the START of this transaction you should see the following:
        //
        // 'count' set to 1 at the first SAMPLE edge of sck
        //
        // At the END of this transaction you should see the following:
        //
        // The address should be on the 'address_bus'.
        // In this case 0x85 (read 0x05) would result in 0x05
        // on the 'address_bus'.
        //
        // The value to read (in this case 0xAA from above) should
        // be on the 'data_bus'.
        //
        // 'rw' should be 1 for a read
        //
        // 'read_n' should go low to start a read
        //
		//w_mosi = 8'hD5;  // READ address 0xD5
		//w_mosi = 8'h85;  // READ address 0x85
		w_mosi = 8'h84;  // READ address 0x85
		SPI_once();


		w_mosi = 8'h33;  // form feed, value is ignored
		SPI_once();

		#1 nss = 1; // disabled

        // *** END EXAMPLE #1 ***


		#3 $finish;
	end

    // {{{ SPI_once() 
	/*
     * SPI_once()
     *
     * This Verilog "task" is used to run a single SPI
     * transaction.
     *
     * It modifies the global variables: nss, mosi, sck
     * And it writes to mosi whatever value is in w_mosi.
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
