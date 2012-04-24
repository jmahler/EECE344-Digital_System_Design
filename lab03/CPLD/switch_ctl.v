/*
 * NAME
 * ----
 *
 * switch_ctl - bussed input switche controller
 *
 * DESCRIPTION
 * -----------
 * 
 * Switch input module suitable for use with a "bus"
 * consisting of address, data and control lines.
 *
 * Any time it is enabled and the control is for a read (read_n low)
 * it assigns the switch values on to the bus ('data').
 * Otherwise the data output is high z.
 *
 * AUTHOR
 * ------
 *
 * Jeremiah Mahler <jmmahler@gmail.com>
 *
 */

module switch_ctl(
	input             read_n,
                      ce_n,
    output wire [7:0] data,
    input       [7:0] switches);

    reg [7:0] write_data;
    assign data = (~(ce_n | read_n)) ? write_data : 8'bz;

    always @(negedge read_n) begin
        write_data <= switches;
    end
endmodule
