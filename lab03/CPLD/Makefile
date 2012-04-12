
# output for use with Gtkwave
output.vcd: a.out
	./a.out

a.out: ram-test.v ram.v
	iverilog $<

#a.out: main-test.v main.v SPI_slave.v bar_leds.v decoder.v switches.v ram.v
#	iverilog $<

clean:
	-rm -f a.out
	-rm -f output.vcd
