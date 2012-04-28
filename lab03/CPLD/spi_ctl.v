/*
 * NAME
 * ----
 *
 *   SPI_slave.v - SPI slave
 *
 * DESCRIPTION
 * -----------
 *
 * This module controls the SPI to bus communication.
 *
 * Refer to the documentation (doc/) for a more detailed
 * description of the timing singals used here.
 * Look for the section titled "Timing diagram of SPI"
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
    output reg [6:0] address_bus,
    inout      [7:0] data_bus,
    output reg       read_n,
    output reg       write_n);

    // sample count
    reg [8:0] count;

	reg mosi_sample;

    reg rw;
    parameter READ = 1'b1,
              WRITE = 1'b0;

    // drive the data bus for a write, high Z otherwise
    reg [7:0] write_data_bus;
    assign data_bus = (~(write_n | ~read_n)) ? write_data_bus : 8'bz;

	// read register and next read register
	reg [7:0] r_reg;
	wire [7:0] r_next;

	// r_next is the next PROPAGATE value
	assign r_next = {r_reg[6:0], mosi_sample};
    assign miso = r_reg[7];

    // This tedious code is much easier to understand
    // along with timing digrams given in the documentation (doc/).
    // Look for the section titled "Timing diagram of SPI"
    // There are two diagrams, one for the read cycle and one
    // for the write cycle.  This code implements both of these.

    // This acts as a "one shot" used to indicate the start of a transaction
    reg start;
    always @(negedge nss, posedge sck) begin
        if (sck)
            start <= 1'b0;
        else
            start <= 1'b1;
    end

    // SAMPLE
    always @(posedge start, posedge sck, posedge nss) begin
        // defaults
        count          <= 1;
        write_data_bus <= 8'h00;

        if (nss) begin
            // end of second byte
            read_n <= 1'b1; // disable
        //end else if ((start == 1'b1) && !(sck == 1'b0)) begin
        end else if (start) begin
            // start, before first bit
            count    <= 1;
            read_n   <= 1'b1; // disable
        end else begin
            // SAMPLE
            mosi_sample <= mosi;
            count       <= count + 1;

            if (7 == count) begin
                // end of first byte

                // we got the 7-bit address and rw bit
                address_bus <= {r_reg[5:0], mosi};
                rw          <= r_reg[6];

                if (r_reg[6] == READ)
                    read_n <= 1'b0; // disable
            end else if (15 == count && rw == 1'b0) begin
                // (WRITE), got the second byte, setup to write it to the bus
                write_data_bus <= r_next;
            end
        end
    end

    // PROPAGATE
    always @(negedge sck, posedge nss) begin
        // defaults
        r_reg <= 8'h00;

        if (nss) begin
            // end of second byte

            write_n <= 1'b1; // disable
        end else begin
            r_reg <= r_next;

            if (1 == count) begin
                write_n <= 1'b1; // disable
            end else if (8 == count) begin
                // if (READ), load the data to be sent back
                if (rw == READ)
                    r_reg <= data_bus;
            end else if (16 == count) begin
                // end of second byte

                // if (WRITE), enable write.
                //  (the enabled device will drive the bus)
                if (rw == WRITE)
                    write_n <= 1'b0; // enable
            end
        end
    end

endmodule

