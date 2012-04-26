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

    // sample count
    reg [8:0] count;

	reg mosi_sample;

    reg rw;

    // when a read, drive the data bus
    reg write_data_bus;
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

    // This acts as a "one shot" used to indicate the start of a transaction
    reg start;
    always @(negedge nss, posedge sck) begin
        if (sck)
            start <= 1'b0;
        else
            start <= 1'b1;
    end

    // SAMPLE
    always @(posedge sck, posedge start) begin
        if ((start == 1'b1) && !(sck == 1'b0)) begin
            count   <= 8'd1;
            read_n  <= 1'b1;
        end else begin
            mosi_sample <= mosi;
            count       <= count + 8'd1;

            if (8'd7 == count) begin
                // values pre-propagate
                address_bus <= {r_reg[5:0], mosi};
                rw          <= r_reg[6];
                read_n      <= 0;
            end
        end
    end

    // PROPAGATE
    always @(negedge sck) begin
        r_reg <= r_next;

 //       if (rw && 7 == count)
//            write_data_bus <= r_next;
    end

endmodule

