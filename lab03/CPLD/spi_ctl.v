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

    reg byte_state;
    parameter FIRST_BYTE = 1'b0;
    parameter SECOND_BYTE = 1'b1;

    reg [3:0] next_state;
    reg [3:0] cur_state;
    parameter BEGIN                 = 8'd1,
              SAMPLE                = 8'd2,
              PROPAGATE             = 8'd3,
              FIRST_BYTE_SAMPLE     = 8'd4,
              FIRST_BYTE_PROPAGATE  = 8'd5,
              SECOND_BYTE_SAMPLE    = 8'd6,
              SECOND_BYTE_PROPAGATE = 8'd7,
              DISABLED              = 8'd8;

    // sample/propagate count
    reg [4:0] sp_cnt;

	// read register and next read register
	reg [7:0] r_reg;
	wire [7:0] r_next;

	reg mosi_sample;

    reg rw;
    reg write_data_bus;

    assign data_bus = (~(write_n | nss | ~read_n)) ? write_data_bus : 8'bz;

	// r_next is the next PROPAGATE value
	assign r_next = {r_reg[6:0], mosi_sample};

    assign miso = r_reg[7];

    always @(negedge sck, negedge nss) begin
        if (~sck)
            cur_state <= next_state;
        else begin
            cur_state <= FIRST_PROPAGATE;
        end
    end

    // SAMPLE
    always @(posedge sck) begin
        mosi_sample <= mosi;

        if (cur_state == FIRST_PROPAGATE) begin
            read_n <= 1'b1; // disable
        end if (cur_state == FIRST_BYTE_PROPAGATE) begin
            // At this point we have the rw bit and the address.
            //
            //   8  7 6 5 4 3 2 1
            // <rw> <   addr    >
            //

            address_bus <= {r_reg[5:0], mosi};
            rw          <= r_reg[6];

            if (1'b1 == r_reg[6] )
                // READ
                read_n  <= 1'b0; // enable
            else
                read_n  <= 1'b1; // disable

        end else if (cur_state == SECOND_BYTE_PROPAGATE) begin
            if (~rw) begin
                // WRITE

                // We got the second chunk of data,
                // drive it on to the data bus to be written.
                write_data_bus <= {r_reg[6:0], mosi};
            end
        end
    end

    // PROPAGATE, etc
    always @(negedge sck) begin

        // (START is the default at the end)

        if (PROPAGATE == cur_state) begin

            r_reg  <= r_next;
            sp_cnt <= sp_cnt + 1;

            if (sp_cnt < 6)
                next_state <= PROPAGATE;
            else if (SECOND_BYTE == byte_state)
                next_state <= SECOND_BYTE_PROPAGATE;
            else
                next_state <= FIRST_BYTE_PROPAGATE;
        end else if (FIRST_BYTE_PROPAGATE == cur_state) begin

            if (rw) begin
                // READ

                // get the data to be sent back on SPI
                r_reg <= data_bus;
            end

            // setup for second byte
            sp_cnt     <= 0;
            byte_state <= SECOND_BYTE;
            next_state <= PROPAGATE;
        end else if (SECOND_BYTE_PROPAGATE == cur_state) begin
            if (~rw) begin
                // enable a write
                write_n <= 1'b0;
            end

            // END
            next_state <= DISABLED;
        end else begin
            // START, FIRST_PROPAGATE

            write_n <= 1'b1; // disable

            r_reg      <= r_next;
            sp_cnt     <= 1;
            byte_state <= FIRST_BYTE;
            next_state <= PROPAGATE;
        end
	end
endmodule

