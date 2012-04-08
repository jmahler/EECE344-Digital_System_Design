
# output for use with Gtkwave
output.vcd: a.out
	./a.out

a.out: main-test.v main.v SPI_slave.v bar_leds.v decoder.v switches.v
	iverilog $<

clean:
	-rm -f a.out
	-rm -f output.vcd
