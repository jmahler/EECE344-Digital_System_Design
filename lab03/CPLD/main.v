/*
 * NAME
 * ----
 *
 * main.v - top most module
 *
 * DESCRIPTION
 * -----------
 *
 * This module is the top most modules which is used
 * to to wire all the different modules together and
 * establish a bus.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

`include "decoder.v"
`include "led_ctl.v"
`include "mem_ctl.v"
`include "spi_ctl.v"
`include "switch_ctl.v"

module main(
    input         sck,
                  nss,
                  mosi,
                  reset_n,
    output        miso,
    output [16:0] mem_address,
    inout  [7:0]  mem_data,
    output        mem1_ceh_n,
                  mem1_ce2,
                  mem1_we_n,
                  mem1_oe_n,
                  mem2_ceh_n,
                  mem2_ce2,
                  mem2_we_n,
                  mem2_oe_n,
    output [7:0]  board_leds,
                  bar_leds,
    input  [7:0]  switches);

	wire [6:0] address;
	wire [7:0] data;

	GSR GSR_INST(.GSR(reset_n));

    wire bar_led_ce_n,
         board_led_ce_n,
         switch_ce_n,
         mem1_ce_n,
         mem2_ce_n;

	decoder decoder1(address, bar_led_ce_n, board_led_ce_n, switch_ce_n,
                    mem1_ce_n, mem2_ce_n);

	led_ctl board_leds1(read_n, write_n, reset_n, board_led_ce_n,
                        data, board_leds);

	led_ctl bar_leds1(read_n, write_n, reset_n, bar_led_ce_n,
                        data, bar_leds);

    spi_ctl spi1(nss, mosi, sck, miso, address, data, read_n, write_n);

	switch_ctl sw1(read_n, switch_ce_n, data, switches);

	mem_ctl mem1(read_n, write_n, mem1_ce_n, address, data,
                mem_data, mem_address, mem1_ceh_n, mem1_ce2, mem1_we_n,
                mem1_oe_n);

	mem_ctl mem2(read_n, write_n, mem2_ce_n, address, data,
                mem_data, mem_address, mem2_ceh_n, mem2_ce2, mem2_we_n,
                mem2_oe_n);

endmodule

