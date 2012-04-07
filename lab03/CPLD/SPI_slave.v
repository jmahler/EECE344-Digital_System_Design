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
 * The data it outputs is defined by 'out_reg'.
 * And the data it receives is stored in 'in_reg'.
 *
 * The following SPI settings used by this module:
 *
 *   MSB first
 *   CPOL = 0
 *   CPHA = 0
 *   SS_L (enable on low)
 *
 *  The slave select line (SS_L) is used in a somewhat unique way.
 *  On the cleared (enabled) to set (disabled) transition the
 *  new data is latched in to the register.
 *  This was done because in the other orientation it was impossible
 *  to determine when to initialize the data because ss_l was
 *  the same value when it is sampling/propagating.
 *  
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module SPI_slave(
	input wire rst_l,
	input wire ss_l,
	input wire sclk,
	input wire mosi,
	output wire miso,
	output reg [7:0] out_reg,
	input wire [7:0] in_reg
	);

	// read register and next read register
	reg [7:0] r_reg;
	wire [7:0] r_next;

	// ### main SPI control: sample, propagate ###

	assign r_next = {r_reg[6:0], mosi_sample};
	assign miso = ~(ss_l) ? r_reg[7] : 1'bz;
	// set miso as long as we are enabled, otherwise set it high z

	reg mosi_sample;
	always @(posedge sclk) begin
		// SAMPLE
		mosi_sample <= mosi;
	end

	always @(negedge sclk or negedge rst_l) begin
		if (~rst_l) begin
			// RESET
			r_reg <= 8'b0;
			out_reg <= 8'b0;
		end else begin
			if (ss_l) begin
				// COMPLETE READ/WRITE

				// reset when sclk falls while ss_l is high (disabled)
				r_reg <= in_reg;   // data to output on miso
				out_reg <= r_next; // last complete read
				// use r_next (not r_reg) so we don't miss the last mosi (SAMPLE)
			end else begin
				// PROPAGATE
				r_reg <= r_next;
			end
		end
	end
endmodule
