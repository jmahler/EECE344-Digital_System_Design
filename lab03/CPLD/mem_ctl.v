/*
 * NAME
 * ----
 *
 * mem_ctl - memory control
 *
 *
 * DESCRIPTION
 * -----------
 * 
 * Module for interfacing an Alliance AS6C1008 128x8 RAM chip
 * on to an 8-bit data bus and a 7-bit address bus.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module mem_ctl(
    input             read_n,
                      write_n,
                      ce_n,
    input      [6:0]  address_bus,
    inout      [7:0]  data_bus,

	inout      [7:0]  mem_data,
	output     [16:0] mem_address,
    output wire       ceh_n,
                      ce2,
                      we_n,
                      oe_n);

	// tie unused address bits low
	assign mem_address[16:7] = 0;

	assign mem_address[6:0] = address_bus;

	// if read enabled, drive current data, otherwise go hi Z

    // for READ
	assign data_bus = (~(ce_n | read_n | ~write_n)) ? mem_data : 8'bz;
    // The following line is used to test read cycle, see mem_ctl-test.v
    // Comment out the one above when using it.
	//assign data_bus = (~(ce_n | read_n | ~write_n)) ? 8'hee : 8'bz;

    // for WRITE
    assign mem_data = (~(ce_n | write_n | ~read_n)) ? data_bus : 8'bz;

    // Not "timing" is required for the control lines.
    // This just follows the truth table given on page 3 of
    // the Alliance RAM data sheet.

    assign ceh_n = 1'b0;
    assign ce2   = 1'b1;

    // for READ
    assign oe_n = (~(ce_n | read_n)) ? 1'b0 : 1'b1;

    // for WRITE
    assign we_n = (~(ce_n | write_n | ~read_n)) ? 1'b0 : 1'b1;

endmodule

