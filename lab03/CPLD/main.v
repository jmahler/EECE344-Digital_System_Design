/*
 * NAME
 * ----
 *
 *   main.v
 *
 * DESCRIPTION
 * -----------
 *
 * This module has serveral functions.
 * It creates the wires which defines the "bus".
 * It instantiates the modules which are connected to the bus.
 * And it controls the inteface between SPI and the bus.
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
	// external leds
	output wire [7:0] led_ext,
	// input switches
	input wire [7:0] in_sw,
	// ram chip
	output wire [16:0] ram_address_ext,
	inout wire [7:0] ram_data_ext,
	output wire ce_l,
	output wire ce2,
	output wire we_l,
	output wire oe_l 
	);


	// ### BUS DEFINITION ###

	// ADDRESS
	wire [6:0] addr;
	reg [6:0] latch_addr;
	assign addr = latch_addr;

	// DATA
	wire [7:0] data;

	// CONTROL
	wire [4:0] enable;  // chip enable, controlled by decoder

	wire rw; // read = 1, write = 0
	parameter READ = 1'b1;
	parameter WRITE = 1'b0;


	// ### MODULES ###

	GSR GSR_INST(.GSR(rst_l));

	wire [7:0] spi_rx; // data received from master
	reg [7:0] spi_tx;  // data to transmit to master
	SPI_slave SPI_slave1(ss_l, sclk, mosi, miso, spi_rx, spi_tx);

	decoder decoder1(addr, enable);

	// Every module has a common interface consisting of
	// (enable, data and rw).  Additional pins can be added
	// if they need to connect externally and these should
	// also be added to main (above).
	// The addr is controlled in this module and triggers the enable.

	bar_leds bar_leds1(enable[1], data, rw, led_ext);
	switches switches1(enable[0], data, rw, in_sw);
	ram ram1(clk, enable[4], addr, data, rw, ram_address_ext, ram_data_ext, ce_l, ce2, we_l, oe_l);
	//ram ram2(enable[3], data, address, rw);


	// ### MAIN ###

	// value of the next address, excluding the rw bit
	wire [7:0] next_addr;
	assign next_addr = {1'b0, spi_rx[6:0]};

	reg [7:0] latch_data;
	reg latch_rw;
	assign rw = latch_rw;

	// If the command is a write, drive data, otherwise set to high Z
	assign data = (latch_rw == WRITE) ? latch_data : 8'bz;

	always begin
		// COMMAND received at end of SPI transaction
		@(posedge ss_l) begin
			// these will trigger the chip enable so data can
			// be read, but there may be a delay before it is ready
			latch_addr <= next_addr;
			latch_rw   <= spi_rx[7];
			spi_tx <= 8'hDD; // marker, DATA next
		end
		// start of next transaction, setup the data
		@(negedge ss_l) begin
			spi_tx <= data;
		end
		// TODO - (for RAM) don't set enable until the address and the
		// data are ready.
		// DATA received at end of SPI transaction
		@(posedge ss_l) begin
			if (latch_rw == WRITE) begin
				latch_data <= spi_rx;
				spi_tx <= 8'hCC; // marker, COMMAND next
			end
			// (READ) spi_tx is transmitted back
		end
	end
endmodule
