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
`include "bar_leds.v"
`include "decoder.v"
`include "switches.v"
`include "ram.v"

module main(
	input wire rst_l,
	input wire ss_l,
	input wire sclk,
	input wire mosi,
	output wire miso,
	output wire [8:1] led_ext,
	input wire [8:1] in_sw,
	// ram chip
	output wire [16:0] ram_address_ext,
	inout wire [7:0] ram_data_ext,
	output wire ce_l,
	output wire ce2,
	output wire we_l,
	output wire oe_l 
	);


	// ### MODULE AND BUS DEFINITION ###

	// ADDRESS
	wire [8:1] addr;
	// main_addr is addr writeable by main
	reg [8:1] main_addr;
	assign addr = main_addr;

	// DATA
	wire [8:1] data;
	// reg for writing to data
	reg [8:1] main_data;
	assign data = main_data;

	// CONTROL
	wire [5:1] enable;  // chip enable

	wire rw; // read = 1, write = 0
	parameter READ = 1'b1;
	parameter WRITE = 1'b0;
	// reg for writing to rw wire
	reg main_rw;
	assign rw = main_rw;

	GSR GSR_INST(.GSR(rst_l));

	wire [8:1] main_spi_rx; // data received from master
	wire [8:1] main_spi_tx;  // data to transmit to master
	SPI_slave SPI_slave1(rst_l, ss_l, sclk, mosi, miso, main_spi_rx, main_spi_tx);

	decoder decoder1(addr, enable);

	bar_leds bar_leds1(enable[2], data, rw, led_ext);

	switches switches1(enable[1], data, rw, in_sw);

	//ram ram2(enable[3], data, address, rw);

	ram ram1(enable[5], addr, data, rw, ram_address_ext, ram_data_ext, ce_l, ce2, we_l, oe_l);


	wire [8:1] main_next_addr;
	assign main_next_addr = {1'b0, main_spi_rx[7:1]};

	// ### MAIN ###

	assign main_spi_tx = data;

	// keep track of the read/write changes
	// so we can see two writes (addr, data)
	reg main_last_rw;
	always @(main_spi_rx) begin
		main_last_rw <= main_rw;
	end
	reg [8:1] pre_addr;

	// anytime new data is received
	//always @(main_spi_rx) begin
	always @(negedge ss_l) begin
		if (main_spi_rx[8] == WRITE) begin
			if (main_last_rw == WRITE) begin
				// second transaction, get data
				main_data <= main_spi_rx;
				main_addr <= pre_addr;  // trigger the chip enable
			end else begin
				// first transaction, gets the address
				main_rw  <= main_spi_rx[8];
				pre_addr <= main_next_addr;
			end
		end else begin
			// READ

			main_data <= 8'bz;  // don't drive the outputs
			main_rw   <= main_spi_rx[8];
			main_addr <= main_next_addr;
		end
	end
endmodule
