/*
 * NAME
 * ----
 *
 *   decoder - specialized decoder
 *
 * DESCRIPTION
 * -----------
 *
 * This is a specialized decoder designed
 * to map the 7-bit addresses to the following
 * active low enable signals.
 *
 *    address (hex) | device
 *  ----------------+---------------
 *   0x74           | switch_ce_n
 *   0x6C           | bar_led_ce_n
 *   0x50 - 0x5F    | mem2_ce_n
 *   0x2F           | board_led_ce_n
 *   0x00 - 0x0F    | mem1_ce_n
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module decoder(
    input [6:0] address,
    output reg  bar_led_ce_n,
                board_led_ce_n,
                switch_ce_n,
                mem1_ce_n,
                mem2_ce_n);

    always @(address) begin
        // default, disabled
        switch_ce_n    = 1'b1;
        bar_led_ce_n   = 1'b1;
        mem2_ce_n      = 1'b1;
        board_led_ce_n = 1'b1;
        mem1_ce_n      = 1'b1;

        casex (address)
            7'h74: switch_ce_n    = 1'b0;
            7'h6C: bar_led_ce_n   = 1'b0;
            7'h5?: mem2_ce_n      = 1'b0;
            7'h2F: board_led_ce_n = 1'b0;
            7'h0?: mem1_ce_n      = 1'b0;
        endcase
    end
endmodule
