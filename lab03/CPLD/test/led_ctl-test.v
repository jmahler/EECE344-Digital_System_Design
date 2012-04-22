
`include "../led_ctl.v"

module test;

    reg        read_n;
    reg        write_n;
    reg        reset_n;
    reg        ce_n;
    wire [7:0] data;
    wire [7:0] leds;

    reg [7:0] write_data;
    assign data = (~(write_n)) ? write_data : 8'bz;

	led_ctl led1(read_n, write_n, reset_n, ce_n, data, leds);


	initial begin
		$dumpfile("led_ctl-test.vcd");
		$dumpvars(0,test);

        // start disabled
        ce_n = 1'b1;
        read_n = 1'b1;
        write_n = 1'b1;
        reset_n = 1'b1;
        write_data = 8'hAA;

        // reset
        #1 reset_n = 1'b0;
        #1 reset_n = 1'b1;

        // read cycle
        #1 ce_n = 1'b0;
        #1 read_n = 1'b0;

        #1 ce_n = 1'b1;
        #1 read_n = 1'b1;

        // write cycle
        #1 write_data = 8'hBB;
        #1 write_n    = 1'b0;
        #1 ce_n       = 1'b0;

        #1 write_n    = 1'b1;
        #1 ce_n       = 1'b1;

        #1;

        $finish;
	end

endmodule

