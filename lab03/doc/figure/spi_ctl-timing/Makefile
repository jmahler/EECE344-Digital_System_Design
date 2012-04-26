
OPTS=--cell-width 24 --font-size=10

all: read-byte1.pdf read-byte2.pdf

read-byte1.eps: read-byte1.drawtiming
	drawtiming $< --output $@ $(OPTS)

read-byte1.pdf: read-byte1.eps
	epstopdf $<

read-byte2.eps: read-byte2.drawtiming
	drawtiming $< --output $@ $(OPTS)

read-byte2.pdf: read-byte2.eps
	epstopdf $<

clean:
	-rm -f *.eps
