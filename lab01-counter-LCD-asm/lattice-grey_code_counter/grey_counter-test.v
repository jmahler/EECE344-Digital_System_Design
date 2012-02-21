
`include "grey_counter.v"

module test;
	reg clk;
	wire [7:0] count;

	grey_counter gc(clk, count);

	initial begin
		//$dumpfile("output.vcd");
		//$dumpvars(0,test);

		$monitor ("%b %t", count, $time);

		// initialize
		clk = 1;

		// C:\DOS  C:\DOS\RUN  RUN\DOS\RUN
		#512;
		// it take 2 clock ticks for a change
		// so we have to wait twice as long (256 * 2 = 512)

		$finish;
	end

	always begin
		#1 clk = ~clk;
	end

endmodule
