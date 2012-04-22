
# This makefile compiles the test files using Iverilog
# and then runs the executable to produce a .vcd file
# which can be used with Gtkwave.


all: decoder-test.vcd switch_ctl-test.vcd led_ctl-test.vcd spi_ctl-test.vcd \
	mem_ctl-test.vcd

decoder-test.vcd: decoder-test
	./$<

switch_ctl-test.vcd: switch_ctl-test
	./$<

led_ctl-test.vcd: led_ctl-test
	./$<

spi_ctl-test.vcd: spi_ctl-test
	./$<

mem_ctl-test.vcd: mem_ctl-test
	./$<

decoder-test: decoder-test.v ../decoder.v
	iverilog $< -o $@

switch_ctl-test: switch_ctl-test.v ../switch_ctl.v
	iverilog $< -o $@

led_ctl-test: led_ctl-test.v ../led_ctl.v
	iverilog $< -o $@

spi_ctl-test: spi_ctl-test.v ../spi_ctl.v
	iverilog $< -o $@

mem_ctl-test: mem_ctl-test.v ../mem_ctl.v
	iverilog $< -o $@

#a.out: main-test.v main.v SPI_slave.v bar_leds.v decoder.v switches.v ram.v
#	iverilog $<

#a.out: ram-test.v ram.v
#	iverilog $<


clean:
	-rm -f decoder-test decoder-test.vcd
	-rm -f mem_ctl-test mem_ctl-test.vcd
	-rm -f spi_ctl-test spi_ctl-test.vcd
	-rm -f led_ctl-test led_ctl-test.vcd
	-rm -f switch_ctl-test switch_ctl-test.vcd


