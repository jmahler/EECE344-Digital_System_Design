
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

        #1 reset_n = 0;
        #1 reset_n = 1;


		#1 nss = 0; // enabled

		//w_mosi = 8'h7F;  // WRITE invalid address
		w_mosi = 8'hFF;  // READ invalid address
		SPI_once();

		w_mosi = 8'hFF;  // form feed
		SPI_once();

		#1 nss = 1; // disabled

		#1 $finish;
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
