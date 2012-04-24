/*
 * NAME
 * ----
 *
 *   SPI_slave.v - SPI slave
 *
 * WARNING
 * -------
 *
 * This code is currently broken and not usable.
 *
 * DESCRIPTION
 * -----------
 *
 * This module controls the SPI to bus communication.
 *
 * The following SPI settings used by this module:
 *
 *   MSB first
 *   CPOL = 0
 *   CPHA = 0
 *   SS_L (enable on low)
 *
 * The following describes the required signals in general.
 * Notice that the NSS transitions after the SCK has stopped.
 * This is also configuration specific with CPOL=0 and CPHA=0.
 *
 *        --+                            +--
 *  NSS     |___________ ... ____________|
 *            +--+  +--+     +--+  +--+
 *  SCK   ____|  |__|  | ... |  |__|  |_____
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

    reg [4:0] next_state;
    reg [4:0] cur_state;
    parameter FIRST_PROPAGATE       = 5'd1,
              PROPAGATE             = 5'd2,
              FIRST_BYTE_PROPAGATE  = 5'd3,
              SECOND_BYTE_PROPAGATE = 5'd4,
              DISABLED              = 5'd5;

    // sample/propagate count
    reg [4:0] sp_cnt;

	// read register and next read register
	reg [7:0] r_reg;
	wire [7:0] r_next;

	reg mosi_sample;

    reg rw;
    reg write_data_bus;

    // when a read, drive the data bus
    assign data_bus = (~(write_n | ~read_n)) ? write_data_bus : 8'bz;

	// r_next is the next PROPAGATE value
	assign r_next = {r_reg[6:0], mosi_sample};

    assign miso = r_reg[7];

    // This acts as a "one shot" used to indicate the start of a transaction
    reg nss_start;
    always @(negedge nss, posedge sck) begin
        if (sck)
            nss_start <= 1'b0;
        else
            nss_start <= 1'b1;
    end

    always @(posedge sck, posedge nss_start) begin
        if (nss_start)
            cur_state <= FIRST_PROPAGATE;
        else begin
            cur_state <= next_state;
        end
    end

    // SAMPLE
    always @(posedge sck) begin
        mosi_sample <= mosi;

        /*
        if (cur_state == FIRST_PROPAGATE) begin
            //read_n <= 1'b1; // disable
        end if (cur_state == FIRST_BYTE_PROPAGATE) begin
            // At this point we have the rw bit and the address.
            //
            //   8  7 6 5 4 3 2 1
            // <rw> <   addr    >
            //

            //address_bus <= r_next;
            //rw          <= r_reg[6];

            if (1'b1 == r_reg[6])
                // READ
                read_n  <= 1'b0; // enable
            else
                read_n  <= 1'b1; // disable

        end else if (cur_state == SECOND_BYTE_PROPAGATE) begin
            //if (~rw) begin
                // WRITE

                // We got the second chunk of data,
                // drive it on to the data bus to be written.
                //write_data_bus <= {r_reg[6:0], mosi};
            //end
        end
        */
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

            address_bus <= r_next;
            rw          <= r_reg[6];

            if (r_reg[6]) begin
                // READ

                // XXX TODO
                // This doesn't work because the data_bus isn't ready
                // until AFTER read_n goes low.
                r_reg <= data_bus;

                read_n <= 1'b0; // enable
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

