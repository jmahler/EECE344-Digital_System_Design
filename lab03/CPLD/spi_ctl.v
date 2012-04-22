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

module spi_ctl(
    input            nss,
                     mosi,
                     sck,
    output           miso,
    input            reset_n,
    output reg [6:0] address_bus,
    inout      [7:0] data_bus,
    output reg       read_n,
    output reg       write_n);


	// read register and next read register
	reg [7:0] r_reg;
	wire [7:0] r_next;

	reg mosi_sample;

    reg [3:0] i;
    reg rw;
    reg write_data_bus;

    assign data_bus = (~(write_n | nss | ~read_n)) ? write_data_bus : 8'bz;

	// r_next is the next PROPAGATE value
	assign r_next = {r_reg[6:0], mosi_sample};

	// set miso as long as we are enabled, otherwise set it high z
	//assign miso = ~(nss) ? r_reg[7] : 1'bz;
    assign miso = r_reg[7];

    initial forever @(negedge reset_n) begin
        disable main;

        r_reg   = 8'h00;
        read_n  = 1'b1;
        write_n = 1'b1;
    end

	always begin : main
        @(negedge nss);

        // get the first 7 bits
        for (i = 0; i < 7; i = i + 1) begin
            // SAMPLE
            @(posedge sck)
                mosi_sample <= mosi;
            // PROPAGATE
            @(negedge sck)
                r_reg <= r_next;
        end

        // get the 8th data bit, and store the data
        @(posedge sck) begin
            // drive the address bus
            address_bus <= {r_reg[5:0], mosi};
            rw <= r_reg[6]; // store rw bit for later

            // if the rw bit is zero, write, else read
            if (r_reg[6] == 1'b0) begin
                // WRITE
                // don't start a write here, we don't have
                // the data yet.
            end else begin
                // READ
                read_n      <= 1'b0;
                @(negedge sck)
                    r_reg <= data_bus;  // to send back on SPI
            end
        end

        // (second chunk of 8 bits)

        // run the next 7 bits
        for (i = 0; i < 7; i = i + 1) begin
            // SAMPLE
            @(posedge sck)
                mosi_sample <= mosi;
            // PROPAGATE
            @(negedge sck)
                r_reg <= r_next;
        end

        // process the 8th data bit
        @(posedge sck) begin
            if (rw) begin
                write_data_bus <= {r_reg[6:0], mosi};
            end
        end

        @(negedge sck) begin
            if (~rw) begin
                write_n  <= 1'b0;
            end
        end

        @(posedge nss) begin
            // reset to disabled state
            read_n  <= 1'b1;
            write_n <= 1'b1;
        end
	end
endmodule

