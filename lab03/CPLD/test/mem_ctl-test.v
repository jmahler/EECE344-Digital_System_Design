
`include "../mem_ctl.v"

module test;

	reg         read_n,
                write_n,
                ce_n,
                clk;
	reg  [6:0]  address_bus;
	wire [7:0]  data_bus;

	wire [7:0]  mem_data;
	wire [16:0] mem_address;
	wire        ceh_n;
	wire        ce2;
	wire        we_n;
	wire        oe_n;

	mem_ctl mem1(read_n, write_n, ce_n, clk, address_bus, data_bus, mem_data,
                    mem_address, ceh_n, ce2, we_n, oe_n);

	reg [7:0] write_data_bus;
	assign data_bus = (~(ce_n | write_n | ~read_n)) ? write_data_bus : 8'bz;

    always
        #1 clk = ~clk;

	initial begin
		$dumpfile("mem_ctl-test.vcd");
		$dumpvars(0,test);

        clk = 1'b0;
        write_n = 1'b1;
        read_n = 1'b1;
        ce_n = 1'b1;
        address_bus = 7'h00;
        // (upper 9 bits are ignored, see mem_ctl.v)

        // The time scale is larger throughout this section
        // because it is assumed that the clock speed (clk)
        // is much larger.

        #1;

        // During a write cycle the data placed on the bus
        // should be seen driven to the mem_data output.

		// WRITE
		    write_data_bus = 8'h73;
            ce_n    = 1'b0; // enable
            write_n = 1'b0;

        #10;
        // disable
            ce_n    = 1'b1;
            write_n = 1'b1;


        // During a read cycle the data in mem_data should
        // be seen driven to the data_bus.
        //
        // IMPORTANT - To get this to work requires a temporary
        // modification of mem_ctl.v.  Look for the line
        // "used to test read cycle" in that file.

        #10;
        // READ
            read_n = 1'b0;
            ce_n   = 1'b0; // enable

        #10;
        // disable
            ce_n = 1'b1;
            write_n = 1'b1;

		#10 $finish;
	end

endmodule

// vim:foldmethod=marker
