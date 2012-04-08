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

module main(
	input wire rst_l,
	input wire ss_l,
	input wire sclk,
	input wire mosi,
	output wire miso,
	output wire [7:0] led_ext,
	input wire [7:0] in_sw
	);


	// ### MODULE AND BUS DEFINITION ###

	wire [8:1] addr;
	inout [8:1] data;
	// control
	wire [5:1] enable;  // chip enable

	// reg for writing to enable wires
	reg [5:1] w_enable;
	assign enable = w_enable;

	// reg for writing to data
	reg [8:1] w_data;
	assign data = w_data;

	wire rw; // read = 1, write = 0
	parameter READ = 1'b1;
	parameter WRITE = 1'b0;

	reg w_rw;
	assign rw = w_rw;

	GSR GSR_INST(.GSR(rst_l));

	wire [8:1] spi_rx; // received data
	reg [8:1] spi_tx;  // data to transmit
	SPI_slave SPI_slave1(rst_l, ss_l, sclk, mosi, miso, spi_rx, spi_tx);

	decoder decoder1(addr, enable);

	bar_leds bar_leds1(enable[2], data, rw, led_ext);

	switches switches1(enable[1], data, rw, in_sw);


	// ### MAIN ###

	// The different states that this "machine" goes through
	reg [3:1] state;
	parameter STATE_READY  = 3'b001;
	parameter STATE_LOADED = 3'b010;
	parameter STATE_ERROR  = 3'b111;

	reg [7:0] r_addr; // register for address
	assign addr = r_addr;

	// 8-bit commands received from SPI on spi_rx
	parameter CMD_EMPTY = 8'h00;
	parameter CMD_RESET = 8'h01;
	parameter CMD_LOAD  = 8'h02;

	// 8-bit return messages to SPI (spi_tx)
	parameter RETURN_OK = 8'h00;
	// an incorrect state change would be due to a programmer error
	parameter RETURN_ERROR_WRONG_STATE = 8'h01;
	parameter RETURN_ERROR_UNKNOWN_CMD = 8'hff;

	wire [7:0] next_r_addr;
	assign next_r_addr = {1'b0, in_sw[6:0]};
	// The 1'b0 is just to fill the empty bit

	// anytime new data is received
	always @(spi_rx) begin
		case (spi_rx)
			CMD_EMPTY: begin
				// An empty command that does nothing.
				// It can be used by the SPI master to receive data from last
				// command.
				spi_tx <= RETURN_OK;
			end
			CMD_RESET: begin
				w_data <= 1'bz; // ensure we aren't driving the bus
				spi_tx <= RETURN_OK;
				state  <= STATE_READY;
			end
			CMD_LOAD: begin
				if (state == STATE_READY) begin
					// prepare for next read/write
					w_data <= 1'bz;  // ensure we aren't driving the outputs
					r_addr <= next_r_addr;
					w_rw <= spi_rx[8];
					// also, send this data

					// this command differs from the others in that
					// it returns a value instead of the return status
					spi_tx <= in_sw;

					state  <= STATE_LOADED;
				end else begin
					spi_tx <= RETURN_ERROR_WRONG_STATE;
					state  <= STATE_ERROR;
				end
			end
			/*
			CMD_EXEC: begin
				if (state == STATE_LOADED) begin
					if (rw == WRITE) begin
						data <= loaded_data;
					end else begin
						// READ
						spi_tx <= data;
					end

					state <= STATE_EXEC_DONE;
				end else begin
					spi_tx <= RETURN_CMD_ERROR_WRONG_STATE;
					state  <= STATE_ERROR;
				end
			end
			*/
		   default: begin
				spi_tx <= RETURN_ERROR_UNKNOWN_CMD;
				state  <= STATE_ERROR;
			end
		endcase
	end

endmodule
