
`include "../decoder.v"

module test;

    reg [6:0] address;

    wire bar_led_ce_n,
         board_led_ce_n,
         switch_ce_n,
         mem1_ce_n,
         mem2_ce_n;

	decoder d1(address,
        bar_led_ce_n,
        board_led_ce_n,
        switch_ce_n,
        mem1_ce_n,
        mem2_ce_n);

	initial begin
		$dumpfile("decoder-test.vcd");
		$dumpvars(0,test);

        // go through all the possible addresses
        #1 address = 7'h00;
        while (! (address == 7'h7F))
            #1 address = address + 1;

        $finish;
	end

endmodule

// vim:foldmethod=marker
