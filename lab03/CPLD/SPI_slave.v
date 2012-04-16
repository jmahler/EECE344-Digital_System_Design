/*
 * NAME
 * ----
 *
 *   SPI_slave.v - SPI slave
 *
 * DESCRIPTION
 * -----------
 *
 * This module acts as an SPI slave.
 * When ss_l goes low it is enabled.
 * And for each rising edge of sclk it samples a value (mosi)
 * and on each falling edge it propagates the received value
 * and updates the miso value.
 * The data it outputs is defined by 'spi_tx'.
 * And the data it receives is stored in 'spi_rx'.
 *
 * The following SPI settings used by this module:
 *
 *   MSB first
 *   CPOL = 0
 *   CPHA = 0
 *   SS_L (enable on low)
 *
 * The following describes the required signals in general.
 * Notice that the SS_L transitions after the SCLK has stopped.
 * This is also configuration specific with CPOL=0 and CPHA=0.
 *
 *        --+                            +--
 *  SS_L    |___________ ... ____________|
 *            +--+  +--+     +--+  +--+
 *  SCLK  ____|  |__|  | ... |  |__|  |_____
 *
 *
 * AUTHOR
 * ------
 *
 *   Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module SPI_slave(
	input wire ss_l,
	input wire sclk,
	input wire mosi,
	output wire miso,
	output reg [7:0] spi_rx,  // data received
	input wire [7:0] spi_tx   // data to be transmitted
	);

	// read register and next read register
	reg [7:0] r_reg;
	wire [7:0] r_next;

	reg mosi_sample;

	// r_next is the next PROPAGATE value
	assign r_next = {r_reg[6:0], mosi_sample};

	// set miso as long as we are enabled, otherwise set it high z
	assign miso = ~(ss_l) ? r_reg[7] : 1'bz;

	always begin
		// START
		@(negedge ss_l)
			r_reg <= spi_tx;

		repeat (7) begin
			// SAMPLE
			@(posedge sclk)
				mosi_sample <= mosi;
			// PROPAGATE
			@(negedge sclk)
				r_reg <= r_next;
		end

		// This final SAMPLE, PROPAGATE block is placed
		// outside so that spi_rx (***) could be set before
		// the rising ss_l.  Then the data will be valid by
		// the time ss_l hi occurs.

		// SAMPLE
		@(posedge sclk)
			mosi_sample <= mosi;
		// PROPAGATE
		@(negedge sclk) begin
			//r_reg  <= r_next;  // don't need to propagate this time
			spi_rx <= r_next;  // ***
		end
	end
endmodule

