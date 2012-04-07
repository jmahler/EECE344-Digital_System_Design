
# output for use with Gtkwave
output.vcd: a.out
	./a.out

a.out: main-test.v
	iverilog $<

clean:
	-rm -f a.out
	-rm -f output.vcd
