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
	                  clk,
    input      [6:0]  address_bus,
    inout      [7:0]  data_bus,

	inout      [7:0]  mem_data,
	output     [16:0] mem_address,
    output reg        ceh_n,
                      ce2,
                      we_n,
                      oe_n);

    reg [4:0] i;

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

	// Refer to the data sheet for the Alliance RAM for a description
	// of the timing requirements.
    //
    // The order of the changes are approximately correct but
    // the timing is not the same as the data sheet because of
    // variances in clock speed.

	// It is assumed that the data and address have already been
	// established.  The following just goes through the timing cycle.

    parameter [2:0]
        START  = 0,
        READ2  = 1,
        WRITE2 = 2,
        DONE   = 3;

    reg [3:0] state;

    always @(posedge clk) begin
        if (~read_n) begin
            case (state)
                START: begin
                    ceh_n  <= 1'b0;
                    ce2    <= 1'b1;
                    state  <= READ2;
                end
                READ2: begin
                    oe_n   <= 1'b0;
                    state  <= DONE;
                end
                default:
                    state  <= DONE;
            endcase
        end else if (~write_n) begin
            case (state)
                START: begin
                    ceh_n  <= 1'b0;
                    ce2    <= 1'b1;
                    state  <= WRITE2;
                end
                WRITE2: begin
                    oe_n   <= 1'b0;
                    state  <= DONE;
                end
                default:
                    state  <= DONE;
            endcase
        end else begin
            state <= START;
            if (ce_n) begin
                // diable
                oe_n  <= 1'b1;
                we_n  <= 1'b1;
                ceh_n <= 1'b1;
                ce2   <= 1'b0;
            end
        end
    end
endmodule

