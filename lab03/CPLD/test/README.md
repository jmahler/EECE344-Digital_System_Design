
NAME
----

Verilog test benches

DESCRIPTION
-----------

The contained here are "test benches" used to
test Verilog code in the parent directory.

The files are named so it is easy to determine
which one the correlate with.  For example 'spi\_ctl-test.v'
corresponds to 'spi\_ctl.v'.

These were developed with the Verilog simulation [IVerilog][iverilog]
and the digital waveforms were examined using [Gtkwave][gtkwave].
Under a decently configured Linux system you should be able to
compile all the these files by just typing 'make'.
And then Gtkwave can be used upon a particular '.vcd' file.

There are two main types of tests: bus tests, and SPI protocol tests.
Tests of individual modules, such as led\_ctl-test.v, generally perform
bus tests. main-test.v performs SPI protocol tests.
Refer to the documentation (doc/main.pdf) for a detailed description.

  [gtkwave]: http://gtkwave.sourceforge.net
  [iverilog]: http://iverilog.icarus.com

AUTHOR
------

Jeremiah Mahler <jmmahler@gmail.com><br>
<https://plus.google.com/101159326398579740638/about>

