/*
 * NAME
 * ----
 *
 * led_ctl - bussed LED control
 *
 *
 * DESCRIPTION
 * -----------
 * 
 * 8-bit bar led module suitable for use with a "bus"
 * consisting of address, data and control lines.
 *
 * To write, data must be assigned to the data bus ('data'),
 * write must be enabled (write_n=0), read must not be
 * enabled (read_n=1), and the chip must be enabled (ce_n=0).
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

    // This is a psuedo wire that goes low when BOTH write_n
    // and ce_n are low.
    // ~A & ~B = ~(A | B)  (De Morgans Law)
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
