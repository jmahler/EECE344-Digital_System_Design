
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
        switches = 8'hAA; // manually specify the value
                          // we should read this value

        // should see:
        //   data == high Z

        // enable
        #1 ce_n = 1'b0;
        #1 read_n = 1'b0;

        // should see:
        //   sw1.data == ~(0xAA) -> 0x55

        // disable
        #1 ce_n = 1'b1;
           read_n = 1'b1;

        // should see:
        //   data == high Z

        #1 $finish;
	end

endmodule

