
OPTS=--cell-width 24 --font-size=10
OBJS=read.pdf write.pdf

all: $(OBJS)


%.eps: %.drawtiming
	drawtiming $< --output $@ $(OPTS)

%.pdf: %.eps
	epstopdf $<

clean:
	-rm -f $(OBJS)
