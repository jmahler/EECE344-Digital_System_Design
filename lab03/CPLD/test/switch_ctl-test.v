
`include "../switch_ctl.v"

module test;

    reg        read_n;
    reg        ce_n;
    wire [7:0] data;
    reg  [7:0] switches;

	switch_ctl sw1(read_n, ce_n, data, switches);

	initial begin
		$dumpfile("switch_ctl-test.vcd");
		$dumpvars(0,test);

        // start disabled
        ce_n = 1'b1;
        read_n = 1'b1;
        switches = 8'hAA;

        #1;

        // For all these various combinations of enable/disable
        // data should only be driven when both ce_n and read_n are low.

        // enable
        #1 ce_n = 1'b0;
        #1 read_n = 1'b0;

        // disable
        #1 ce_n = 1'b1;
        #1 read_n = 1'b1;

        // enable in different order
        #1 read_n = 1'b0;
        #1 ce_n = 1'b0;

        // disable
        #1 ce_n = 1'b1;
           read_n = 1'b1;

        #1 read_n = 1'b0;
           ce_n = 1'b0;

        // disable
        #1 ce_n = 1'b1;
           read_n = 1'b1;

        $finish;
	end

endmodule

