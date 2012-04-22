/*
 * NAME
 * ----
 *
 *   led_ctl - bussed LED control
 *
 *
 * DESCRIPTION
 * -----------
 * 
 * 8-bit bar led module suitable for use with a "bus"
 * consisting of address, data and control lines.
 *
 * Any time it is enabled data can be read from (rw = 1)
 * or written to (rw = 0).  At all other times the data
 * line is high z.
 *
 * To write, data must be assigned to 'data', 'rw' set to 0 (write),
 * and then 'ce' set to high.
 * A similar sequence is performed for a read except that rw = 1.
 *
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module led_ctl(
    input            read_n,
                     write_n,
                     reset_n,
                     ce_n,
    inout      [7:0] data,
    output reg [7:0] leds);

    // READ
    // If we are enabled (ce_n lo) and read is enabled (read_n lo)
    // and write is not enabled (write_n hi)
    // drive the leds values on to the data bus.
    assign data = (~(ce_n | read_n | ~write_n)) ? leds : 8'bz;

    wire write_ce_n;
    assign write_ce_n = write_n | ce_n;

    // WRITE
    // If anything here changes and reset_n is low, reset leds
    // If write_n or ce_n change such that write is enabled
    // (write_n lo) and the chip is enabled (ce_n lo)
    // write the data to the leds.
    always @(negedge reset_n, negedge write_ce_n) begin
        if (~reset_n)
            leds <= 8'h00;
        else
            leds <= data;
    end
endmodule
