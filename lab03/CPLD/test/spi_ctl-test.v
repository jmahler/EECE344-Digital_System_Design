
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

		#1 nss = 0; // enabled


        // *** READ CYCLE #1 ***

		w_mosi = 8'hD5;  // READ
		SPI_once();

        // at this point look for the following states (using Gtkwave)
        //
        // s1.address_bus = 0x55
        // s1.rw = 1      // read
        // s1.read_n = 0  // enable read
        // s1.write_n = 1 // disable write
        // data_bus = 0xAA
        // r_reg = 0xAA  // loaded with data to write back

		w_mosi = 8'h33;  // form feed, value is ignored
		SPI_once();

        // s1.data_bus = 

		#1 nss = 1; // disabled

        // *** END READ CYCLE #1 ***


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
