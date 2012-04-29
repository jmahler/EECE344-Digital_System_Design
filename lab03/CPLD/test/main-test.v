
`include "../main.v"

// GSR is a module provide by Diamond for the MachXO
// Here we create a pseudo one that just never causes
// a reset.
module GSR(output GSR);
    assign GSR = 1'b1;
endmodule

module OSCC(output reg OSC);
    initial begin
        OSC = 0;
    end

    always begin
        #1 OSC = ~OSC;
    end
endmodule

module test;

    reg           sck,
                  nss,
                  mosi,
                  reset_n;
    wire          miso;
    wire   [16:0] mem_address;
    wire   [7:0]  mem_data;
    wire          mem1_ceh_n,
                  mem1_ce2,
                  mem1_we_n,
                  mem1_oe_n,
                  mem2_ceh_n,
                  mem2_ce2,
                  mem2_we_n,
                  mem2_oe_n;
    wire   [7:0]  board_leds,
                  bar_leds;
    reg    [7:0]  switches;

    main m1(sck, nss, mosi, reset_n, miso, mem_address,
            mem_data, mem1_ceh_n, mem1_ce2, mem1_we_n,
            mem1_oe_n, mem2_ceh_n, mem2_ce2, mem2_we_n,
            mem2_oe_n, board_leds, bar_leds, switches);

	// data to be written to the slave
	reg [7:0] w_mosi;

	reg [4:0] i;

	initial begin
		$dumpfile("main-test.vcd");
		$dumpvars(0,test);

        w_mosi = 8'h00;
        nss = 1;
        sck = 0;

        // The time delays in this section are slower (#10)
        // relative to the OSC clock (#1).
        // On a real board the magnitudes would be much larger
        // (kHz to MHz) so this is a worst case situation.
        // Currently this is only important for the memory modules.

        // *** EXAMPLE #1, read switches ***
        switches = 8'h0F;

        #10 nss = 0;

        //
        // At the END of the first byte:
        //
        //  read_n = 0, ce_n = 0  (enabled)
        //
        //  data = 0x0F  (value of switches)
        //

        // address of switches (0x74), read (0x80)
        w_mosi = 8'h74 | 8'h80;
        SPI_once();

        //
        // For the second byte the value read from the
        // switches (0x0F) should be seen transferred
        // across the miso pin.
        //

        w_mosi = 8'h00; // form feed, can be any value
        SPI_once();

        #10 nss = 1;

        // *** END EXAMPLE #1 ***

        #10 $finish;
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
			#10;
			// sample
			sck = 1;
			#10;
			// propagate
			sck = 0;
			mosi = w_mosi[i];
		end
		#10 sck = 1;
		#10 sck = 0; // CPOL = 0

		end
	endtask
    // }}}

endmodule



