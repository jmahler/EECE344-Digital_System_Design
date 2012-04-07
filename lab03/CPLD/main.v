/*
 * NAME
 * ----
 *
 *   main.v - TODO
 *
 * DESCRIPTION
 * -----------
 *
 * TODO
 *  
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

`include "SPI_slave.v"

module main(
	input wire rst_l,
	input wire ss_l,
	input wire sclk,
	input wire mosi,
	output wire miso,
	output wire [7:0] led_ext,
	input wire [7:0] in_sw
	);

	GSR GSR_INST(.GSR(rst_l));

	wire [7:0] n_in_sw;
	assign n_in_sw = ~(in_sw);  // negated in_sw

	SPI_slave SPI_slave1(rst_l, ss_l, sclk, mosi, miso, led_ext, n_in_sw);
endmodule
